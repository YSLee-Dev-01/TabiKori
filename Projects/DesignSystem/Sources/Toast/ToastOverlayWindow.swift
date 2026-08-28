//
//  ToastOverlayWindow.swift
//  DesignSystem
//
//  Created by Claude on 8/26/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import UIKit

/// 터치를 하위 뷰로 통과시키는(pass-through) `UIWindow`
///
/// `hitFrame` 영역 안의 터치만 자기 자신(및 하위 계층)에서 처리하고, 그 외 영역의 터치는 `nil`을 반환해
/// 아래에 놓인 메인 윈도우(및 `.sheet()`로 표시된 화면 등)로 그대로 전달한다
final class PassThroughWindow: UIWindow {
    var hitFrame: CGRect = .zero

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard self.hitFrame.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}

/// 오버레이 윈도우의 루트에 표시되는 실제 SwiftUI 콘텐츠
///
/// Toast가 없을 때는 아무것도 그리지 않아 `hitFrame`이 `.zero`가 되고, 오버레이 윈도우 전체가 터치를 통과시킨다
private struct ToastOverlayContent: View {
    let message: String?
    let style: TabiToast.Style
    let actionButtonTitle: String?
    let onActionTapped: (() -> Void)?
    let onFrameChanged: (CGRect) -> Void

    var body: some View {
        VStack {
            Spacer()
            if let message = self.message {
                TabiToast(
                    message: message,
                    style: self.style,
                    actionButtonTitle: self.actionButtonTitle,
                    onActionTapped: self.onActionTapped
                )
                .padding(.horizontal, 20)
                // GeometryReader + PreferenceKey 조합은 .transition() 애니메이션과 함께 쓰이면
                // 삽입 시점의 frame(간혹 {0,0})만 한 번 보고된 뒤 실제 레이아웃이 끝나도 다시 갱신되지
                // 않는 경우가 있다. onGeometryChange는 레이아웃이 바뀔 때마다 안정적으로 다시 호출된다.
                // 반드시 아래의 .padding(.bottom, 100)보다 먼저(안쪽에) 붙여야 한다 — padding은 여백만큼
                // 뷰 자신의 frame도 함께 확장시키므로, 순서가 바뀌면 실제 카드보다 훨씬 아래(빈 여백 구간,
                // 바로 밑의 탭바 영역)까지 hitFrame이 잡혀 탭바 터치를 막아버린다
                .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { frame in
                    self.onFrameChanged(frame)
                }
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.tabiSpring, value: self.message)
        // .onGeometryChange는 TabiToast 서브뷰에 직접 붙어 있어, message가 nil이 되어 그 서브뷰가
        // 트리에서 사라지면 더 이상 호출되지 않는다(마지막 frame 값이 그대로 남아 하단 탭바 등의
        // 터치를 계속 막아버림). message가 nil로 바뀌는 시점을 직접 감지해 hitFrame을 리셋한다
        .onChange(of: self.message) { _, newValue in
            guard newValue == nil else { return }
            self.onFrameChanged(.zero)
        }
        .onDisappear {
            self.onFrameChanged(.zero)
        }
    }
}

/// `TabiToastModifier`가 적용된 뷰의 `UIWindowScene`을 찾아, 메인 윈도우보다 `windowLevel`이 높은
/// 별도의 `PassThroughWindow`를 생성/관리한다.
///
/// `.sheet()`/`.fullScreenCover()`는 프레젠팅 뷰의 `overlay`보다 위에 별도 계층으로 렌더링되므로,
/// 그 위에도 Toast가 항상 보이도록 하려면 메인 윈도우 자체보다 레벨이 높은 윈도우가 필요하다
struct ToastOverlayWindowAccessor: UIViewControllerRepresentable {
    let message: String?
    let style: TabiToast.Style
    let actionButtonTitle: String?
    let onActionTapped: (() -> Void)?

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.update(
            anchorView: uiViewController.view,
            message: self.message,
            style: self.style,
            actionButtonTitle: self.actionButtonTitle,
            onActionTapped: self.onActionTapped
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {
        private var overlayWindow: PassThroughWindow?
        private var hostingController: UIHostingController<ToastOverlayContent>?

        func update(
            anchorView: UIView,
            message: String?,
            style: TabiToast.Style,
            actionButtonTitle: String?,
            onActionTapped: (() -> Void)?
        ) {
            guard let windowScene = anchorView.window?.windowScene else { return }

            let content = ToastOverlayContent(
                message: message,
                style: style,
                actionButtonTitle: actionButtonTitle,
                onActionTapped: onActionTapped,
                onFrameChanged: { [weak self] frame in
                    self?.overlayWindow?.hitFrame = frame
                }
            )

            if let hostingController = self.hostingController, let overlayWindow = self.overlayWindow {
                hostingController.rootView = content
                overlayWindow.frame = windowScene.coordinateSpace.bounds
            } else {
                let hostingController = UIHostingController(rootView: content)
                hostingController.view.backgroundColor = .clear

                let overlayWindow = PassThroughWindow(windowScene: windowScene)
                overlayWindow.frame = windowScene.coordinateSpace.bounds
                overlayWindow.rootViewController = hostingController
                overlayWindow.backgroundColor = .clear
                overlayWindow.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue + 1)
                overlayWindow.isHidden = false

                self.hostingController = hostingController
                self.overlayWindow = overlayWindow
            }
        }
    }
}

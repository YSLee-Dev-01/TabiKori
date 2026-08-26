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

/// Toast 콘텐츠의 실제 렌더링 프레임을 오버레이 윈도우로 전달하기 위한 `PreferenceKey`
private struct ToastFramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
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
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: ToastFramePreferenceKey.self, value: proxy.frame(in: .global))
                    }
                )
            }
        }
        .animation(.tabiSpring, value: self.message)
        .onPreferenceChange(ToastFramePreferenceKey.self) { frame in
            self.onFrameChanged(frame)
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

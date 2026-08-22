//
//  KoreanPhraseDetailView.swift
//  Presentation
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import UIKit

import ComposableArchitecture
import Core
import DesignSystem
import Domain
import Resource

/// 한국어 문구 셀 탭 시 진입하는 가로모드 전용 상세 화면.
/// 등장 시 실제 기기 방향을 landscape로 전환 요청하고, 이탈 시 다시 portrait로 복귀시킨다.
/// OrientationLock 마스크 자체는 진입/이탈을 트리거하는 액션(셀 탭, 닫기 버튼 탭) 시점에 이미 갱신되어 있으므로,
/// 여기서는 windowScene이 확보된 시점에 실제 회전 요청(requestGeometryUpdate)만 수행한다.
///
/// 회전 요청을 fullScreenCover 표시 이전(리스트 화면의 셀 탭 시점)으로 앞당기는 시도는 하지 않는다 —
/// 그 시점의 활성 뷰 컨트롤러는 아직 이 화면(가로모드를 지원하는 뷰 컨트롤러)이 아니라 리스트 화면(portrait만
/// 지원)이라, requestGeometryUpdate가 "지원되는 화면 방향이 없다"는 에러와 함께 즉시 실패한다.
///
/// OrientationLock.shared.mask를 갱신하는 것만으로는 부족하다 — iOS는
/// AppDelegate.application(_:supportedInterfaceOrientationsFor:)의 반환값을 매 순간 다시 묻지 않고 캐시하며,
/// setNeedsUpdateOfSupportedInterfaceOrientations()를 호출해 명시적으로 무효화해야만 다음 쿼리 시점에
/// 새 mask(.landscape)를 반영한다. 이를 빠뜨리면 mask는 이미 .landscape로 바뀐 뒤인데도
/// requestGeometryUpdate는 "지원되는 방향: portrait"라는, 실제 상태와 어긋나 보이는 에러로 계속 실패한다
public struct KoreanPhraseDetailView: View {

    @Bindable private var store: StoreOf<KoreanPhraseDetailFeature>

    public init(store: StoreOf<KoreanPhraseDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle()
                .fill(TabiColor.tabiBackground)
                .ignoresSafeArea()

            self.phraseContent()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            self.closeButton()
                .padding(20)
        }
        .onAppear {
            self.enterLandscape()
        }
        .onDisappear {
            self.exitLandscape()
        }
    }
}

// MARK: - View

private extension KoreanPhraseDetailView {
    func closeButton() -> some View {
        TabiCircleIconButton(systemName: "xmark") {
            self.store.send(.closeButtonTapped)
        }
    }

    func phraseContent() -> some View {
        VStack(spacing: 40) {
            Text(self.store.phrase.korean)
                .font(.pretendard(.bold, size: 56))
                .foregroundStyle(TabiColor.tabiPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                if let pronunciation = self.store.phrase.pronunciation, pronunciation.isEmpty == false {
                    Text(pronunciation)
                        .font(.pretendard(.semiBold, size: 24))
                        .foregroundStyle(TabiColor.tabiTextSecondary)
                }
                Text(self.store.phrase.japanese)
                    .font(.pretendard(.semiBold, size: 24))
                    .foregroundStyle(TabiColor.tabiTextPrimary)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 48)
    }
}

// MARK: - Method

private extension KoreanPhraseDetailView {
    func enterLandscape() {
        AppLogger.view.log(.debug, "가로모드 진입 onAppear, 현재 mask=\(OrientationLock.shared.mask)")
        self.requestGeometryUpdate(interfaceOrientations: .landscapeRight) { error in
            AppLogger.view.log(.error, "가로모드 전환 요청 실패: \(error.localizedDescription)")
        }
    }

    func exitLandscape() {
        AppLogger.view.log(.debug, "세로모드 복귀 onDisappear, 현재 mask=\(OrientationLock.shared.mask)")
        self.requestGeometryUpdate(interfaceOrientations: .portrait) { error in
            AppLogger.view.log(.error, "세로모드 복귀 요청 실패: \(error.localizedDescription)")
        }
    }

    func currentWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }

    /// setNeedsUpdateOfSupportedInterfaceOrientations()로 UIKit의 캐시된 "이 장면이 지원하는 화면 방향"
    /// 판단을 무효화한 뒤 requestGeometryUpdate를 보낸다. 두 가지를 함께 처리하지 않으면 계속 실패한다:
    /// 1) 무효화 대상은 root가 아니라 실제 화면에 표시된 최상단(topmost) 뷰 컨트롤러여야 한다 — fullScreenCover는
    ///    root와 별개로 새로 present된 뷰 컨트롤러이므로, root만 무효화해서는 그 presented 체인에 반영되지 않는다.
    /// 2) setNeedsUpdateOfSupportedInterfaceOrientations()는 다음 런루프 사이클에 실제 재조회를 예약할 뿐이라,
    ///    같은 동기 실행 흐름에서 바로 requestGeometryUpdate를 이어 호출하면 아직 무효화가 반영되기 전의
    ///    캐시된 값을 참조해 여전히 실패한다. DispatchQueue.main.async로 한 틱 미뤄 순서를 보장한다
    func requestGeometryUpdate(interfaceOrientations: UIInterfaceOrientationMask, onFailure: @escaping (Error) -> Void) {
        guard let windowScene = self.currentWindowScene() else {
            AppLogger.view.log(.error, "화면 방향 전환 실패: windowScene을 찾을 수 없음")
            return
        }
        guard let topViewController = self.topmostViewController(in: windowScene) else {
            AppLogger.view.log(.error, "화면 방향 전환 실패: 최상단 뷰 컨트롤러를 찾을 수 없음")
            return
        }
        topViewController.setNeedsUpdateOfSupportedInterfaceOrientations()
        DispatchQueue.main.async {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: interfaceOrientations), errorHandler: onFailure)
        }
    }

    func topmostViewController(in windowScene: UIWindowScene) -> UIViewController? {
        guard var current = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController else { return nil }
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}

#Preview {
    KoreanPhraseDetailView(
        store: Store(
            initialState: KoreanPhraseDetailFeature.State(
                phrase: KoreanPhrase(id: "hello", order: 0, korean: "안녕하세요", japanese: "こんにちは", pronunciation: "アンニョンハセヨ")
            ),
            reducer: { KoreanPhraseDetailFeature() }
        )
    )
}

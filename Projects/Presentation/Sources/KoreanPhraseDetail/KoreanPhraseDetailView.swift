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
/// 여기서는 windowScene이 확보된 시점에 실제 회전 요청(requestGeometryUpdate)만 수행한다
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
    /// KoreanPhraseListView의 행 탭 시점에도 동일한 요청을 미리 보내(회전 끊김 완화), 여기서는
    /// 그 선요청이 실패했거나 아직 반영되지 않은 경우를 위한 안전망으로 다시 한 번 요청한다
    func enterLandscape() {
        AppLogger.view.log(.debug, "가로모드 진입 onAppear, 현재 mask=\(OrientationLock.shared.mask)")
        guard let windowScene = self.currentWindowScene() else {
            AppLogger.view.log(.error, "가로모드 전환 실패: windowScene을 찾을 수 없음")
            return
        }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight)) { error in
            AppLogger.view.log(.error, "가로모드 전환 요청 실패: \(error.localizedDescription)")
        }
    }

    func exitLandscape() {
        AppLogger.view.log(.debug, "세로모드 복귀 onDisappear, 현재 mask=\(OrientationLock.shared.mask)")
        guard let windowScene = self.currentWindowScene() else {
            AppLogger.view.log(.error, "세로모드 복귀 실패: windowScene을 찾을 수 없음")
            return
        }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
            AppLogger.view.log(.error, "세로모드 복귀 요청 실패: \(error.localizedDescription)")
        }
    }

    func currentWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
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

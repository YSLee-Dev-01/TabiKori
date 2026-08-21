//
//  KoreanPhraseListView.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import UIKit

import ComposableArchitecture
import Core
import DesignSystem
import Domain
import Resource

public struct KoreanPhraseListView: View {

    @Bindable private var store: StoreOf<KoreanPhraseListFeature>

    public init(store: StoreOf<KoreanPhraseListFeature>) {
        self.store = store
    }

    public var body: some View {
        self.content()
            .navigationTitle(Strings.KoreanPhrase.listTitle)
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: self.$store.scope(state: \.phraseDetailState, action: \.phraseDetail)) { store in
                KoreanPhraseDetailView(store: store)
            }
            .onAppear {
                self.store.send(.onAppear)
            }
    }
}

// MARK: - View

private extension KoreanPhraseListView {
    @ViewBuilder
    func content() -> some View {
        if self.store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.store.hasLoadFailed {
            TabiRetryableEmptyState(description: Strings.KoreanPhrase.loadFailedDescription) {
                self.store.send(.retryButtonTapped)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.store.phrases.isEmpty {
            TabiEmptyState(
                systemImageName: "text.bubble",
                title: Strings.KoreanPhrase.emptyTitle,
                description: Strings.KoreanPhrase.emptyDescription,
                style: .card
            )
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(self.store.phrases) { phrase in
                    KoreanPhraseRow(
                        phrase: phrase,
                        onTap: {
                            // 가로모드 회전 요청을 fullScreenCover가 실제로 표시되기 전(탭 시점)에
                            // 미리 시작해, KoreanPhraseDetailView가 세로 프레임으로 잠시 표시된 뒤
                            // 회전하는 것처럼 보이는 끊김을 줄인다. OrientationLock 마스크는
                            // phraseRowTapped 리듀서 케이스에서 동기적으로 먼저 갱신되므로,
                            // send() 직후 시점에는 이미 .landscape가 반영되어 있다
                            self.store.send(.phraseRowTapped(phrase))
                            self.requestLandscapeGeometry()
                        },
                        onCopyTapped: {
                            self.store.send(.phraseCopyMenuTapped(phrase))
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

// MARK: - Method

private extension KoreanPhraseListView {
    /// KoreanPhraseDetailView.onAppear에서도 동일한 요청을 보내지만(안전망), 그 시점은 fullScreenCover가
    /// 이미 표시된 이후라 회전이 화면에 노출된 채로 일어나 끊겨 보인다. 여기서 최대한 이르게(행 탭 시점)
    /// 선요청해 실제 회전이 커버 프레젠테이션 애니메이션과 겹쳐 시작되도록 한다.
    /// iOS의 requestGeometryUpdate는 비동기이며 실제 회전 완료 시점을 보장하지 않으므로, 기기/상황에 따라
    /// 완전한 끊김 없는 전환은 iOS 자체의 한계로 보장되지 않을 수 있다
    func requestLandscapeGeometry() {
        guard let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            AppLogger.view.log(.error, "가로모드 선요청 실패: windowScene을 찾을 수 없음")
            return
        }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight)) { error in
            AppLogger.view.log(.error, "가로모드 선요청 실패: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let mockUseCase: TestKoreanPhraseUseCase = {
        let useCase = TestKoreanPhraseUseCase()
        useCase.phrases = [
            KoreanPhrase(id: "hello", order: 0, korean: "안녕하세요", japanese: "こんにちは", pronunciation: "アンニョンハセヨ"),
            KoreanPhrase(id: "thanks", order: 1, korean: "감사합니다", japanese: "ありがとうございます", pronunciation: "カムサハムニダ")
        ]
        return useCase
    }()

    NavigationStack {
        KoreanPhraseListView(
            store: Store(
                initialState: KoreanPhraseListFeature.State(),
                reducer: { KoreanPhraseListFeature() },
                withDependencies: { dependency in
                    dependency.koreanPhraseUseCase = mockUseCase
                }
            )
        )
    }
}

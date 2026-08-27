//
//  TranslateSearchTaskModifier.swift
//  Presentation
//
//  Created by Claude on 8/27/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
@preconcurrency import Translation

import Core

/// 일본어 검색어를 한국어로 번역하는 Translation 프레임워크 연결부.
/// `pendingQuery`가 채워지면 번역을 실행하고 결과/실패를 콜백으로 되돌려준다.
/// Map/PlanDetailAddSpot/AddCustomPlace 세 화면에서 동일하게 중복되던 번역 실행 로직을 공용화한 것
private struct TranslateSearchTaskModifier: ViewModifier {
    let pendingQuery: String?
    let onResult: (String) -> Void
    let onFailure: () -> Void

    @State private var translationConfiguration: TranslationSession.Configuration?

    func body(content: Content) -> some View {
        content
            .onChange(of: self.pendingQuery) { _, newValue in
                guard newValue != nil else { return }
                // TranslationSession.Configuration은 Equatable이라 동일한 source/target으로 새 인스턴스를 만들어도
                // 이전 값과 같다고 판단되어 .translationTask가 재실행되지 않는다. 이미 Configuration이 있다면
                // invalidate()로 명시적으로 무효화해야 동일 언어쌍으로도 번역이 다시 실행된다
                guard self.translationConfiguration != nil else {
                    self.translationConfiguration = TranslationSession.Configuration(
                        source: Locale.Language(languageCode: .japanese),
                        target: Locale.Language(languageCode: .korean)
                    )
                    return
                }
                self.translationConfiguration?.invalidate()
            }
            .translationTask(self.translationConfiguration) { session in
                guard let query = self.pendingQuery else { return }
                do {
                    let response = try await session.translate(query)
                    self.onResult(response.targetText)
                } catch {
                    AppLogger.view.log(.error, "検索語の翻訳に失敗: \(error.localizedDescription)")
                    self.onFailure()
                }
            }
    }
}

public extension View {
    /// `pendingQuery`가 채워지면 Translation 프레임워크로 일본어→한국어 번역을 실행하고,
    /// 결과는 `onResult`, 실패는 `onFailure`로 되돌려준다
    func translateSearchTask(
        pendingQuery: String?,
        onResult: @escaping (String) -> Void,
        onFailure: @escaping () -> Void
    ) -> some View {
        self.modifier(TranslateSearchTaskModifier(pendingQuery: pendingQuery, onResult: onResult, onFailure: onFailure))
    }
}

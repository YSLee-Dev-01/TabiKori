//
//  KoreanPhraseModelContainer.swift
//  Data
//
//  Created by Claude on 8/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

import Core

public final class KoreanPhraseModelContainer: Sendable {

    // MARK: - Properties

    public static let shared = KoreanPhraseModelContainer()

    public let modelContainer: ModelContainer
    public let isFallbackToMemory: Bool

    // MARK: - Init

    private init() {
        let schema = Schema([CustomKoreanPhraseModel.self])
        do {
            let configuration = ModelConfiguration("KoreanPhrase", schema: schema)
            self.modelContainer = try ModelContainer(for: schema, configurations: configuration)
            self.isFallbackToMemory = false
        } catch {
            AppLogger.core.log(.error, "KoreanPhraseModelContainer 생성 실패, in-memory로 폴백: \(error.localizedDescription)")
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            guard let fallback = try? ModelContainer(for: schema, configurations: fallbackConfig) else {
                fatalError("KoreanPhraseModelContainer in-memory 폴백조차 실패: \(error.localizedDescription)")
            }
            self.modelContainer = fallback
            self.isFallbackToMemory = true
        }
    }
}

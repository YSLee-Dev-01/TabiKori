//
//  TestKoreanPhraseUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestKoreanPhraseUseCase: KoreanPhraseUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var phrases: [KoreanPhrase] = []
    public var customPhrases: [KoreanPhrase] = []

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetchPhrases() async throws -> [KoreanPhrase] {
        return self.phrases
    }

    public func fetchCustomPhrases() async throws -> [KoreanPhrase] {
        return self.customPhrases
    }

    public func addCustomPhrase(korean: String, japanese: String, pronunciation: String?) async throws -> KoreanPhrase {
        let phrase = KoreanPhrase(
            id: "custom_" + UUID().uuidString,
            order: 0,
            korean: korean,
            japanese: japanese,
            pronunciation: pronunciation,
            isCustom: true
        )
        self.customPhrases.append(phrase)
        return phrase
    }

    public func deleteCustomPhrase(id: String) async throws {
        self.customPhrases.removeAll { $0.id == id }
    }
}

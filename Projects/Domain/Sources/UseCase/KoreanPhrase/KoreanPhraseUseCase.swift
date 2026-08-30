//
//  KoreanPhraseUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class KoreanPhraseUseCase: KoreanPhraseUseCaseProtocol {

    // MARK: - Properties

    private let repository: KoreanPhraseRepositoryProtocol
    private let customRepository: CustomKoreanPhraseRepositoryProtocol

    // MARK: - Init

    public init(repository: KoreanPhraseRepositoryProtocol, customRepository: CustomKoreanPhraseRepositoryProtocol) {
        self.repository = repository
        self.customRepository = customRepository
    }

    // MARK: - Method

    public func fetchPhrases() async throws -> [KoreanPhrase] {
        return try await self.repository.fetchPhrases()
    }

    public func fetchCustomPhrases() async throws -> [KoreanPhrase] {
        return try await self.customRepository.fetchCustomPhrases()
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
        try await self.customRepository.addCustomPhrase(phrase, createdAt: Date())
        return phrase
    }

    public func deleteCustomPhrase(id: String) async throws {
        try await self.customRepository.deleteCustomPhrase(id: id)
    }
}

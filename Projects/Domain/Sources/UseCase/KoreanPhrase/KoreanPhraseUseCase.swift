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

    // MARK: - Init

    public init(repository: KoreanPhraseRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func fetchPhrases() async throws -> [KoreanPhrase] {
        return try await self.repository.fetchPhrases()
    }
}

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

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetchPhrases() async throws -> [KoreanPhrase] {
        return self.phrases
    }
}

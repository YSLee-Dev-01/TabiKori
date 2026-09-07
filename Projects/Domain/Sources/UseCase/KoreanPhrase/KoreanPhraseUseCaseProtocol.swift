//
//  KoreanPhraseUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol KoreanPhraseUseCaseProtocol: Sendable {
    func fetchPhrases() async throws -> [KoreanPhrase]
    func fetchCustomPhrases() async throws -> [KoreanPhrase]
    func addCustomPhrase(korean: String, japanese: String, pronunciation: String?) async throws -> KoreanPhrase
    func deleteCustomPhrase(id: String) async throws
}

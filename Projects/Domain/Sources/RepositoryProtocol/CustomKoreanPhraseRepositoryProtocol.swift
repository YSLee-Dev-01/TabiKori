//
//  CustomKoreanPhraseRepositoryProtocol.swift
//  Domain
//
//  Created by Claude on 8/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol CustomKoreanPhraseRepositoryProtocol: Sendable {
    func fetchCustomPhrases() async throws -> [KoreanPhrase]
    func addCustomPhrase(_ phrase: KoreanPhrase, createdAt: Date) async throws
    func deleteCustomPhrase(id: String) async throws
}

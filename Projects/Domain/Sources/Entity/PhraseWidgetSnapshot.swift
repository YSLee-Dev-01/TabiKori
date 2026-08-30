//
//  PhraseWidgetSnapshot.swift
//  Domain
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct PhraseWidgetSnapshot: Codable, Equatable, Sendable {
    public let updatedAt: Date
    public let phrases: [PhraseWidgetSnapshotItem]

    public init(updatedAt: Date, phrases: [PhraseWidgetSnapshotItem]) {
        self.updatedAt = updatedAt
        self.phrases = phrases
    }

    public func phrase(at index: Int) -> PhraseWidgetSnapshotItem? {
        guard !self.phrases.isEmpty else { return nil }
        let normalizedIndex = ((index % self.phrases.count) + self.phrases.count) % self.phrases.count
        return self.phrases[normalizedIndex]
    }
}

public struct PhraseWidgetSnapshotItem: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let korean: String
    public let japanese: String
    public let pronunciation: String?

    public init(id: String, korean: String, japanese: String, pronunciation: String?) {
        self.id = id
        self.korean = korean
        self.japanese = japanese
        self.pronunciation = pronunciation
    }
}

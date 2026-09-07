//
//  KoreanPhrase.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct KoreanPhrase: Equatable, Sendable, Identifiable {
    public let id: String
    public let order: Int
    public let korean: String
    public let japanese: String
    public let pronunciation: String?
    public let isCustom: Bool

    public init(
        id: String,
        order: Int,
        korean: String,
        japanese: String,
        pronunciation: String?,
        isCustom: Bool = false
    ) {
        self.id = id
        self.order = order
        self.korean = korean
        self.japanese = japanese
        self.pronunciation = pronunciation
        self.isCustom = isCustom
    }
}

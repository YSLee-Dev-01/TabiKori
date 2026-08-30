//
//  CustomKoreanPhraseModel.swift
//  Data
//
//  Created by Claude on 8/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class CustomKoreanPhraseModel {
    @Attribute(.unique) var id: String
    var korean: String
    var japanese: String
    var pronunciation: String?
    var createdAt: Date

    init(
        id: String,
        korean: String,
        japanese: String,
        pronunciation: String?,
        createdAt: Date
    ) {
        self.id = id
        self.korean = korean
        self.japanese = japanese
        self.pronunciation = pronunciation
        self.createdAt = createdAt
    }
}

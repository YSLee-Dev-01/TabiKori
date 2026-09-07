//
//  CustomKoreanPhraseModel+.swift
//  Data
//
//  Created by Claude on 8/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

extension CustomKoreanPhraseModel {
    func toDomain(order: Int) -> KoreanPhrase {
        KoreanPhrase(
            id: self.id,
            order: order,
            korean: self.korean,
            japanese: self.japanese,
            pronunciation: self.pronunciation,
            isCustom: true
        )
    }

    convenience init(phrase: KoreanPhrase, createdAt: Date) {
        self.init(
            id: phrase.id,
            korean: phrase.korean,
            japanese: phrase.japanese,
            pronunciation: phrase.pronunciation,
            createdAt: createdAt
        )
    }
}

//
//  KoreanPhraseRepository.swift
//  Data
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

import FirebaseDatabase

public final class KoreanPhraseRepository: Sendable {

    // MARK: - Properties

    private let cache = FirebaseListCache<KoreanPhrase>()

    // MARK: - Init

    public init() {}
}

// MARK: - KoreanPhraseRepositoryProtocol

extension KoreanPhraseRepository: KoreanPhraseRepositoryProtocol {
    public func fetchPhrases() async throws -> [KoreanPhrase] {
        return try await self.cache.value {
            let databaseReference = Database.database().reference(withPath: "TabiKori/koreanPhrases")
            let snapshot = try await databaseReference.getData()

            do {
                return try snapshot.decodeOrderedList(listKey: "phrases", order: { $0.order }) { id, dict in
                    guard let order = (dict["order"] as? NSNumber)?.intValue,
                          let korean = dict["korean"] as? String,
                          let japanese = dict["japanese"] as? String else {
                        return nil
                    }
                    return KoreanPhrase(
                        id: id,
                        order: order,
                        korean: korean,
                        japanese: japanese,
                        pronunciation: dict["pronunciation"] as? String
                    )
                }
            } catch {
                AppLogger.network.log(.error, "한국어 문구 리스트 조회 실패: TabiKori/koreanPhrases/phrases 데이터 없음")
                throw error
            }
        }
    }
}

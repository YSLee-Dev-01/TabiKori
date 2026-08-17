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

    // MARK: - Init

    public init() {}
}

// MARK: - KoreanPhraseRepositoryProtocol

extension KoreanPhraseRepository: KoreanPhraseRepositoryProtocol {
    public func fetchPhrases() async throws -> [KoreanPhrase] {
        let databaseReference = Database.database().reference(withPath: "TabiKori/koreanPhrases")
        let snapshot = try await databaseReference.getData()

        guard let value = snapshot.value as? [String: Any],
              let phrases = value["phrases"] as? [String: Any],
              phrases.isEmpty == false else {
            AppLogger.network.log(.error, "한국어 문구 리스트 조회 실패: TabiKori/koreanPhrases/phrases 데이터 없음")
            throw TabiError.dataNotFound
        }

        let koreanPhrases = phrases.compactMap { key, rawValue -> KoreanPhrase? in
            guard let phraseDict = rawValue as? [String: Any],
                  let order = (phraseDict["order"] as? NSNumber)?.intValue,
                  let korean = phraseDict["korean"] as? String,
                  let japanese = phraseDict["japanese"] as? String else {
                return nil
            }
            return KoreanPhrase(
                id: key,
                order: order,
                korean: korean,
                japanese: japanese,
                pronunciation: phraseDict["pronunciation"] as? String
            )
        }

        return koreanPhrases.sorted { $0.order < $1.order }
    }
}

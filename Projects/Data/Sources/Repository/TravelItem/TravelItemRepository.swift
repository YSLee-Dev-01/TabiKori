//
//  TravelItemRepository.swift
//  Data
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

import FirebaseDatabase

public final class TravelItemRepository: Sendable {

    // MARK: - Init

    public init() {}
}

// MARK: - TravelItemRepositoryProtocol

extension TravelItemRepository: TravelItemRepositoryProtocol {
    public func fetchMasterItems() async throws -> [TravelItem] {
        let databaseReference = Database.database().reference(withPath: "TabiKori/travelItems")
        let snapshot = try await databaseReference.getData()

        guard let value = snapshot.value as? [String: Any],
              let items = value["items"] as? [String: Any],
              items.isEmpty == false else {
            AppLogger.network.log(.error, "준비물 마스터 리스트 조회 실패: TabiKori/travelItems/items 데이터 없음")
            throw TabiError.dataNotFound
        }

        let travelItems = items.compactMap { key, rawValue -> TravelItem? in
            guard let itemDict = rawValue as? [String: Any],
                  let order = (itemDict["order"] as? NSNumber)?.intValue,
                  let title = itemDict["title"] as? String else {
                return nil
            }
            return TravelItem(id: key, order: order, title: title, note: itemDict["note"] as? String)
        }

        return travelItems.sorted { $0.order < $1.order }
    }
}

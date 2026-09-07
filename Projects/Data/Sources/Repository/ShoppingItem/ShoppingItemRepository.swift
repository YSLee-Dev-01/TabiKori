//
//  ShoppingItemRepository.swift
//  Data
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

import FirebaseDatabase

public final class ShoppingItemRepository: Sendable {

    // MARK: - Properties

    private let cache = FirebaseListCache<ShoppingItem>()

    // MARK: - Init

    public init() {}
}

// MARK: - ShoppingItemRepositoryProtocol

extension ShoppingItemRepository: ShoppingItemRepositoryProtocol {
    public func fetchRecommendedItems() async throws -> [ShoppingItem] {
        return try await self.cache.value {
            let databaseReference = Database.database().reference(withPath: "TabiKori/shoppingItems")
            let snapshot = try await databaseReference.getData()

            do {
                return try snapshot.decodeOrderedList(listKey: "items", order: { $0.order }) { id, dict in
                    guard let order = (dict["order"] as? NSNumber)?.intValue,
                          let titleDict = dict["title"] as? [String: Any],
                          let title = titleDict.localizedStringValue else {
                        return nil
                    }
                    let noteDict = dict["note"] as? [String: Any]
                    return ShoppingItem(id: id, order: order, title: title, note: noteDict?.localizedStringValue)
                }
            } catch {
                AppLogger.network.log(.error, "추천 쇼핑 리스트 조회 실패: TabiKori/shoppingItems/items 데이터 없음")
                throw error
            }
        }
    }
}

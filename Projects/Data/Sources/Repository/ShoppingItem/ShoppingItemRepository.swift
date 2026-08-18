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

    // MARK: - Init

    public init() {}
}

// MARK: - ShoppingItemRepositoryProtocol

extension ShoppingItemRepository: ShoppingItemRepositoryProtocol {
    public func fetchRecommendedItems() async throws -> [ShoppingItem] {
        let databaseReference = Database.database().reference(withPath: "TabiKori/shoppingItems")
        let snapshot = try await databaseReference.getData()

        guard let value = snapshot.value as? [String: Any],
              let items = value["items"] as? [String: Any],
              items.isEmpty == false else {
            AppLogger.network.log(.error, "추천 쇼핑 리스트 조회 실패: TabiKori/shoppingItems/items 데이터 없음")
            throw TabiError.dataNotFound
        }

        let shoppingItems = items.compactMap { key, rawValue -> ShoppingItem? in
            guard let itemDict = rawValue as? [String: Any],
                  let order = (itemDict["order"] as? NSNumber)?.intValue,
                  let title = itemDict["title"] as? String else {
                return nil
            }
            return ShoppingItem(id: key, order: order, title: title, note: itemDict["note"] as? String)
        }

        return shoppingItems.sorted { $0.order < $1.order }
    }
}

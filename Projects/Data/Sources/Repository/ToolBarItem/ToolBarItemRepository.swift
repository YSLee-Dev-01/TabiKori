//
//  ToolBarItemRepository.swift
//  Data
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

import FirebaseDatabase

public final class ToolBarItemRepository: Sendable {

    // MARK: - Properties

    private let cache = FirebaseListCache<ToolBarItem>()

    // MARK: - Init

    public init() {}
}

// MARK: - ToolBarItemRepositoryProtocol

extension ToolBarItemRepository: ToolBarItemRepositoryProtocol {
    public func fetchMasterItems() async throws -> [ToolBarItem] {
        return try await self.cache.value {
            let databaseReference = Database.database().reference(withPath: "TabiKori/travelItems")
            let snapshot = try await databaseReference.getData()

            do {
                return try snapshot.decodeOrderedList(listKey: "items", order: { $0.order }) { id, dict in
                    guard let order = (dict["order"] as? NSNumber)?.intValue,
                          let title = dict["title"] as? String else {
                        return nil
                    }
                    return ToolBarItem(id: id, order: order, title: title, note: dict["note"] as? String)
                }
            } catch {
                AppLogger.network.log(.error, "준비물 마스터 리스트 조회 실패: TabiKori/travelItems/items 데이터 없음")
                throw error
            }
        }
    }
}

//
//  DataSnapshot+.swift
//  Data
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

import FirebaseDatabase

extension DataSnapshot {
    func decodeOrderedList<Item>(
        listKey: String,
        order: (Item) -> Int,
        build: (_ id: String, _ dict: [String: Any]) -> Item?
    ) throws -> [Item] {
        guard let value = self.value as? [String: Any],
              let items = value[listKey] as? [String: Any],
              items.isEmpty == false else {
            throw TabiError.dataNotFound
        }

        let builtItems = items.compactMap { key, rawValue -> Item? in
            guard let dict = rawValue as? [String: Any] else { return nil }
            return build(key, dict)
        }

        return builtItems.sorted { order($0) < order($1) }
    }
}

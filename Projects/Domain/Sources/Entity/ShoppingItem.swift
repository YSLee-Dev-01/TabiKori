//
//  ShoppingItem.swift
//  Domain
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct ShoppingItem: Equatable, Sendable, Identifiable {
    public let id: String
    public let order: Int
    public let title: String
    public let note: String?

    public init(id: String, order: Int, title: String, note: String?) {
        self.id = id
        self.order = order
        self.title = title
        self.note = note
    }
}

//
//  ToastItem.swift
//  Domain
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct ToastItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let message: String
    public let type: ToastType

    public init(id: UUID = UUID(), message: String, type: ToastType) {
        self.id = id
        self.message = message
        self.type = type
    }
}

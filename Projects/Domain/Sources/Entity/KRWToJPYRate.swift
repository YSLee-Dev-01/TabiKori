//
//  KRWToJPYRate.swift
//  Domain
//
//  Created by 이윤수 on 7/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct KRWToJPYRate: Equatable, Sendable {
    public let rate: Double
    public let updatedAt: Date

    public init(rate: Double, updatedAt: Date) {
        self.rate = rate
        self.updatedAt = updatedAt
    }
}

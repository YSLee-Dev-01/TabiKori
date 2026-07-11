//
//  ExchangeRate.swift
//  Domain
//
//  Created by 이윤수 on 7/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct ExchangeRate: Equatable, Sendable, Codable {
    public let currencyCode: String
    public let currencyName: String
    public let unitScale: Int
    public let baseRate: Double

    public init(currencyCode: String, currencyName: String, unitScale: Int, baseRate: Double) {
        self.currencyCode = currencyCode
        self.currencyName = currencyName
        self.unitScale = unitScale
        self.baseRate = baseRate
    }
}

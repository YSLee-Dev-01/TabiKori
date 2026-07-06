//
//  ExchangeRateError.swift
//  Domain
//
//  Created by 이윤수 on 7/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum ExchangeRateError: Error, Equatable, Sendable {
    case currencyNotFound
}

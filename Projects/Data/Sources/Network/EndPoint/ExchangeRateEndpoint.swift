//
//  ExchangeRateEndpoint.swift
//  Data
//
//  Created by 이윤수 on 7/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

enum ExchangeRateEndpoint: Endpoint {
    case today

    var baseURL: String {
        switch self {
        case .today: return "https://oapi.koreaexim.go.kr"
        }
    }

    var path: String {
        switch self {
        case .today: return "/site/program/financial/exchangeJSON"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .today:
            return [
                URLQueryItem(name: "authkey", value: Secret.exchangeAPIKey),
                URLQueryItem(name: "data", value: "AP01")
            ]
        }
    }

    var method: HTTPMethod  {
        return .get
    }
}

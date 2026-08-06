//
//  NaverGeocodingEndpoint.swift
//  Data
//
//  Created by 이윤수 on 8/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

enum NaverGeocodingEndpoint: Endpoint {
    case geocode(address: String)

    var baseURL: String {
        switch self {
        case .geocode: return "https://maps.apigw.ntruss.com"
        }
    }

    var path: String {
        switch self {
        case .geocode: return "/map-geocode/v2/geocode"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .geocode(let address):
            return [URLQueryItem(name: "query", value: address)]
        }
    }

    var headers: [String: String] {
        return [
            "x-ncp-apigw-api-key-id": Secret.naverMapClientID,
            "x-ncp-apigw-api-key": Secret.naverGeocodingClientSecret,
            "Accept": "application/json"
        ]
    }

    var method: HTTPMethod {
        return .get
    }
}

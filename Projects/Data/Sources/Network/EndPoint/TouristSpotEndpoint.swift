//
//  TouristSpotEndpoint.swift
//  Data
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

enum TouristSpotEndpoint: Endpoint {
    case nearbySpots(contentType: CategoryType, coordinate: Coordinate, radiusMeters: Int)

    var baseURL: String {
        switch self {
        case .nearbySpots: return "https://apis.data.go.kr"
        }
    }

    var path: String {
        switch self {
        case .nearbySpots: return "/B551011/KorService2/locationBasedList2"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .nearbySpots(let contentType, let coordinate, let radiusMeters):
            return [
                URLQueryItem(name: "MobileOS", value: "IOS"),
                URLQueryItem(name: "MobileApp", value: "TabiKori"),
                URLQueryItem(name: "serviceKey", value: Secret.tourAPIKey),
                URLQueryItem(name: "_type", value: "json"),
                URLQueryItem(name: "arrange", value: "E"),
                URLQueryItem(name: "numOfRows", value: "50"),
                URLQueryItem(name: "pageNo", value: "1"),
                URLQueryItem(name: "contentTypeId", value: contentType.apiCode),
                URLQueryItem(name: "mapX", value: "\(coordinate.longitude)"),
                URLQueryItem(name: "mapY", value: "\(coordinate.latitude)"),
                URLQueryItem(name: "radius", value: "\(radiusMeters)")
            ]
        }
    }

    var method: HTTPMethod {
        return .get
    }
}

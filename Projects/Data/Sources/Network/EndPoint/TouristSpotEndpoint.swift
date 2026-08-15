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
    case nearbySpots(contentType: CategoryType, coordinate: Coordinate, radiusMeters: Int, pageNo: Int)
    case areaBasedSpots(region: KoreanRegion, contentType: CategoryType, pageNo: Int)
    case detail(contentId: String)
    case intro(contentId: String, contentType: CategoryType)
    case images(contentId: String)
    case searchKeyword(keyword: String, pageNo: Int)

    var baseURL: String {
        switch self {
        case .nearbySpots, .areaBasedSpots, .detail, .intro, .images, .searchKeyword: return "https://apis.data.go.kr"
        }
    }

    var path: String {
        switch self {
        case .nearbySpots: return "/B551011/JpnService2/locationBasedList2"
        case .areaBasedSpots: return "/B551011/JpnService2/areaBasedList2"
        case .detail: return "/B551011/JpnService2/detailCommon2"
        case .intro: return "/B551011/JpnService2/detailIntro2"
        case .images: return "/B551011/JpnService2/detailImage2"
        case .searchKeyword: return "/B551011/JpnService2/searchKeyword2"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .nearbySpots(let contentType, let coordinate, let radiusMeters, let pageNo):
            return [
                URLQueryItem(name: "MobileOS", value: "IOS"),
                URLQueryItem(name: "MobileApp", value: "TabiKori"),
                URLQueryItem(name: "serviceKey", value: Secret.tourAPIKey),
                URLQueryItem(name: "_type", value: "json"),
                URLQueryItem(name: "arrange", value: "E"),
                URLQueryItem(name: "numOfRows", value: "50"),
                URLQueryItem(name: "pageNo", value: "\(pageNo)"),
                URLQueryItem(name: "contentTypeId", value: contentType.apiCode),
                URLQueryItem(name: "mapX", value: "\(coordinate.longitude)"),
                URLQueryItem(name: "mapY", value: "\(coordinate.latitude)"),
                URLQueryItem(name: "radius", value: "\(radiusMeters)")
            ]
        case .areaBasedSpots(let region, let contentType, let pageNo):
            var items = [
                URLQueryItem(name: "MobileOS", value: "IOS"),
                URLQueryItem(name: "MobileApp", value: "TabiKori"),
                URLQueryItem(name: "serviceKey", value: Secret.tourAPIKey),
                URLQueryItem(name: "_type", value: "json"),
                URLQueryItem(name: "arrange", value: "Q"),
                URLQueryItem(name: "numOfRows", value: "50"),
                URLQueryItem(name: "pageNo", value: "\(pageNo)"),
                URLQueryItem(name: "contentTypeId", value: contentType.apiCode),
                URLQueryItem(name: "areaCode", value: region.areaCode)
            ]
            if let sigunguCode = region.sigunguCode {
                items.append(URLQueryItem(name: "sigunguCode", value: sigunguCode))
            }
            return items
        case .detail(let contentId):
            return [
                URLQueryItem(name: "MobileOS", value: "IOS"),
                URLQueryItem(name: "MobileApp", value: "TabiKori"),
                URLQueryItem(name: "serviceKey", value: Secret.tourAPIKey),
                URLQueryItem(name: "_type", value: "json"),
                URLQueryItem(name: "numOfRows", value: "1"),
                URLQueryItem(name: "pageNo", value: "1"),
                URLQueryItem(name: "contentId", value: contentId)
            ]
        case .intro(let contentId, let contentType):
            return [
                URLQueryItem(name: "MobileOS", value: "IOS"),
                URLQueryItem(name: "MobileApp", value: "TabiKori"),
                URLQueryItem(name: "serviceKey", value: Secret.tourAPIKey),
                URLQueryItem(name: "_type", value: "json"),
                URLQueryItem(name: "numOfRows", value: "1"),
                URLQueryItem(name: "pageNo", value: "1"),
                URLQueryItem(name: "contentId", value: contentId),
                URLQueryItem(name: "contentTypeId", value: contentType.apiCode)
            ]
        case .images(let contentId):
            return [
                URLQueryItem(name: "MobileOS", value: "IOS"),
                URLQueryItem(name: "MobileApp", value: "TabiKori"),
                URLQueryItem(name: "serviceKey", value: Secret.tourAPIKey),
                URLQueryItem(name: "_type", value: "json"),
                URLQueryItem(name: "numOfRows", value: "50"),
                URLQueryItem(name: "pageNo", value: "1"),
                URLQueryItem(name: "contentId", value: contentId),
                URLQueryItem(name: "imageYN", value: "Y")
            ]
        case .searchKeyword(let keyword, let pageNo):
            return [
                URLQueryItem(name: "MobileOS", value: "IOS"),
                URLQueryItem(name: "MobileApp", value: "TabiKori"),
                URLQueryItem(name: "serviceKey", value: Secret.tourAPIKey),
                URLQueryItem(name: "_type", value: "json"),
                URLQueryItem(name: "arrange", value: "A"),
                URLQueryItem(name: "numOfRows", value: "50"),
                URLQueryItem(name: "pageNo", value: "\(pageNo)"),
                URLQueryItem(name: "keyword", value: keyword)
            ]
        }
    }

    var method: HTTPMethod {
        return .get
    }
}

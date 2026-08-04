//
//  FestivalEndpoint.swift
//  Data
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

enum FestivalEndpoint: Endpoint {
    case searchFestival(startDate: Date, endDate: Date?, regionCode: String?, pageNo: Int)
    case ldongCode

    var baseURL: String {
        switch self {
        case .searchFestival, .ldongCode: return "https://apis.data.go.kr"
        }
    }

    var path: String {
        switch self {
        case .searchFestival: return "/B551011/JpnService2/searchFestival2"
        case .ldongCode: return "/B551011/JpnService2/ldongCode2"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .searchFestival(let startDate, let endDate, let regionCode, let pageNo):
            var items = [
                URLQueryItem(name: "MobileOS", value: "IOS"),
                URLQueryItem(name: "MobileApp", value: "TabiKori"),
                URLQueryItem(name: "serviceKey", value: Secret.tourAPIKey),
                URLQueryItem(name: "_type", value: "json"),
                URLQueryItem(name: "arrange", value: "A"),
                URLQueryItem(name: "numOfRows", value: "50"),
                URLQueryItem(name: "pageNo", value: "\(pageNo)"),
                URLQueryItem(name: "eventStartDate", value: startDate.festivalQueryDateString)
            ]
            if let endDate {
                items.append(URLQueryItem(name: "eventEndDate", value: endDate.festivalQueryDateString))
            }
            if let regionCode {
                items.append(URLQueryItem(name: "lDongRegnCd", value: regionCode))
            }
            return items

        case .ldongCode:
            return [
                URLQueryItem(name: "MobileOS", value: "IOS"),
                URLQueryItem(name: "MobileApp", value: "TabiKori"),
                URLQueryItem(name: "serviceKey", value: Secret.tourAPIKey),
                URLQueryItem(name: "_type", value: "json"),
                URLQueryItem(name: "numOfRows", value: "20"),
                URLQueryItem(name: "pageNo", value: "1"),
                URLQueryItem(name: "lDongListYn", value: "N")
            ]
        }
    }

    var method: HTTPMethod {
        return .get
    }
}

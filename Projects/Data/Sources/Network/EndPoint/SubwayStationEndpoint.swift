//
//  SubwayStationEndpoint.swift
//  Data
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

enum SubwayStationEndpoint: Endpoint {
    case search(stationName: String)

    var baseURL: String {
        switch self {
        case .search: return "http://openapi.seoul.go.kr:8088"
        }
    }

    var path: String {
        switch self {
        case .search(let stationName):
            let encodedName = stationName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? stationName
            return "/\(Secret.seoulSubwayAPIKey)/json/SearchInfoBySubwayNameService/1/5/\(encodedName)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .search: return .get
        }
    }

    /// 인증키가 path에 포함되므로 로그로 노출되지 않도록 비활성화
    var enableLog: Bool {
        return false
    }
}

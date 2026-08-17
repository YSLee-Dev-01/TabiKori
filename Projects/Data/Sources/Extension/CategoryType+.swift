//
//  CategoryType+.swift
//  Data
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

extension CategoryType {
    var apiCode: String {
        switch self {
        case .sightseeing: return "76"
        case .food: return "82"
        case .hotel: return "80"
        case .festival: return "85"
        case .shopping: return "79"
        case .nature: return "75"
        case .subway:
            AppLogger.network.log(.error, "지하철 카테고리는 관광공사 API 대상이 아닙니다")
            return ""
        }
    }

    init?(apiCode: String) {
        switch apiCode {
        case "76", "78": self = .sightseeing
        case "82": self = .food
        case "80": self = .hotel
        case "85": self = .festival
        case "79": self = .shopping
        case "75": self = .nature
        default: return nil
        }
    }
}

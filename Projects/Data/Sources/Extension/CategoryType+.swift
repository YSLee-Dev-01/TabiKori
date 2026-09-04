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
        Locale.current.language.languageCode == .korean ? self.koreanApiCode : self.multilingualApiCode
    }

    init?(apiCode: String) {
        switch apiCode {
        case "76", "78", "12", "14": self = .sightseeing
        case "82", "39": self = .food
        case "80", "32": self = .hotel
        case "85", "15": self = .festival
        case "79", "38": self = .shopping
        case "75", "28": self = .nature
        default: return nil
        }
    }
}

// MARK: - Method
private extension CategoryType {
    /// 다국어 서비스(JpnService2 등) 전용 contentTypeId
    var multilingualApiCode: String {
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

    /// 국문 서비스(KorService2) 전용 contentTypeId
    var koreanApiCode: String {
        switch self {
        case .sightseeing: return "12"
        case .food: return "39"
        case .hotel: return "32"
        case .festival: return "15"
        case .shopping: return "38"
        case .nature: return "28"
        case .subway:
            AppLogger.network.log(.error, "지하철 카테고리는 관광공사 API 대상이 아닙니다")
            return ""
        }
    }
}

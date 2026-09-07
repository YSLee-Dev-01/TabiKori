//
//  KoreanRegion+.swift
//  Data
//
//  Created by 이윤수 on 8/10/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

extension KoreanRegion {
    var areaCode: String? {
        switch self {
        case .seoul: return "1"
        case .busan: return "6"
        case .jeju: return "39"
        case .gyeongju: return "35"
        case .yeosu: return "38"
        case .gangneung: return "32"
        case .jeonju: return "37"
        case .etc: return nil
        }
    }

    var sigunguCode: String? {
        switch self {
        case .gyeongju: return "2"
        case .yeosu: return "13"
        case .gangneung: return "1"
        case .jeonju: return "12"
        case .seoul, .busan, .jeju, .etc: return nil
        }
    }

    var lDongRegnCd: String? {
        switch self {
        case .seoul: return "11"
        case .busan: return "26"
        case .jeju: return "50"
        case .gyeongju: return "47"
        case .yeosu: return "12"
        case .gangneung: return "51"
        case .jeonju: return "52"
        case .etc: return nil
        }
    }

    var lDongSignguCd: String? {
        switch self {
        case .gyeongju: return "130"
        case .yeosu: return "130"
        case .gangneung: return "150"
        case .jeonju: return "110"
        case .seoul, .busan, .jeju, .etc: return nil
        }
    }
}

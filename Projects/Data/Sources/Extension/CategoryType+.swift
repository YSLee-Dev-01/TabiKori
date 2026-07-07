//
//  CategoryType+.swift
//  Data
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

extension CategoryType {
    var apiCode: String {
        switch self {
        case .sightseeing: return "12"
        case .food: return "39"
        case .hotel: return "32"
        case .festival: return "15"
        case .shopping: return "38"
        case .nature: return "28"
        }
    }

    init?(apiCode: String) {
        switch apiCode {
        case "12", "14": self = .sightseeing
        case "39": self = .food
        case "32": self = .hotel
        case "15": self = .festival
        case "38": self = .shopping
        case "28": self = .nature
        default: return nil
        }
    }
}

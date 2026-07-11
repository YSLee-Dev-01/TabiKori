//
//  CategoryType+.swift
//  Presentation
//
//  Created by 이윤수 on 6/22/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Domain
import Resource

extension CategoryType {

    var icon: TabiIcon {
        switch self {
        case .sightseeing: .sightseeing
        case .food: .food
        case .hotel: .hotel
        case .festival: .festival
        case .shopping: .shopping
        case .nature: .nature
        }
    }

    var color: TabiColor {
        switch self {
        case .sightseeing: .categorySightseeing
        case .food: .categoryFood
        case .hotel: .categoryHotel
        case .festival: .categoryFestival
        case .shopping: .categoryShopping
        case .nature: .categoryNature
        }
    }

    var label: String {
        switch self {
        case .sightseeing: Strings.Common.categorySightseeing
        case .food: Strings.Common.categoryFood
        case .hotel: Strings.Common.categoryHotel
        case .festival: Strings.Common.categoryFestival
        case .shopping: Strings.Common.categoryShopping
        case .nature: Strings.Common.categoryNature
        }
    }

    @MainActor static let allItems: [Self] = [
        .sightseeing, .food, .hotel, .festival, .shopping, .nature
    ]
}

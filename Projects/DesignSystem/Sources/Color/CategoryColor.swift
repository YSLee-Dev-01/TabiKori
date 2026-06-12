//
//  CategoryColor.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

public enum CategoryColor {
    case sightseeing
    case food
    case hotel
    case festival
    case shopping
    case nature

    public var color: Color {
        switch self {
        case .sightseeing: return Color(red: 0.769, green: 0.392, blue: 0.353) // #C4645A
        case .food: return Color(red: 0.416, green: 0.624, blue: 0.753) // #6A9FC0
        case .hotel: return Color(red: 0.608, green: 0.518, blue: 0.784) // #9B84C8
        case .festival: return Color(red: 0.831, green: 0.533, blue: 0.478) // #D4887A
        case .shopping: return Color(red: 0.431, green: 0.722, blue: 0.600) // #6EB899
        case .nature: return Color(red: 0.353, green: 0.620, blue: 0.478) // #5A9E7A
        }
    }
}

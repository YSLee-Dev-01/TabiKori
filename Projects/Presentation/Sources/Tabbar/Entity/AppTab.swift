//
//  AppTab.swift
//  Presentation
//
//  Created by 이윤수 on 6/16/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum AppTab: CaseIterable {
    case home
    case map
    case plan
    case save
    case search

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .map: return "map"
        case .plan: return "calendar"
        case .save: return "bookmark"
        case .search: return "magnifyingglass"
        }
    }
}

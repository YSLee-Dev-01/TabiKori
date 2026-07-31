//
//  PlanSection.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Resource

enum PlanSection: CaseIterable {
    case ongoing
    case upcoming
    case past

    var title: String {
        switch self {
        case .ongoing: return Strings.Plan.ongoingSectionTitle
        case .upcoming: return Strings.Plan.upcomingSectionTitle
        case .past: return Strings.Plan.pastSectionTitle
        }
    }
}

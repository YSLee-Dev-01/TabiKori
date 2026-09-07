//
//  AddToItineraryEmptyState.swift
//  Presentation
//
//  Created by 이윤수 on 8/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// 등록된 일정이 없을 때 표시되는 빈 상태
struct AddToItineraryEmptyState: View {
    var body: some View {
        TabiEmptyState(
            systemImageName: "calendar.badge.plus",
            description: Strings.Plan.emptyTitle,
            style: .card
        )
    }
}

//
//  PlanDetailSpotEmptyState.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct PlanDetailSpotEmptyState: View {

    var body: some View {
        TabiEmptyState(
            systemImageName: "calendar",
            title: Strings.Plan.spotEmptyTitle,
            description: Strings.Plan.spotEmptyDescription,
            style: .card
        )
    }
}

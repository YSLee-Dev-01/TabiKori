//
//  PlanDetailMapEmptyState.swift
//  Presentation
//
//  Created by 이윤수 on 8/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// 해당 일자에 좌표를 가진 스팟이 없을 때 `PlanDetailMapSection`과 동일한 크기로 표시하는 빈 상태
struct PlanDetailMapEmptyState: View {

    var body: some View {
        TabiEmptyState(
            systemImageName: "map",
            description: Strings.Plan.mapEmptyDescription,
            style: .card
        )
        .frame(height: 200)
        .padding(.horizontal, 20)
    }
}

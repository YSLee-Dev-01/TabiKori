//
//  OnboardingPlanStepView.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct OnboardingPlanStepView: View {
    var body: some View {
        OnboardingStepFrame(
            title: OnboardingStep.plan.title,
            description: OnboardingStep.plan.description
        ) {
            VStack(spacing: 16) {
                ForEach(OnboardingMock.plans) { plan in
                    PlanCardView(plan: plan, spotCount: OnboardingMock.planDetail.spots.count, onTapped: {})
                }
            }
        }
    }
}

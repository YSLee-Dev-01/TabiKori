//
//  OnboardingAgreementStepView.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct OnboardingAgreementStepView: View {
    let currentCoachMark: OnboardingCoachMark
    let hasViewedPolicy: Bool
    let isAgreed: Bool
    let onViewPolicyTapped: () -> Void
    let onCheckBoxTapped: () -> Void
    let onStartTapped: () -> Void

    var body: some View {
        OnboardingStepFrame(
            title: OnboardingStep.agreement.title,
            description: OnboardingStep.agreement.description,
            scrollTarget: self.currentCoachMark
        ) {
            VStack(alignment: .leading, spacing: 20) {
                TabiButton(
                    Strings.Onboarding.viewPrivacyPolicyButtonTitle,
                    style: .secondary,
                    isExpanded: true,
                    action: self.onViewPolicyTapped
                )
                .onboardingHighlight(OnboardingCoachMark.agreementPolicyButton)

                VStack(alignment: .leading, spacing: 8) {
                    OnboardingAgreementCheckBox(
                        isEnabled: self.hasViewedPolicy,
                        isChecked: self.isAgreed,
                        onTapped: self.onCheckBoxTapped
                    )
                    .onboardingHighlight(OnboardingCoachMark.agreementCheckBox)

                    if self.hasViewedPolicy == false {
                        TabiLabel(
                            title: Strings.Onboarding.privacyPolicyUnviewedGuide,
                            style: .captionM,
                            color: .tabiTextTertiary
                        )
                    }
                }

                TabiButton(
                    Strings.Onboarding.startButtonTitle,
                    style: .primary,
                    isExpanded: true,
                    action: self.onStartTapped
                )
                .disabled(self.isAgreed == false)
                .onboardingHighlight(OnboardingCoachMark.agreementStartButton)
            }
        }
    }
}

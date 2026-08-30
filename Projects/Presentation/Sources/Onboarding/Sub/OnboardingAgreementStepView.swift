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
    let hasViewedPolicy: Bool
    let isAgreed: Bool
    let onViewPolicyTapped: () -> Void
    let onCheckBoxTapped: () -> Void

    var body: some View {
        OnboardingStepFrame(
            title: OnboardingStep.agreement.title,
            description: OnboardingStep.agreement.description
        ) {
            VStack(alignment: .leading, spacing: 20) {
                TabiButton(
                    Strings.Onboarding.viewPrivacyPolicyButtonTitle,
                    style: .secondary,
                    isExpanded: true,
                    action: self.onViewPolicyTapped
                )

                VStack(alignment: .leading, spacing: 8) {
                    OnboardingAgreementCheckBox(
                        isEnabled: self.hasViewedPolicy,
                        isChecked: self.isAgreed,
                        onTapped: self.onCheckBoxTapped
                    )

                    if self.hasViewedPolicy == false {
                        TabiLabel(
                            title: Strings.Onboarding.privacyPolicyUnviewedGuide,
                            style: .captionM,
                            color: .tabiTextTertiary
                        )
                    }
                }
            }
        }
    }
}

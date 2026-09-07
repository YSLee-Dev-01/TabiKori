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

/// 약관동의 스텝은 다른 스텝과 달리 스포트라이트/툴팁 가이드 없이 세 요소(정책 보기/체크박스/시작하기)를
/// 순서 강제 없이 자유롭게 누를 수 있게 한다(웹뷰 열람 전 체크 불가·미동의 시 시작 불가 같은 기능적
/// 제약은 `OnboardingFeature`에서 그대로 유지)
struct OnboardingAgreementStepView: View {
    let hasViewedPolicy: Bool
    let isAgreed: Bool
    let onViewPolicyTapped: () -> Void
    let onCheckBoxTapped: () -> Void
    let onStartTapped: () -> Void

    var body: some View {
        OnboardingStepFrame(
            title: OnboardingStep.agreement.title,
            description: OnboardingStep.agreement.description,
            scrollTarget: nil
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

                TabiButton(
                    Strings.Onboarding.startButtonTitle,
                    style: .primary,
                    isExpanded: true,
                    action: self.onStartTapped
                )
                .disabled(self.isAgreed == false)
            }
        }
    }
}

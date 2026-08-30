//
//  OnboardingAgreementCheckBox.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// 약관동의 체크박스. 온보딩에서만 쓰이는 단일 사용처 컴포넌트로 DesignSystem이 아닌 Presentation 내부에 위치
struct OnboardingAgreementCheckBox: View {
    let isEnabled: Bool
    let isChecked: Bool
    let onTapped: () -> Void

    var body: some View {
        Button {
            self.onTapped()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: self.isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundStyle(self.isChecked ? TabiColor.tabiPrimary : TabiColor.tabiTextTertiary)

                TabiLabel(
                    title: Strings.Onboarding.privacyPolicyAgreementLabel,
                    style: .bodyM,
                    color: .tabiTextPrimary
                )
            }
        }
        .buttonStyle(TabiPressStyle())
        .disabled(self.isEnabled == false)
        .opacity(self.isEnabled ? 1 : 0.4)
    }
}

//
//  OnboardingWelcomeStepView.swift
//  Presentation
//
//  Created by Claude on 8/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Lottie
import Resource

/// 온보딩 최초 진입 시 기능 소개(코치마크 흐름)에 앞서 노출되는 환영 스텝.
/// `OnboardingCoachMark` 흐름에 속하지 않는 독립 화면이라 하이라이트/스포트라이트 없이
/// 자유롭게 탭할 수 있는 시작 버튼만 제공한다
struct OnboardingWelcomeStepView: View {
    let onStartTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            LottieView(animation: .named("Congratulations", bundle: ResourceResources.bundle))
                .playing(loopMode: .loop)
                .resizable()
                .frame(width: 220, height: 220)

            VStack(spacing: 8) {
                TabiLabel(
                    title: Strings.Onboarding.welcomeTitle,
                    style: .titleL,
                    color: .tabiTextPrimary,
                    alignment: .center,
                    isExpanded: true
                )
                TabiLabel(
                    title: Strings.Onboarding.welcomeDescription,
                    style: .bodyM,
                    color: .tabiTextSecondary,
                    alignment: .center,
                    isExpanded: true
                )
            }
            .padding(.horizontal, 20)

            Spacer()

            TabiButton(
                Strings.Onboarding.welcomeButtonTitle,
                style: .primary,
                isExpanded: true,
                action: self.onStartTapped
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TabiColor.tabiBackground)
    }
}

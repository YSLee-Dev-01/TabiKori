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
        VStack(spacing: 8) {
            Spacer()

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

            Spacer()

            TabiButton(
                Strings.Onboarding.welcomeButtonTitle,
                style: .primary,
                isExpanded: true,
                action: self.onStartTapped
            )
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            // 배경(로티 애니메이션)만 세이프에어리어를 무시해 화면 전체를 덮고,
            // 전경(텍스트/버튼)은 세이프에어리어 안쪽에 그대로 위치시켜 하단 버튼이 홈 인디케이터 위로 밀리지 않게 한다
            GeometryReader { proxy in
                ZStack {
                    Color.getTabiColor(.tabiBackground)

                    LottieView(animation: .named("Congratulations", bundle: ResourceResources.bundle))
                        .playing(loopMode: .loop)
                        .resizable()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .ignoresSafeArea()
        }
    }
}

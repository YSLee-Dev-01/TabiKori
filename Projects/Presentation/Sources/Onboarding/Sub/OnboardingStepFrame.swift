//
//  OnboardingStepFrame.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// 온보딩 각 스텝의 상단 카피(제목/설명) 영역을 통일하고 하단에 콘텐츠 슬롯을 배치하는 공용 프레임.
/// 코치마크 하이라이트 대상이 화면 밖에 있을 수 있으므로 `scrollTarget`이 바뀌면 자동으로 스크롤해 노출시킨다
struct OnboardingStepFrame<Content: View>: View {
    let title: String
    let description: String
    let scrollTarget: OnboardingCoachMark?
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        TabiLabel(title: self.title, style: .titleL, color: .tabiTextPrimary)
                        TabiLabel(title: self.description, style: .bodyM, color: .tabiTextSecondary)
                    }

                    self.content()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(true)
            .task(id: self.scrollTarget) {
                guard let scrollTarget = self.scrollTarget else { return }
                withAnimation(.tabiStandard) {
                    proxy.scrollTo(scrollTarget, anchor: .center)
                }
            }
        }
    }
}

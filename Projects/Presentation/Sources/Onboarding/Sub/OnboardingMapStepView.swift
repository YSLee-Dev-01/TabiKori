//
//  OnboardingMapStepView.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// 실제 NaverMap SDK(TabiMapView)를 쓰지 않고, 정적 이미지 위에 마커를 고정 배치한 지도 목업.
/// 온보딩 체험 화면은 네트워크·위치 호출이 없어야 하므로 실제 지도 렌더링을 대체한다
struct OnboardingMapStepView: View {
    var body: some View {
        OnboardingStepFrame(
            title: OnboardingStep.map.title,
            description: OnboardingStep.map.description
        ) {
            VStack(alignment: .leading, spacing: 20) {
                self.mapMock()
                self.searchPanel()
            }
        }
    }
}

// MARK: - View

private extension OnboardingMapStepView {
    func mapMock() -> some View {
        RoundedRectangle(cornerRadius: .tabiRadiusLg)
            .fill(TabiColor.tabiSurfaceElevated)
            .overlay {
                RoundedRectangle(cornerRadius: .tabiRadiusLg)
                    .stroke(TabiColor.tabiBorder, lineWidth: 1)
            }
            .frame(height: 260)
            .overlay {
                ZStack {
                    self.markerPin(color: .categorySightseeing)
                        .offset(x: -60, y: -40)
                    self.markerPin(color: .categoryFood)
                        .offset(x: 40, y: -10)
                    self.markerPin(color: .categoryShopping)
                        .offset(x: -10, y: 50)
                }
            }
    }

    func markerPin(color: TabiColor) -> some View {
        Circle()
            .fill(color)
            .overlay {
                Image(systemName: "mappin")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(TabiColor.tabiOnColor)
            }
            .overlay {
                Circle()
                    .stroke(TabiColor.tabiOnColor, lineWidth: 2)
            }
            .frame(width: 32, height: 32)
    }

    func searchPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TabiSearchField(placeholder: Strings.Map.searchPlaceholder) {}

            VStack(spacing: 12) {
                ForEach(OnboardingMock.searchResults) { spot in
                    TabiCard {
                        MapSearchResultRowView(spot: spot, onTapped: {})
                    }
                }
            }
        }
    }
}

//
//  OnboardingMapBackgroundMockView.swift
//  Presentation
//
//  Created by Claude on 8/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// 실제 NaverMap SDK(TabiMapView)를 쓰지 않고, 정적 색상 배경 위에 마커를 고정 배치한 지도 목업.
/// 온보딩 체험 화면은 실제 지도 타일 네트워크 호출이 없어야 하므로, `MapView`의 지도 배경 주입 지점
/// (`mapBackgroundOverride`)에 이 뷰를 대신 전달해 실제 지도 렌더링을 대체한다
struct OnboardingMapBackgroundMockView: View {
    var body: some View {
        Rectangle()
            .fill(TabiColor.tabiSurfaceElevated)
            .overlay {
                ZStack {
                    self.markerPin(color: .categorySightseeing)
                        .offset(x: -70, y: -140)
                    self.markerPin(color: .categoryFood)
                        .offset(x: 60, y: -60)
                    self.markerPin(color: .categoryShopping)
                        .offset(x: -30, y: 40)
                }
            }
            .ignoresSafeArea()
    }
}

// MARK: - View

private extension OnboardingMapBackgroundMockView {
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
}

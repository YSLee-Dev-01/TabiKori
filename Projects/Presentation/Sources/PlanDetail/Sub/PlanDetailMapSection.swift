//
//  PlanDetailMapSection.swift
//  Presentation
//
//  Created by 이윤수 on 8/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct PlanDetailMapSection: View {
    let markers: [TabiMapMarker]
    let fitToken: Int
    let onFullMapTapped: () -> Void

    var body: some View {
        TabiMapView(
            centerLatitude: self.markers.first?.latitude ?? Coordinate.seoulCityHall.latitude,
            centerLongitude: self.markers.first?.longitude ?? Coordinate.seoulCityHall.longitude,
            markers: self.markers,
            isClusteringEnabled: false,
            showsPolyline: true,
            showsLocationButton: false,
            showsZoomControls: false,
            followsUserLocation: false,
            boundsFitToken: self.fitToken,
            onMapTapped: { _, _ in },
            onMarkerTapped: { _ in }
        )
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusLg))
        .overlay {
            RoundedRectangle(cornerRadius: .tabiRadiusLg)
                .stroke(TabiColor.tabiBorder.opacity(0.4), lineWidth: 1)
        }
        .overlay(alignment: .topTrailing) {
            TabiGlassIconButton(systemName: "arrow.up.left.and.arrow.down.right", size: .sm) {
                self.onFullMapTapped()
            }
            .accessibilityLabel(Strings.Plan.fullMapButtonAccessibilityLabel)
            .padding(10)
            // 온보딩 코치마크는 이 버튼(지도 전체보기)을 하이라이트한다. 프로덕션 화면에서는 항상 부착되지만
            // 온보딩 화면 밖에서는 아무도 이 anchorPreference 값을 읽지 않으므로 동작에 영향이 없다
            .onboardingHighlight("planDetailFullMapButton")
        }
        .padding(.horizontal, 20)
    }
}

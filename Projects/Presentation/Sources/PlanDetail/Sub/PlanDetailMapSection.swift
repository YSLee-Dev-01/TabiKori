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
        }
        .padding(.horizontal, 20)
    }
}

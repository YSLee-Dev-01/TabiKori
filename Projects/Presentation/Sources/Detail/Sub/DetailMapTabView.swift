//
//  DetailMapTabView.swift
//  Presentation
//
//  Created by 이윤수 on 7/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Core
import DesignSystem
import Domain
import Resource

struct DetailMapTabView: View {
    let touristSpotID: String
    let title: String
    let coordinate: Coordinate
    let onViewInMapTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TabiMapView(
                centerLatitude: self.coordinate.latitude,
                centerLongitude: self.coordinate.longitude,
                markers: [
                    TabiMapMarker(
                        id: self.touristSpotID,
                        latitude: self.coordinate.latitude,
                        longitude: self.coordinate.longitude,
                        title: self.title.removingHangul
                    )
                ],
                onMapTapped: { _, _ in },
                onMarkerTapped: { _ in }
            )
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusLg))
            .overlay {
                RoundedRectangle(cornerRadius: .tabiRadiusLg)
                    .stroke(TabiColor.tabiBorder.opacity(0.4), lineWidth: 1)
            }
            HStack {
                Spacer()
                TabiButton(
                    Strings.Detail.viewInMap,
                    style: .secondary,
                    icon: Image(systemName: "arrow.up.right.square")
                ) {
                    self.onViewInMapTapped()
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

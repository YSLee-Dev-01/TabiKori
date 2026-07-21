//
//  DetailMapTabView.swift
//  Presentation
//
//  Created by 이윤수 on 7/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct DetailMapTabView: View {
    let touristSpotID: String
    let title: String
    let coordinate: Coordinate

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
                        title: self.title
                    )
                ],
                onMapTapped: { _, _ in },
                onMarkerTapped: { _ in }
            )
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusLg))
            .overlay {
                RoundedRectangle(cornerRadius: .tabiRadiusLg)
                    .stroke(TabiColor.tabiBorder.opacity(0.4), lineWidth: 1)
            }
            HStack {
                Spacer()
                TabiButton(
                    Strings.Detail.openInMaps,
                    style: .secondary,
                    icon: Image(systemName: "arrow.up.right.square")
                ) {}
                .disabled(true)
            }
        }
        .padding(.horizontal, 20)
    }
}

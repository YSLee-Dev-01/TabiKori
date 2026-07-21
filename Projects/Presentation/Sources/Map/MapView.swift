//
//  MapView.swift
//  Presentation
//
//  Created by 이윤수 on 7/21/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Resource

public struct MapView: View {

    @Bindable private var store: StoreOf<MapFeature>

    public init(store: StoreOf<MapFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack(alignment: .top) {
            if self.store.hasResolvedInitialCenter {
                TabiMapView(
                    centerLatitude: self.store.centerLatitude,
                    centerLongitude: self.store.centerLongitude,
                    showsLocationButton: self.store.showsUserLocation,
                    followsUserLocation: false,
                    onMapTapped: { _, _ in },
                    onMarkerTapped: { _ in }
                )
                .ignoresSafeArea()
            } else {
                Rectangle()
                    .fill(TabiColor.tabiBackground)
                    .ignoresSafeArea()
                ProgressView()
            }

            TabiLabel(title: Strings.Tabbar.map, style: .titleL, color: .tabiTextPrimary)
                .padding(.horizontal, 20)
        }
        .onAppear {
            self.store.send(.onAppear)
        }
    }
}

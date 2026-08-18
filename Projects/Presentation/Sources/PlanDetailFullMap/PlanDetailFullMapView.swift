//
//  PlanDetailFullMapView.swift
//  Presentation
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

/// PlanDetail 지도 섹션 "전체화면 보기"로 push되는 화면. 상단 전체화면 지도 + 하단 가로 스크롤 카드로 구성된다
struct PlanDetailFullMapView: View {
    @Bindable private var store: StoreOf<PlanDetailFullMapFeature>

    @Environment(\.dismiss) private var dismiss

    init(store: StoreOf<PlanDetailFullMapFeature>) {
        self.store = store
    }

    var body: some View {
        VStack(spacing: 0) {
            self.mapSection()
            self.cardScroll()
        }
        .navigationTitle("\(self.store.dayTitle) · \(self.store.dateTitle)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .tint(Color.getTabiColor(.tabiPrimary))
            }
        }
        .navigationBarBackButtonHidden(true)
        .interactivePopGestureEnabled(true)
    }
}

// MARK: - View

private extension PlanDetailFullMapView {
    var markers: [TabiMapMarker] {
        self.store.spots.enumerated().compactMap { index, spot in
            guard let marker = spot.toMapMarker(index: index + 1) else { return nil }
            return TabiMapMarker(
                id: marker.id,
                latitude: marker.latitude,
                longitude: marker.longitude,
                title: marker.title,
                icon: marker.icon,
                color: marker.color,
                index: marker.index,
                isHighlighted: spot.id == self.store.selectedSpotId
            )
        }
    }

    var focusedSpot: TravelPlanDetailSpot? {
        self.store.spots.first { $0.id == self.store.selectedSpotId }
    }

    func mapSection() -> some View {
        TabiMapView(
            centerLatitude: self.markers.first?.latitude ?? Coordinate.seoulCityHall.latitude,
            centerLongitude: self.markers.first?.longitude ?? Coordinate.seoulCityHall.longitude,
            markers: self.markers,
            isClusteringEnabled: false,
            showsPolyline: true,
            showsLocationButton: false,
            followsUserLocation: false,
            focusLatitude: self.focusedSpot?.coordinate.latitude,
            focusLongitude: self.focusedSpot?.coordinate.longitude,
            focusToken: self.store.focusToken,
            onMapTapped: { _, _ in },
            onMarkerTapped: { markerID in
                guard let spotId = UUID(uuidString: markerID) else { return }
                self.store.send(.cardTapped(spotId))
            }
        )
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    func cardScroll() -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(self.store.spots) { spot in
                    PlanDetailFullMapSpotCard(
                        spot: spot,
                        isSelected: spot.id == self.store.selectedSpotId
                    ) {
                        self.store.send(.cardTapped(spot.id))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    NavigationStack {
        PlanDetailFullMapView(
            store: Store(
                initialState: PlanDetailFullMapFeature.State(
                    dayTitle: "1日目",
                    dateTitle: Date().planDayHeaderTitle,
                    spots: TravelPlanDetail.mock.spots.filter { $0.dayIndex == 0 }
                ),
                reducer: { PlanDetailFullMapFeature() }
            )
        )
    }
}

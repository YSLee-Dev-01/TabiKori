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

/// PlanDetail 지도 섹션 "전체화면 보기"로 push되는 화면. 지도를 화면(하단 safe area 포함) 전체에 채우고,
/// 하단에 스팟 카드 캐러셀을 가로 스와이프로 겹쳐 보여준다(Apple/Kakao 지도 스타일)
struct PlanDetailFullMapView: View {

    @Bindable private var store: StoreOf<PlanDetailFullMapFeature>

    @Environment(\.dismiss) private var dismiss

    /// 카드 캐러셀의 스크롤 스냅 정착 위치. 뷰포트에 정착한 스팟을 추적해 지도 포커스와 동기화한다
    @State private var scrolledSpotID: UUID?

    init(store: StoreOf<PlanDetailFullMapFeature>) {
        self.store = store
    }

    var body: some View {
        self.mapSection()
            .ignoresSafeArea(edges: .all)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                self.spotCarousel()
                    .padding(.bottom, 12)
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
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .interactivePopGestureEnabled(true)
            .onAppear {
                self.scrolledSpotID = self.store.selectedSpotId
            }
            .onChange(of: self.store.selectedSpotId) { _, newValue in
                guard self.scrolledSpotID != newValue else { return }
                self.scrolledSpotID = newValue
            }
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

    var currentSpotIndex: Int {
        self.store.spots.firstIndex { $0.id == self.store.selectedSpotId } ?? 0
    }

    func mapSection() -> some View {
        TabiMapView(
            centerLatitude: self.markers.first?.latitude ?? Coordinate.seoulCityHall.latitude,
            centerLongitude: self.markers.first?.longitude ?? Coordinate.seoulCityHall.longitude,
            markers: self.markers,
            isClusteringEnabled: false,
            showsPolyline: true,
            showsLocationButton: false,
            showsZoomControls: false,
            followsUserLocation: false,
            focusLatitude: self.focusedSpot?.coordinate.latitude,
            focusLongitude: self.focusedSpot?.coordinate.longitude,
            focusToken: self.store.focusToken,
            onMapTapped: { _, _ in },
            onMarkerTapped: { markerID in
                guard let spotId = UUID(uuidString: markerID) else { return }
                self.store.send(.spotSelected(spotId))
            }
        )
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    func spotCarousel() -> some View {
        VStack(spacing: 8) {
            TabiPageIndicator(count: self.store.spots.count, currentIndex: self.currentSpotIndex)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(self.store.spots) { spot in
                        PlanDetailFullMapSpotCard(
                            spot: spot,
                            isSelected: spot.id == self.store.selectedSpotId
                        ) {
                            self.store.send(.spotSelected(spot.id))
                        }
                        .id(spot.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .scrollPosition(id: self.$scrolledSpotID, anchor: .leading)
            .scrollTargetBehavior(.viewAligned)
            .onChange(of: self.scrolledSpotID) { _, newValue in
                guard let newValue, newValue != self.store.selectedSpotId else { return }
                self.store.send(.spotSelected(newValue))
            }
        }
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

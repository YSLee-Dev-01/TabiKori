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
    /// 캐러셀 ScrollView의 실제 가시 영역 폭. 마지막 카드가 leading anchor까지 스크롤될 수 있도록
    /// 필요한 trailing 여백을 계산하는 데 사용한다
    @State private var carouselViewportWidth: CGFloat = 0

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
                // 마지막 카드가 leading anchor까지 스크롤/스냅될 수 있으려면, 마지막 카드 뒤에 최소
                // "뷰포트 폭 - 카드 폭"만큼의 실제 레이아웃 공간이 있어야 한다. contentMargins(.trailing:)는
                // scrollTargetLayout의 스냅 대상 목록 계산에 반영되지 않아(뷰포트보다 좁을 때 마지막 카드가
                // leading anchor에 정착하지 못하고 이전 카드로 되튕겨 탭이 스크롤 제스처에 먹히는 문제가
                // 그대로 남았음), 실제 레이아웃 크기에 반영되는 padding으로 직접 여백을 준다
                .padding(.trailing, max(20, self.carouselViewportWidth - PlanDetailFullMapSpotCard.width))
            }
            .background(
                // onScrollGeometryChange는 실제 기기/시뮬레이터에서 갱신이 지연되거나 발생하지 않아
                // carouselViewportWidth가 0으로 남는 문제가 있었다(트레일링 패딩이 폴백값 20에 고정되어
                // 마지막 카드가 leading anchor까지 스크롤되지 못함). GeometryReader는 이 뷰(ScrollView)의
                // 실제 레이아웃 폭을 레이아웃 패스와 동기적으로 제공하므로 이 값을 대신 사용한다
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { self.carouselViewportWidth = proxy.size.width }
                        .onChange(of: proxy.size.width) { _, newValue in
                            self.carouselViewportWidth = newValue
                        }
                }
            )
            .scrollIndicators(.hidden)
            .scrollPosition(id: self.$scrolledSpotID, anchor: .leading)
            .scrollTargetBehavior(.viewAligned)
            // 첫 카드는 HStack 앞에 있던 leading padding 덕에 화면 왼쪽 가장자리에서 20pt 떨어져
            // 보였지만, anchor: .leading으로 다른 카드에 스냅될 때는 그 카드의 프레임 자체가 뷰포트
            // 왼쪽 끝(x=0)에 딱 붙어 카드 테두리·그림자가 화면 가장자리에서 잘려 보였다(마지막 카드로
            // 스크롤했을 때 특히 두드러짐). contentMargins(.leading:)는 이 환경에서 viewAligned의 앵커
            // 정렬 계산에 반영되지 않아(트레일링에서와 동일하게 확인됨) 효과가 없었고, safeAreaPadding은
            // 스크롤 콘텐츠의 세이프에어리어로 취급되어 앵커 정렬에 반영되므로 이걸 대신 사용한다
            .safeAreaPadding(.leading, 20)
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

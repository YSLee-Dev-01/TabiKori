//
//  MapView.swift
//  Presentation
//
//  Created by 이윤수 on 7/21/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import UIKit

import ComposableArchitecture
import Core
import DesignSystem
import Domain
import Resource

public struct MapView: View {

    @Bindable private var store: StoreOf<MapFeature>
    @FocusState private var isSearchFieldFocused: Bool
    @Namespace private var searchFieldNamespace
    @State private var mapContainerHeight: CGFloat = 0
    @State private var topBarHeight: CGFloat = 0
    @State private var keyboardHeight: CGFloat = 0
    @State private var lastTappedSpotID: String?

    fileprivate var baseFullHeight: CGFloat { max(0, self.mapContainerHeight - self.topBarHeight) }
    fileprivate var baseHalfHeight: CGFloat { min(self.baseFullHeight, self.mapContainerHeight * 0.42) }
    fileprivate var baseCollapsedHeight: CGFloat { min(self.baseHalfHeight, 140) }

    public init(store: StoreOf<MapFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack(alignment: .top) {
            self.mapBackground()
                .safeAreaBar(edge: .top) {
                    self.topBar()
                }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newValue in
            self.mapContainerHeight = newValue
        }
        .overlay(alignment: .bottom) {
            if self.store.mode == .typing || self.store.mode == .result {
                self.searchPanel()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.tabiStandard, value: self.store.searchQuery.isEmpty)
        .animation(.tabiStandard, value: self.store.mode)
        .animation(.tabiStandard, value: self.store.showsResearchButton)
        .onChange(of: self.store.mode) { _, mode in
            self.isSearchFieldFocused = mode == .typing
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self.keyboardHeight = max(0, UIScreen.main.bounds.height - frame.origin.y)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            self.keyboardHeight = 0
        }
        .onAppear {
            self.store.send(.onAppear)
        }
    }
}

// MARK: - TouristSpot View Extension

private extension TouristSpot {
    var toMapMarker: TabiMapMarker? {
        guard self.coordinate.isValid else { return nil }
        return TabiMapMarker(
            id: self.id,
            latitude: self.coordinate.latitude,
            longitude: self.coordinate.longitude,
            title: self.title.removingHangul,
            icon: self.contentType.icon,
            color: self.contentType.color
        )
    }
}

// MARK: - MapSearchLoadingDots

private struct MapSearchLoadingDots: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 3, id: \.self) { index in
                Circle()
                    .fill(TabiColor.tabiPrimary)
                    .frame(width: 5, height: 5)
                    .opacity(self.isAnimating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: self.isAnimating
                    )
            }
        }
        .onAppear {
            self.isAnimating = true
        }
    }
}

// MARK: - View

private extension MapView {
    func mapBackground() -> some View {
        Group {
            if self.store.hasResolvedInitialCenter {
                TabiMapView(
                    centerLatitude: self.store.centerLatitude,
                    centerLongitude: self.store.centerLongitude,
                    markers: self.store.searchResults.compactMap(\.toMapMarker),
                    isClusteringEnabled: false,
                    showsLocationButton: self.store.showsUserLocation,
                    followsUserLocation: false,
                    boundsFitToken: self.store.searchResultFitToken,
                    onMapTapped: { _, _ in },
                    onMarkerTapped: { id in
                        guard let spot = self.store.searchResults.first(where: { $0.id == id }) else { return }
                        self.selectSearchResult(spot)
                    },
                    onMapDragged: { self.store.send(.mapDragged) },
                    onCameraIdle: { latitude, longitude, radiusMeters in
                        self.store.send(.mapCenterChanged(Coordinate(latitude: latitude, longitude: longitude), radiusMeters: radiusMeters))
                    }
                )
                .ignoresSafeArea()
            } else {
                Rectangle()
                    .fill(TabiColor.tabiBackground)
                    .ignoresSafeArea()
                ProgressView()
            }
        }
    }

    func recentSearchContent() -> some View {
        Group {
            if self.store.recentSearches.isEmpty {
                MapRecentSearchPlaceholderView(keyboardHeight: self.keyboardHeight)
            } else {
                MapRecentSearchListView(
                    histories: self.store.recentSearches,
                    onTapped: { history in
                        self.store.send(.recentSearchTapped(history))
                    },
                    onDeleteTapped: { history in
                        self.store.send(.recentSearchDeleteTapped(history))
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func searchPanel() -> some View {
        MapSearchPanelView(
            stage: self.store.panelStage,
            collapsedHeight: self.baseCollapsedHeight,
            halfHeight: self.baseHalfHeight,
            fullHeight: self.baseFullHeight,
            onStageChanged: { stage in self.store.send(.panelDragEnded(stage)) },
            onDismiss: { self.cancelSearch() }
        ) {
            if self.store.mode == .typing {
                self.recentSearchContent()
            } else {
                self.searchResultContent()
            }
        }
    }

    @ViewBuilder
    func searchResultContent() -> some View {
        if self.store.searchQuery.isEmpty && self.store.isCategorySearchActive == false {
            self.searchGuideState()
        } else if self.store.isSearchLoading {
            self.searchResultSkeletonList()
        } else if self.store.searchResults.isEmpty {
            self.searchResultEmptyState()
        } else {
            self.searchResultList()
        }
    }

    func searchGuideState() -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 34))
                    .foregroundStyle(TabiColor.tabiTextTertiary)
                TabiLabel(
                    title: Strings.Map.searchEmptyDescription,
                    style: .bodyS,
                    color: .tabiTextTertiary,
                    alignment: .center
                )
            }

            Spacer(minLength: 0)
        }
    }

    func searchResultEmptyState() -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Image(systemName: "mappin.slash")
                    .font(.system(size: 34))
                    .foregroundStyle(TabiColor.tabiTextTertiary)

                VStack(spacing: 3) {
                    TabiLabel(title: Strings.Map.searchResultEmptyTitle, style: .bodySBold, color: .tabiTextSecondary)
                    TabiLabel(
                        title: Strings.Map.searchResultEmptyDescription,
                        style: .captionM,
                        color: .tabiTextTertiary,
                        alignment: .center
                    )
                }
            }

            Spacer(minLength: 0)
        }
    }

    func searchResultSkeletonList() -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0 ..< 6, id: \.self) { index in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    self.searchResultSkeletonRow()
                }
            }
        }
        .scrollDisabled(true)
        .allowsHitTesting(false)
    }

    func searchResultSkeletonRow() -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: .tabiRadiusMd)
                .fill(TabiColor.tabiBorder.opacity(0.3))
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(TabiColor.tabiBorder.opacity(0.3))
                    .frame(width: 120, height: 16)
                Capsule()
                    .fill(TabiColor.tabiBorder.opacity(0.3))
                    .frame(width: 55, height: 20)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(TabiColor.tabiBorder.opacity(0.2))
                .frame(width: 40, height: 14)
        }
        .padding(16)
    }

    func searchResultList() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(self.store.searchResults.enumerated()), id: \.element.id) { index, spot in
                        if index > 0 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                        MapSearchResultRowView(spot: spot) {
                            self.selectSearchResult(spot)
                        }
                        .id(spot.id)
                        .onAppear {
                            guard spot.id == self.store.searchResults.last?.id else { return }
                            self.store.send(.searchNextPageTriggered)
                        }
                    }

                    if self.store.isSearchNextPageLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                }
            }
            .onAppear {
                guard let id = self.lastTappedSpotID else { return }
                // sheet가 재생성되는 시점에 동기 scrollTo를 호출하면 "state changes lost" 레이스 컨디션이 발생해 한 틱 지연
                DispatchQueue.main.async {
                    proxy.scrollTo(id, anchor: .top)
                }
            }
        }
    }

    func topBar() -> some View {
        VStack(spacing: 12) {
            TabiNavigationBar(
                title: Strings.Tabbar.map
            )

            HStack(spacing: 12) {
                switch self.store.mode {
                case .map:
                    TabiSearchField(
                        placeholder: Strings.Map.searchPlaceholder,
                        style: .glass
                    ) {
                        self.store.send(.searchFieldTapped)
                    }
                    .matchedGeometryEffect(id: "mapSearchField", in: self.searchFieldNamespace)

                case .typing:
                    TabiSearchField(
                        placeholder: Strings.Map.searchPlaceholder,
                        text: self.$store.searchQuery,
                        focus: self.$isSearchFieldFocused,
                        style: .glass,
                        onSubmit: {
                            self.lastTappedSpotID = nil
                            self.store.send(.searchSubmitted)
                        }
                    )
                    .matchedGeometryEffect(id: "mapSearchField", in: self.searchFieldNamespace)

                    self.searchCancelButton()

                case .result:
                    TabiSearchField(
                        placeholder: self.store.activeCategoryLabel ?? (self.store.searchQuery.isEmpty ? Strings.Map.searchPlaceholder : self.store.searchQuery),
                        style: .glass
                    ) {
                        self.store.send(.searchFieldTapped)
                    }
                    .matchedGeometryEffect(id: "mapSearchField", in: self.searchFieldNamespace)

                    self.searchCancelButton()
                }
            }
            .padding(.horizontal, 20)

            if self.store.mode == .map {
                self.categoryChips()
            }

            if self.store.mode == .result && self.store.isSearchLoading {
                self.searchLoadingIndicator()
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else if self.store.showsResearchButton {
                self.researchButton()
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.bottom, 16)
        .background {
            LinearGradient(
                colors: [
                    Color.getTabiColor(.tabiBackground),
                    Color.getTabiColor(.tabiBackground).opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.container, edges: .top)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newValue in
            self.topBarHeight = newValue
        }
    }

    func researchButton() -> some View {
        HStack {
            Spacer()
            TabiButton(
                Strings.Map.researchAtCurrentLocation,
                style: .glass(on: .surface)
            ) {
                self.store.send(.researchAtCurrentLocationTapped)
            }
            Spacer()
        }
    }

    func searchLoadingIndicator() -> some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                TabiLabel(title: Strings.Map.loading, style: .bodyMBold, color: .tabiPrimary)
                MapSearchLoadingDots()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .glassEffect(.regular, in: .rect(cornerRadius: .tabiRadiusSm))
            Spacer()
        }
    }

    func searchCancelButton() -> some View {
        Button {
            self.cancelSearch()
        } label: {
            TabiLabel(title: Strings.Map.searchCancel, style: .bodyM, color: .tabiTextSecondary)
        }
    }

    func categoryChips() -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(CategoryType.allItems, id: \.self) { item in
                    self.categoryChip(item)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    func categoryChip(_ item: CategoryType) -> some View {
        Button {
            self.store.send(.categorySelected(item, coordinate: nil))
        } label: {
            HStack(spacing: 6) {
                Image(item.icon)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(item.color)

                TabiLabel(title: item.label, style: .captionMBold, color: item.color)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(TabiColor.tabiSurface)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(TabiColor.tabiBorder, lineWidth: 1)
            }
        }
        .buttonStyle(TabiPressStyle())
    }

    func selectSearchResult(_ spot: TouristSpot) {
        self.lastTappedSpotID = spot.id
        self.store.send(.searchResultTapped(spot))
    }
}

// MARK: - Method

private extension MapView {
    func cancelSearch() {
        self.lastTappedSpotID = nil
        self.store.send(.searchCancelTapped)
    }
}

//
//  AddCustomPlaceView.swift
//  Presentation
//
//  Created by 이윤수 on 8/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import Core
import DesignSystem
import Domain
import Resource

public struct AddCustomPlaceView: View {

    @Bindable private var store: StoreOf<AddCustomPlaceFeature>

    @State private var selectedDetent: PresentationDetent = .medium
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isAddressFocused: Bool
    @FocusState private var isSearchFieldFocused: Bool

    public init(store: StoreOf<AddCustomPlaceFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                self.tabBar()

                if self.store.selectedTab == .custom {
                    self.categorySection()
                    self.titleField()
                    self.bottomSection()
                } else {
                    self.searchTabContent()
                }
            }
            .padding(20)
            .animation(.tabiStandard, value: self.store.isSubwayMode)
            .animation(.tabiStandard, value: self.store.subwayResults)
            .animation(.tabiStandard, value: self.store.matchedStation)
            .animation(.tabiStandard, value: self.store.selectedTab)
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaBar(edge: .top) {
            TabiNavigationBar(title: Strings.AddCustomPlace.screenTitle) {
                self.closeButton()
            }
            .padding(.top, 20)
        }
        .safeAreaBar(edge: .bottom) {
            if self.store.selectedTab == .custom {
                AddCustomPlaceBottomCTAView(isEnabled: self.store.isConfirmEnabled, isLoading: self.store.isSaving) {
                    self.store.send(.confirmTapped)
                }
            }
        }
        .disabled(self.store.selectedTab == .search && self.store.isSaving)
        .overlay {
            if self.store.selectedTab == .search, self.store.isSaving {
                ProgressView()
            }
        }
        .presentationDetents([.medium, .large], selection: self.$selectedDetent)
        .presentationDragIndicator(.visible)
        .alert($store.scope(state: \.alert, action: \.alert))
        .onChange(of: self.isTitleFocused) { _, isFocused in
            guard isFocused else { return }
            self.selectedDetent = .large
        }
        .onChange(of: self.isAddressFocused) { _, isFocused in
            guard isFocused else { return }
            self.selectedDetent = .large
        }
        .onChange(of: self.isSearchFieldFocused) { _, isFocused in
            guard isFocused else { return }
            self.selectedDetent = .large
        }
    }
}

// MARK: - View

private extension AddCustomPlaceView {
    func closeButton() -> some View {
        TabiCircleIconButton(systemName: "xmark") {
            self.store.send(.closeTapped)
        }
    }

    func tabBar() -> some View {
        AddCustomPlaceTabBar(selectedTab: self.store.selectedTab) { tab in
            self.store.send(.tabSelected(tab))
        }
    }

    func categorySection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.Common.categoryTitle, style: .bodyMBold, color: .tabiTextPrimary)
            BookmarkCategoryFilterBar(
                selectedCategory: self.store.isSubwayMode ? .subway : self.store.selectedCategory,
                includesAllChip: false,
                includesSubwayChip: true
            ) { category in
                guard let category else { return }
                self.store.send(.categorySelected(category))
            }
        }
    }

    func titleField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(
                title: self.store.isSubwayMode ? Strings.AddCustomPlace.stationTitleLabel : Strings.AddCustomPlace.titleLabel,
                style: .bodyMBold,
                color: .tabiTextPrimary
            )
            TabiTextField(
                placeholder: self.store.isSubwayMode ? Strings.AddCustomPlace.stationTitlePlaceholder : Strings.AddCustomPlace.titlePlaceholder,
                text: self.$store.title,
                focus: self.$isTitleFocused
            )
            .onSubmit {
                guard self.store.isSubwayMode else { return }
                self.store.send(.stationNameSubmitted)
            }
            if self.store.isSubwayMode {
                TabiLabel(
                    title: self.store.trimmedTitle.isEmpty ? Strings.Common.subwayKatakanaGuide : Strings.Common.subwaySearchEnterGuide,
                    style: .captionM,
                    color: .tabiTextSecondary
                )
            }
            if self.store.isSubwayMode, self.store.isSubwaySearching {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    func bottomSection() -> some View {
        if self.store.isSubwayMode {
            if self.store.matchedStation != nil {
                self.mapPreviewSection()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                self.subwayResultsSection()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        } else {
            self.addressField()
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    func addressField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.AddCustomPlace.addressLabel, style: .bodyMBold, color: .tabiTextPrimary)
            TabiTextField(
                placeholder: Strings.AddCustomPlace.addressPlaceholder,
                text: self.$store.address,
                focus: self.$isAddressFocused
            )
            .onSubmit {
                self.store.send(.addressSubmitted)
            }
            TabiLabel(
                title: Strings.AddCustomPlace.addressKoreanSearchGuide,
                style: .captionM,
                color: .tabiTextSecondary
            )
            self.mapPreviewSection()
        }
    }

    @ViewBuilder
    func subwayResultsSection() -> some View {
        if self.store.subwayResults.isEmpty == false {
            VStack(spacing: 0) {
                ForEach(Array(self.store.subwayResults.enumerated()), id: \.element.stationCode) { index, station in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    TabiSpotRow(
                        thumbnailURL: nil,
                        japaneseTitle: station.displayJapaneseName,
                        koreanTitle: station.koreanName,
                        address: station.lineNumbers.joined(separator: "・"),
                        tagTitle: CategoryType.subway.label,
                        tagColor: CategoryType.subway.color,
                        isCustom: false,
                        distance: nil,
                        onTap: { self.store.send(.subwayStationTapped(station)) }
                    )
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: .tabiRadiusLg)
                    .stroke(TabiColor.tabiBorder.opacity(0.4), lineWidth: 1)
            }
        }
    }

    func mapPreviewSection() -> some View {
        let coordinate = self.store.previewCoordinate ?? .seoulCityHall
        let category = self.store.isSubwayMode ? CategoryType.subway : (self.store.selectedCategory ?? .sightseeing)
        let markerTitle = self.store.isSubwayMode
            ? (self.store.matchedStation?.japaneseTitle ?? self.store.trimmedTitle.removingHangul)
            : self.store.trimmedTitle.removingHangul
        let markers: [TabiMapMarker] = self.store.previewCoordinate == nil ? [] : [
            TabiMapMarker(
                id: "preview",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                title: markerTitle,
                icon: category.icon,
                color: category.color
            )
        ]

        return TabiMapView(
            centerLatitude: coordinate.latitude,
            centerLongitude: coordinate.longitude,
            markers: markers,
            boundsFitToken: self.store.previewFitToken,
            onMapTapped: { _, _ in },
            onMarkerTapped: { _ in }
        )
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusLg))
        .overlay {
            RoundedRectangle(cornerRadius: .tabiRadiusLg)
                .stroke(TabiColor.tabiBorder.opacity(0.4), lineWidth: 1)
        }
    }
}

// MARK: - Search Tab

private extension AddCustomPlaceView {
    func searchTabContent() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            self.searchField()
            self.searchResultsSection()
        }
    }

    func searchField() -> some View {
        TabiTextField(
            placeholder: Strings.Map.searchPlaceholder,
            text: self.$store.searchQuery,
            focus: self.$isSearchFieldFocused
        )
        .onSubmit {
            self.store.send(.searchSubmitted)
        }
    }

    @ViewBuilder
    func searchResultsSection() -> some View {
        if self.store.trimmedSearchQuery.isEmpty {
            TabiEmptyState(
                systemImageName: "magnifyingglass",
                description: Strings.Map.searchEmptyDescription
            )
            .frame(maxWidth: .infinity)
        } else if self.store.isSearchLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else if self.store.searchStationResults.isEmpty, self.store.searchResults.isEmpty {
            TabiEmptyState(
                systemImageName: "mappin.slash",
                title: Strings.Map.searchResultEmptyTitle,
                description: Strings.Map.searchResultEmptyDescription
            )
            .frame(maxWidth: .infinity)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(self.store.searchStationResults.enumerated()), id: \.element.stationCode) { index, station in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    MapSubwayStationRowView(station: station) {
                        self.store.send(.searchStationTapped(station))
                    }
                }

                if self.store.searchStationResults.isEmpty == false, self.store.searchResults.isEmpty == false {
                    Divider()
                        .padding(.horizontal, 16)
                }

                ForEach(Array(self.store.searchResults.enumerated()), id: \.element.id) { index, spot in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    MapSearchResultRowView(spot: spot) {
                        self.store.send(.searchSpotTapped(spot))
                    }
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
            .overlay {
                RoundedRectangle(cornerRadius: .tabiRadiusLg)
                    .stroke(TabiColor.tabiBorder.opacity(0.4), lineWidth: 1)
            }
        }
    }
}

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

    public init(store: StoreOf<AddCustomPlaceFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                self.categorySection()
                self.titleField()
                self.bottomSection()
            }
            .padding(20)
            .animation(.tabiStandard, value: self.store.isSubwayMode)
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaBar(edge: .top) {
            TabiNavigationBar(title: Strings.AddCustomPlace.screenTitle) {
                self.closeButton()
            }
            .padding(.top, 20)
        }
        .safeAreaBar(edge: .bottom) {
            AddCustomPlaceBottomCTAView(isEnabled: self.store.isConfirmEnabled, isLoading: self.store.isSaving) {
                self.store.send(.confirmTapped)
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
    }
}

// MARK: - View

private extension AddCustomPlaceView {
    func closeButton() -> some View {
        TabiCircleIconButton(systemName: "xmark") {
            self.store.send(.closeTapped)
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
                TabiLabel(title: Strings.Common.subwayKatakanaGuide, style: .captionM, color: .tabiTextSecondary)
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
                        japaneseTitle: station.japaneseName,
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

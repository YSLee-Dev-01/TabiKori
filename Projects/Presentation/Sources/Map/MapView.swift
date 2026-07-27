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
import DesignSystem
import Domain
import Kingfisher
import Resource

public struct MapView: View {

    @Bindable private var store: StoreOf<MapFeature>
    @FocusState private var isSearchFieldFocused: Bool
    @Namespace private var searchFieldNamespace
    @State private var mapContainerHeight: CGFloat = 0
    @State private var topBarHeight: CGFloat = 0
    @State private var keyboardHeight: CGFloat = 0

    fileprivate var baseFullHeight: CGFloat { max(0, self.mapContainerHeight - self.topBarHeight) }
    fileprivate var baseHalfHeight: CGFloat { min(self.baseFullHeight, self.mapContainerHeight * 0.42) }
    fileprivate var baseCollapsedHeight: CGFloat { min(self.baseHalfHeight, 140) }

    fileprivate var panelStageBinding: Binding<PresentationDetent> {
        Binding(
            get: {
                switch self.store.panelStage {
                case .collapsed: return .height(self.baseCollapsedHeight)
                case .half: return .height(self.baseHalfHeight)
                case .full: return .height(self.baseFullHeight)
                }
            },
            set: { newValue in
                let stage: MapPanelStage
                if newValue == .height(self.baseCollapsedHeight) {
                    stage = .collapsed
                } else if newValue == .height(self.baseHalfHeight) {
                    stage = .half
                } else {
                    stage = .full
                }
                self.store.send(.panelDragEnded(stage))
            }
        )
    }

    fileprivate var isResultSheetPresented: Binding<Bool> {
        Binding(
            get: { self.store.mode == .result },
            set: { newValue in
                guard newValue == false else { return }
                self.store.send(.searchCancelTapped)
            }
        )
    }

    public init(store: StoreOf<MapFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack(alignment: .top) {
            self.mapBackground()
            self.topBar()

            if self.store.mode == .typing {
                self.recentSearchPlaceholder()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newValue in
            self.mapContainerHeight = newValue
        }
        .animation(.tabiStandard, value: self.store.searchQuery.isEmpty)
        .onChange(of: self.store.mode) { _, mode in
            self.isSearchFieldFocused = mode == .typing
        }
        .onAppear {
            self.store.send(.onAppear)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self.keyboardHeight = max(0, UIScreen.main.bounds.height - frame.origin.y)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            self.keyboardHeight = 0
        }
        .sheet(isPresented: self.isResultSheetPresented) {
            self.searchResultSheet()
        }
    }
}

// MARK: - TouristSpot View Extension

private extension TouristSpot {
    var formattedDistance: String? {
        guard let dist = self.distanceMeters else { return nil }
        if dist >= 1000 { return String(format: "%.1fkm", dist / 1000) }
        return "\(Int(dist))m"
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
                    showsLocationButton: self.store.showsUserLocation,
                    followsUserLocation: false,
                    onMapTapped: { _, _ in },
                    onMarkerTapped: { _ in },
                    onMapDragged: { self.store.send(.mapDragged) }
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

    func recentSearchPlaceholder() -> some View {
        MapRecentSearchPlaceholderView(keyboardHeight: self.keyboardHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(TabiColor.tabiBackground)
            .padding(.top, self.topBarHeight)
            .ignoresSafeArea(.container, edges: .bottom)
    }

    func searchResultSheet() -> some View {
        VStack(spacing: 0) {
            self.searchResultContent()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .presentationDetents(
            [
                .height(self.baseCollapsedHeight),
                .height(self.baseHalfHeight),
                .height(self.baseFullHeight)
            ],
            selection: self.panelStageBinding
        )
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled(upThrough: .height(self.baseHalfHeight)))
        .presentationCornerRadius(.tabiRadiusXl)
        .interactiveDismissDisabled()
    }

    @ViewBuilder
    func searchResultContent() -> some View {
        if self.store.searchQuery.isEmpty {
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
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(self.store.searchResults.enumerated()), id: \.element.id) { index, spot in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    self.searchResultRow(spot)
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
    }

    func searchResultRow(_ spot: TouristSpot) -> some View {
        Button {
            self.store.send(.searchResultTapped(spot))
        } label: {
            HStack(spacing: 12) {
                KFImage(spot.thumbnailURL)
                    .placeholder {
                        Color.getTabiColor(.tabiBorder).opacity(0.25)
                            .overlay {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 16))
                                    .foregroundStyle(TabiColor.tabiTextTertiary)
                            }
                    }
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))

                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        TabiLabel(title: spot.japaneseTitle, style: .bodyMBold, color: .tabiTextPrimary, lineLimit: 1)

                        if let korean = spot.koreanTitle {
                            TabiLabel(title: korean, style: .captionM, color: .tabiTextSecondary, lineLimit: 1)
                        }
                    }

                    TabiTag(spot.contentType.label, color: spot.contentType.color)
                }

                Spacer()

                if let distance = spot.formattedDistance {
                    self.distanceLabel(distance)
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabiPressStyle())
    }

    func distanceLabel(_ distance: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "location.fill")
                .font(.system(size: 10))
                .foregroundStyle(TabiColor.tabiTextTertiary)
            TabiLabel(title: distance, style: .captionM, color: .tabiTextTertiary)
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
                        onSubmit: { self.store.send(.searchSubmitted) }
                    )
                    .matchedGeometryEffect(id: "mapSearchField", in: self.searchFieldNamespace)

                    self.searchCancelButton()

                case .result:
                    TabiSearchField(
                        placeholder: self.store.searchQuery.isEmpty ? Strings.Map.searchPlaceholder : self.store.searchQuery,
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
        }
        .padding(.bottom, 16)
        .safeAreaPadding(.top)
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

    func searchCancelButton() -> some View {
        Button {
            self.store.send(.searchCancelTapped)
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
}

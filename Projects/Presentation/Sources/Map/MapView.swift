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
    @FocusState private var isSearchFieldFocused: Bool

    public init(store: StoreOf<MapFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            self.mapContent()

            if self.store.isSearching {
                self.searchModeOverlay()
                    .transition(.opacity)
            }
        }
        .animation(.tabiStandard, value: self.store.isSearching)
        .onChange(of: self.store.isSearching) { _, isSearching in
            self.isSearchFieldFocused = isSearching
        }
        .onAppear {
            self.store.send(.onAppear)
        }
    }
}

// MARK: - View

private extension MapView {
    func mapContent() -> some View {
        Group {
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
        }
        .safeAreaBar(edge: .top) {
            VStack(spacing: 12) {
                TabiNavigationBar(
                    subtitle: Strings.Map.navigationSubtitle,
                    title: Strings.Tabbar.map
                )

                TabiSearchField(placeholder: Strings.Map.searchPlaceholder) {
                    self.store.send(.searchFieldTapped)
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 4)
            .background(.bar)
        }
    }

    func searchModeOverlay() -> some View {
        ZStack {
            Rectangle()
                .fill(TabiColor.tabiBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    TabiSearchField(
                        placeholder: Strings.Map.searchPlaceholder,
                        text: self.$store.searchQuery,
                        focus: self.$isSearchFieldFocused
                    )

                    Button {
                        self.store.send(.searchCancelTapped)
                    } label: {
                        TabiLabel(title: Strings.Map.searchCancel, style: .bodyM, color: .tabiTextSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                Spacer()

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

                Spacer()
            }
        }
    }
}

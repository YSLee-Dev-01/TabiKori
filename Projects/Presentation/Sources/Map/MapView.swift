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
import Domain
import Resource

public struct MapView: View {

    @Bindable private var store: StoreOf<MapFeature>
    @FocusState private var isSearchFieldFocused: Bool
    @Namespace private var searchFieldNamespace
    @State private var mapContainerHeight: CGFloat = 0
    @State private var topBarHeight: CGFloat = 0
    @GestureState private var panelDragTranslation: CGFloat = 0
    
    fileprivate var collapsedPanelHeight: CGFloat { 50 }
    fileprivate var halfPanelHeight: CGFloat { self.mapContainerHeight * 0.42 }
    fileprivate var fullPanelHeight: CGFloat { max(0, self.mapContainerHeight - self.topBarHeight) }
    
    fileprivate var panelHeight: CGFloat {
        let base = self.panelHeight(for: self.store.panelStage)
        return min(self.fullPanelHeight, max(self.collapsedPanelHeight, base - self.panelDragTranslation))
    }

    public init(store: StoreOf<MapFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                self.mapBackground()
                self.topBar()
            }

            if self.store.isSearching {
                self.searchResultPanel()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newValue in
            self.mapContainerHeight = newValue
        }
        .animation(.tabiStandard, value: self.store.isSearching)
        .animation(.tabiStandard, value: self.store.searchQuery.isEmpty)
        .animation(.tabiSpring, value: self.store.panelStage)
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

    func searchResultPanel() -> some View {
        VStack(spacing: 0) {
            self.panelGrabber()

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
        .frame(maxWidth: .infinity)
        .frame(height: self.panelHeight)
        .background(TabiColor.tabiSurface)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: .tabiRadiusXl,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: .tabiRadiusXl
            )
        )
        .ignoresSafeArea(.container, edges: .top)
    }

    func panelGrabber() -> some View {
        Capsule()
            .fill(TabiColor.tabiBorder)
            .frame(width: 36, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating(self.$panelDragTranslation) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let base = self.panelHeight(for: self.store.panelStage)
                        let projected = base - value.translation.height
                        self.store.send(.panelDragEnded(self.nearestStage(to: projected)))
                    }
            )
    }

    func panelHeight(for stage: MapPanelStage) -> CGFloat {
        switch stage {
        case .full: return self.fullPanelHeight
        case .half: return self.halfPanelHeight
        case .collapsed: return self.collapsedPanelHeight
        }
    }

    func nearestStage(to height: CGFloat) -> MapPanelStage {
        let candidates: [(MapPanelStage, CGFloat)] = [
            (.full, self.fullPanelHeight),
            (.half, self.halfPanelHeight),
            (.collapsed, self.collapsedPanelHeight)
        ]
        return candidates.min { abs($0.1 - height) < abs($1.1 - height) }?.0 ?? self.store.panelStage
    }

    func topBar() -> some View {
        VStack(spacing: 12) {
            TabiNavigationBar(
                title: Strings.Tabbar.map
            )

            HStack(spacing: 12) {
                if self.store.isSearching {
                    TabiSearchField(
                        placeholder: Strings.Map.searchPlaceholder,
                        text: self.$store.searchQuery,
                        focus: self.$isSearchFieldFocused,
                        onSubmit: { self.store.send(.searchSubmitted) }
                    )
                    .matchedGeometryEffect(id: "mapSearchField", in: self.searchFieldNamespace)

                    Button {
                        self.store.send(.searchCancelTapped)
                    } label: {
                        TabiLabel(title: Strings.Map.searchCancel, style: .bodyM, color: .tabiTextSecondary)
                    }
                } else {
                    TabiSearchField(
                        placeholder: Strings.Map.searchPlaceholder,
                        style: .glass
                    ) {
                        self.store.send(.searchFieldTapped)
                    }
                    .matchedGeometryEffect(id: "mapSearchField", in: self.searchFieldNamespace)
                }
            }
            .padding(.horizontal, 20)

            if !self.store.isSearching {
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
            .background(item.color.opacity(0.1))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(item.color.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(TabiPressStyle())
    }
}

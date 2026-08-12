//
//  RegionSpotView.swift
//  Presentation
//
//  Created by 이윤수 on 8/10/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

public struct RegionSpotView: View {

    @Bindable private var store: StoreOf<RegionSpotFeature>
    @Environment(\.dismiss) private var dismiss

    private static let heroTopAnchorID = "regionSpotHeroTop"

    public init(store: StoreOf<RegionSpotFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                self.content(proxy: proxy)
            }
            .coordinateSpace(name: RegionSpotHeroView.coordinateSpaceName)
            .ignoresSafeArea(edges: .top)
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
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                self.store.send(.onAppear)
            }
        }
    }
}

// MARK: - View

private extension RegionSpotView {
    func content(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            RegionSpotHeroView(image: self.store.region.image)
                .id(Self.heroTopAnchorID)

            VStack(alignment: .leading, spacing: 4) {
                TabiLabel(title: self.store.region.jaTitle, style: .titleL, color: .tabiTextPrimary)
                TabiLabel(title: self.store.region.koTitle, style: .bodyM, color: .tabiTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            self.tabBarSection(proxy: proxy)

            if self.store.selectedContentTab == .spot {
                Group {
                    TabiLabel(title: Strings.Common.categoryTitle, style: .titleS, color: .tabiTextPrimary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    RegionSpotCategoryTabBar(
                        selectedCategory: self.store.selectedCategory,
                        onSelect: { self.store.send(.categoryTabTapped($0)) }
                    )
                    .padding(.bottom, 16)
                }
                .transition(.opacity)
            }

            self.tabContentSection()
                .padding(.bottom, 20)
        }
    }

    func tabBarSection(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 8) {
            ForEach(RegionSpotContentTab.allCases, id: \.self) { tab in
                TabiChip(tab.label, isSelected: self.store.selectedContentTab == tab) {
                    self.selectTab(tab, proxy: proxy)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    func selectTab(_ tab: RegionSpotContentTab, proxy: ScrollViewProxy) {
        withAnimation(.tabiStandard) {
            proxy.scrollTo(Self.heroTopAnchorID, anchor: .top)
        } completion: {
            withAnimation(.tabiStandard) {
                _ = self.store.send(.contentTabSelected(tab))
            }
        }
    }

    @ViewBuilder
    func tabContentSection() -> some View {
        if self.store.selectedContentTab == .spot {
            RegionSpotSpotSection(
                loadState: self.store.spotLoadState,
                spots: self.store.spots,
                onRetry: { self.store.send(.retryButtonTapped) },
                onSpotTapped: { self.store.send(.spotTapped($0)) }
            )
            .transition(.opacity)
        }
        if self.store.selectedContentTab == .festival {
            RegionSpotFestivalSection(
                loadState: self.store.festivalLoadState,
                festivals: self.store.festivals,
                onRetry: { self.store.send(.retryButtonTapped) },
                onFestivalTapped: { self.store.send(.festivalTapped($0)) }
            )
            .transition(.opacity)
        }
    }
}

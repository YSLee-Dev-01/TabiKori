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

    public init(store: StoreOf<RegionSpotFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            self.content()
        }
        .navigationTitle(self.store.region.jaTitle)
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
        .onAppear {
            self.store.send(.onAppear)
        }
    }
}

// MARK: - View

private extension RegionSpotView {
    func content() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            self.regionHeaderImage()

            VStack(alignment: .leading, spacing: 4) {
                TabiLabel(title: self.store.region.jaTitle, style: .titleL, color: .tabiTextPrimary)
                TabiLabel(title: self.store.region.koTitle, style: .bodyM, color: .tabiTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            RegionSpotCategoryTabBar(
                selectedCategory: self.store.selectedCategory,
                onSelect: { self.store.send(.categoryTabTapped($0)) }
            )
            .padding(.top, 20)

            RegionSpotSpotSection(
                loadState: self.store.spotLoadState,
                spots: self.store.spots,
                onRetry: { self.store.send(.retryButtonTapped) },
                onSpotTapped: { self.store.send(.spotTapped($0)) }
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)

            RegionSpotFestivalSection(
                loadState: self.store.festivalLoadState,
                festivals: self.store.festivals,
                onRetry: { self.store.send(.retryButtonTapped) },
                onFestivalTapped: { self.store.send(.festivalTapped($0)) }
            )
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    func regionHeaderImage() -> some View {
        if let image = self.store.region.image {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()
        }
    }
}

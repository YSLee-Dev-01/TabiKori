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
        VStack(alignment: .leading, spacing: 0) {
            self.regionHeaderImage()

            VStack(alignment: .leading, spacing: 4) {
                TabiLabel(title: self.store.region.jaTitle, style: .titleL, color: .tabiTextPrimary)
                TabiLabel(title: self.store.region.koTitle, style: .bodyM, color: .tabiTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            self.comingSoonState()
                .padding(.horizontal, 20)
                .padding(.top, 20)

            Spacer()
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

    func comingSoonState() -> some View {
        TabiCard {
            VStack(alignment: .leading, spacing: 6) {
                TabiLabel(title: Strings.RegionSpot.comingSoonTitle, style: .bodyLBold, color: .tabiTextPrimary)
                TabiLabel(
                    title: Strings.RegionSpot.comingSoonDescription,
                    style: .bodyS,
                    color: .tabiTextSecondary,
                    isExpanded: true
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }
}

//
//  DetailView.swift
//  Presentation
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

struct DetailView: View {
    @Bindable private var store: StoreOf<DetailFeature>
    let namespace: Namespace.ID

    @Environment(\.dismiss) private var dismiss

    init(store: StoreOf<DetailFeature>, namespace: Namespace.ID) {
        self.store = store
        self.namespace = namespace
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    DetailHeroView(
                        images: self.store.images,
                        currentIndex: self.$store.currentImageIndex
                    )
                    self.contentHeaderSection()
                    self.tabBarSection()
                    self.tabContentSection()
                        .animation(.tabiStandard, value: self.store.selectedTab)
                }
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .coordinateSpace(name: "detailScroll")

            DetailPinnedTopBar(
                isSaved: self.store.isSaved,
                onBackTapped: { self.dismiss() },
                onShareTapped: {},
                onSaveTapped: { self.store.send(.saveButtonTapped) }
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea(edges: .all)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DetailBottomCTAView(
                isSaved: self.store.isSaved,
                onSaveTapped: { self.store.send(.saveButtonTapped) },
                onAddToItineraryTapped: {}
            )
        }
        .navigationTransition(.zoom(sourceID: self.store.touristSpot.id, in: self.namespace))
    }
}

// MARK: - Method

private extension DetailView {
    func contentHeaderSection() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            TabiLabel(title: self.store.detail.japaneseTitle, style: .titleL, color: .tabiTextPrimary)
            if let koreanTitle = self.store.detail.koreanTitle {
                TabiLabel(title: koreanTitle, style: .bodyM, color: .tabiTextSecondary)
                    .padding(.top, 4)
            }
            HStack {
                TabiTag(self.store.detail.contentType.label, color: self.store.detail.contentType.color)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(TabiColor.tabiTextTertiary)
                    TabiLabel(title: self.store.detail.address, style: .captionM, color: .tabiTextTertiary)
                }
            }
            .padding(.top, 12)
            Divider()
                .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    func tabBarSection() -> some View {
        HStack(spacing: 8) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                TabiChip(tab.label, isSelected: self.store.selectedTab == tab) {
                    self.store.send(.tabSelected(tab))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    func tabContentSection() -> some View {
        if self.store.selectedTab == .info {
            DetailInfoTabView(intro: self.$store.intro, detail: self.$store.detail)
        }
        if self.store.selectedTab == .photos {
            DetailPhotosTabView(images: self.store.images)
        }
        if self.store.selectedTab == .map {
            DetailMapTabView()
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace

    DetailView(
        store: Store(
            initialState: DetailFeature.State(
                touristSpot: TouristSpot(
                    id: "264337",
                    title: "景福宮（경복궁）",
                    thumbnailURLString: nil,
                    distanceMeters: 1200,
                    contentType: .sightseeing
                )
            ),
            reducer: { DetailFeature() }
        ),
        namespace: namespace
    )
}

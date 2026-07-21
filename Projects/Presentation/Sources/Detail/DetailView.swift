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
    
    fileprivate var visibleTabs: [DetailTab] {
        DetailTab.allCases.filter { $0 != .photos || self.store.images.isEmpty == false }
    }
    private static let heroTopAnchorID = "detailHeroTop"

    init(store: StoreOf<DetailFeature>, namespace: Namespace.ID) {
        self.store = store
        self.namespace = namespace
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    DetailHeroView(
                        images: self.store.images,
                        fallbackImageURL: self.store.detail.imageURL,
                        currentIndex: self.$store.currentImageIndex,
                        onImageTapped: { self.store.send(.photoCellTapped(index: $0)) }
                    )
                    .id(Self.heroTopAnchorID)
                    self.contentHeaderSection()
                    self.tabBarSection(proxy: proxy)
                    self.tabContentSection()
                        .animation(.tabiStandard, value: self.store.selectedTab)
                        .animation(.tabiStandard, value: self.store.isLoading)
                }
                .padding(.bottom, 115)
            }
            .scrollIndicators(.hidden)
            .coordinateSpace(name: "detailScroll")
            .ignoresSafeArea(edges: .all)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .tint(Color.getTabiColor(.tabiPrimary))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .tint(Color.getTabiColor(.tabiPrimary))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.store.send(.saveButtonTapped)
                    } label: {
                        Image(systemName: self.store.isSaved ? "heart.fill" : "heart")
                    }
                    .tint(Color.getTabiColor(.tabiPrimary))
                }
            }
            .navigationTransition(.zoom(sourceID: self.store.touristSpot.id, in: self.namespace))
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                DetailBottomCTAView(
                    isSaved: self.store.isSaved,
                    onSaveTapped: { self.store.send(.saveButtonTapped) },
                    onAddToItineraryTapped: {}
                )
            }
            .onAppear {
                self.store.send(.onAppear)
            }
        }
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

    func tabBarSection(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 8) {
            ForEach(self.visibleTabs, id: \.self) { tab in
                TabiChip(tab.label, isSelected: self.store.selectedTab == tab) {
                    self.selectTab(tab, proxy: proxy)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    func selectTab(_ tab: DetailTab, proxy: ScrollViewProxy) {
        withAnimation(.tabiStandard) {
            proxy.scrollTo(Self.heroTopAnchorID, anchor: .top)
        } completion: {
            self.store.send(.tabSelected(tab))
        }
    }

    @ViewBuilder
    func tabContentSection() -> some View {
        if self.store.selectedTab == .info {
            if self.store.isLoading {
                self.infoLoadingPlaceholder()
                    .transition(.opacity)
            } else {
                DetailInfoTabView(intro: self.$store.intro, detail: self.$store.detail)
                    .transition(.opacity)
            }
        }
        if self.store.selectedTab == .photos {
            DetailPhotosTabView(
                images: self.store.images,
                onImageTapped: { self.store.send(.photoCellTapped(index: $0)) }
            )
        }
        if self.store.selectedTab == .map {
            DetailMapTabView(
                touristSpotID: self.store.touristSpot.id,
                title: self.store.touristSpot.title,
                coordinate: self.store.detail.coordinate
            )
        }
    }

    func infoLoadingPlaceholder() -> some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }
}

#Preview {
    @Previewable @Namespace var namespace

    let mockUseCase: TestTouristSpotUseCase = {
        let useCase = TestTouristSpotUseCase()
        useCase.detail = .mock
        useCase.intro = .mock
        useCase.images = .mock
        return useCase
    }()

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
            reducer: { DetailFeature() },
            withDependencies: { dependency in
                dependency.touristSpotUseCase = mockUseCase
            }
        ),
        namespace: namespace
    )
}

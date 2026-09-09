//
//  FestivalView.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

public struct FestivalView: View {

    @Bindable private var store: StoreOf<FestivalFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var headerHeight: CGFloat = 0

    public init(store: StoreOf<FestivalFeature>) {
        self.store = store
    }

    public var body: some View {
        self.contentScrollView()
            .navigationTitle(Strings.Home.eventFestivalTitle)
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

private extension FestivalView {
    func filterSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            FestivalDateRangeView(
                startDate: self.$store.startDate,
                endDate: self.$store.endDate,
                activeField: self.store.activeDateField,
                onFieldTapped: { field in
                    self.store.send(.dateFieldTapped(field), animation: .tabiStandard)
                }
            )

            if self.store.regions.isEmpty == false {
                FestivalRegionFilterBar(
                    regions: self.store.regions,
                    selectedRegionCode: self.store.selectedRegionCode
                ) { regionCode in
                    self.store.send(.regionChipTapped(regionCode), animation: .tabiStandard)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newValue in
            self.headerHeight = newValue
        }
    }

    func contentScrollView() -> some View {
        GeometryReader { proxy in
            ScrollView {
                self.filterSection()

                switch self.store.loadState {
                case .idle, .loading:
                    ProgressView()
                        .frame(height: max(proxy.size.height - self.headerHeight, 0))
                        .frame(maxWidth: .infinity)

                case .failed:
                    TabiRetryableEmptyState(description: Strings.RegionSpot.errorDescription) {
                        self.store.send(.retryButtonTapped)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .frame(height: max(proxy.size.height - self.headerHeight, 0), alignment: .top)

                case .loaded where self.store.festivals.isEmpty:
                    FestivalEmptyState()
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .frame(height: max(proxy.size.height - self.headerHeight, 0), alignment: .top)

                case .loaded:
                    LazyVStack(spacing: 0) {
                        ForEach(self.store.festivals) { festival in
                            TabiFestivalRow(
                                thumbnailURL: festival.touristSpot.thumbnailURL,
                                japaneseTitle: self.mainTitle(of: festival.touristSpot),
                                koreanTitle: self.subTitle(of: festival.touristSpot),
                                periodTitle: festival.periodTitle,
                                onTap: { self.store.send(.festivalTapped(festival)) }
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Method

private extension FestivalView {
    /// 로케일이 한국어이고 한국어 표기가 존재하면 한국어를 메인(볼드)으로 표시
    func mainTitle(of spot: TouristSpot) -> String {
        if Locale.isKoreanLanguage, let koreanTitle = spot.koreanTitle {
            return koreanTitle
        }
        return spot.japaneseTitle
    }

    func subTitle(of spot: TouristSpot) -> String? {
        if Locale.isKoreanLanguage, spot.koreanTitle != nil {
            return spot.japaneseTitle
        }
        return spot.koreanTitle
    }
}

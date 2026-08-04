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
import Resource

public struct FestivalView: View {

    @Bindable private var store: StoreOf<FestivalFeature>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<FestivalFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            self.filterSection()
            self.festivalList()
        }
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
    }

    func festivalList() -> some View {
        GeometryReader { proxy in
            List {
                Section {
                    if self.store.isLoading {
                        ProgressView()
                            .frame(height: max(proxy.size.height, 0))
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                    } else if self.store.festivals.isEmpty {
                        FestivalEmptyState()
                            .frame(height: max(proxy.size.height, 0))
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(self.store.festivals) { festival in
                            TabiFestivalRow(
                                thumbnailURL: festival.touristSpot.thumbnailURL,
                                japaneseTitle: festival.touristSpot.japaneseTitle,
                                koreanTitle: festival.touristSpot.koreanTitle,
                                periodTitle: festival.periodTitle,
                                onTap: { self.store.send(.festivalTapped(festival)) }
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 0, for: .scrollContent)
        }
    }
}

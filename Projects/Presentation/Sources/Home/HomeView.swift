//
//  HomeView.swift
//  Presentation
//
//  Created by 이윤수 on 6/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource
import Domain
import ComposableArchitecture

public struct HomeView: View {

    fileprivate enum ExchangeField: Hashable {
        case krw
        case jpy
    }

    @Bindable private var store: StoreOf<HomeFeature>
    @Environment(\.openURL) var openURL
    @FocusState private var focusedExchangeField: ExchangeField?

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    if self.store.locationStatus == .allowed && self.store.currentRegion.isKorea {
                        self.inKoreaBanner()
                            .staggeredAppear(index: 0)
                        self.exchangeRateCard()
                            .staggeredAppear(index: 1)
                        self.categoryView()
                            .staggeredAppear(index: 2)
                        self.nearbyTouristSpotBanner()
                            .staggeredAppear(index: 3)
                        self.nearbyRestaurantBanner()
                            .staggeredAppear(index: 4)
                    } else {
                        if self.store.locationStatus == .allowed {
                            self.inJapanBanner()
                                .staggeredAppear(index: 0)
                        } else {
                            self.locationPermissionBanner()
                                .staggeredAppear(index: 0)
                        }
                        self.categoryView()
                            .staggeredAppear(index: 1)
                        self.recommendedRegionBanner()
                            .staggeredAppear(index: 2)
                    }
                    self.recommendedEventBanner()
                        .staggeredAppear(index: 5)
                }
                .animation(.tabiStandard, value: self.store.locationStatus)
                .animation(.tabiStandard, value: self.store.currentRegion.isKorea)
                .padding(.horizontal, 20)
                .padding(.top, 15)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .safeAreaBar(edge: .top) {
            TabiNavigationBar(subtitle: self.store.currentDate, title: Strings.Common.tabicori) {
                TabiGlassIconButton(systemName: "bell") {
                    print("tap")
                }
            }
        }
        .onAppear {
            self.store.send(.onAppear)
        }
        .onTapGesture {
            self.focusedExchangeField = nil
        }
    }
}

// MARK: - TourismContentType View Extension

private extension TourismContentType {
    var label: String {
        switch self {
        case .touristSpot: Strings.Common.categorySightseeing
        case .restaurant: Strings.Common.categoryFood
        case .accommodation: Strings.Common.categoryHotel
        case .festival: Strings.Common.categoryFestival
        case .shopping: Strings.Common.categoryShopping
        case .culturalFacility: Strings.Common.contentTypeCulturalFacility
        case .leisure: Strings.Common.contentTypeLeisure
        }
    }

    var tagColor: TabiColor {
        switch self {
        case .touristSpot: .categorySightseeing
        case .restaurant: .categoryFood
        case .accommodation: .categoryHotel
        case .festival: .categoryFestival
        case .shopping: .categoryShopping
        case .culturalFacility: .tabiAccentLavender
        case .leisure: .tabiAccentMint
        }
    }
}

// MARK: - NearbySpot View Extension

private extension NearbySpot {
    var formattedDistance: String? {
        guard let dist = self.distanceMeters else { return nil }
        if dist >= 1000 { return String(format: "%.1fkm", dist / 1000) }
        return "\(Int(dist))m"
    }
}

// MARK: - HomeView Private

fileprivate extension HomeView {
    func inJapanBanner() -> some View {
        Button {
            self.store.send(.planCreateButtonTapped)
        } label: {
            TabiCard {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Strings.Home.japanTravelBannerFromLabel)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(TabiColor.tabiTextTertiary)
                                .tracking(1.0)
                            Text(Strings.Home.japanTravelBannerFromCountry)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(TabiColor.tabiTextPrimary)
                        }
                        Spacer()
                        Image(systemName: "airplane")
                            .font(.system(size: 18))
                            .foregroundStyle(TabiColor.tabiPrimary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Strings.Home.japanTravelBannerToLabel)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(TabiColor.tabiTextTertiary)
                                .tracking(1.0)
                            Text(Strings.Home.japanTravelBannerToCountry)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(TabiColor.tabiPrimary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 14)

                    Canvas { context, size in
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: 0.5))
                        path.addLine(to: CGPoint(x: size.width, y: 0.5))
                        context.stroke(path, with: .color(Color.getTabiColor(.tabiBorder)), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    }
                    .frame(height: 1.5)
                    .padding(.horizontal, 16)

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(Strings.Home.japanTravelBannerPlanLabel)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(TabiColor.tabiTextTertiary)
                                .tracking(0.8)
                            TabiLabel(title: Strings.Home.japanTravelBannerDescription, style: .bodyLBold, color: .tabiTextPrimary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(TabiColor.tabiTextTertiary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .buttonStyle(TabiPressStyle())
    }

    func locationPermissionBanner() -> some View {
        Button {
            // 설정 탭 이동
        } label: {
            TabiCard {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "location.slash.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(TabiColor.tabiAccentAmber)

                    VStack(alignment: .leading, spacing: 3) {
                        TabiLabel(title: Strings.Home.locationBannerTitle, style: .bodyLBold, color: .tabiTextPrimary)
                        TabiLabel(
                            title: Strings.Home.locationBannerDescription,
                            style: .bodyS,
                            color: .tabiTextSecondary,
                            isExpanded: true
                        )
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TabiColor.tabiTextTertiary)
                }
                .padding(16)
            }
        }
        .buttonStyle(TabiPressStyle())
    }

    func nearbyTouristSpotBanner() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TabiLabel(title: Strings.Home.nearbyTouristSpotsTitle, style: .titleM, color: .tabiTextPrimary)

            if self.store.isLoadingTouristSpots {
                self.nearbyTouristSpotSkeletonRow()
            } else if self.store.nearbyTouristSpots.isEmpty {
                self.nearbyTouristSpotEmptyState()
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(self.store.nearbyTouristSpots) { spot in
                            self.nearbyTouristSpotCard(spot)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    func nearbyRestaurantBanner() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TabiLabel(title: Strings.Home.nearbyRestaurantsTitle, style: .titleM, color: .tabiTextPrimary)

            if self.store.isLoadingRestaurants {
                self.nearbyRestaurantSkeletonCard()
            } else if self.store.nearbyRestaurants.isEmpty {
                self.nearbyRestaurantEmptyState()
            } else {
                TabiCard {
                    VStack(spacing: 0) {
                        ForEach(Array(self.store.nearbyRestaurants.enumerated()), id: \.element.id) { index, spot in
                            if index > 0 {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                            self.nearbyRestaurantRow(spot)
                        }
                    }
                }
            }
        }
    }

    func nearbyTouristSpotCard(_ spot: NearbySpot) -> some View {
        Button {
            self.store.send(.nearbySpotTapped(spot))
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                AsyncImage(url: URL(string: spot.thumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.getTabiColor(.tabiBorder).opacity(0.25)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundStyle(TabiColor.tabiTextTertiary)
                        }
                }
                .frame(width: 160, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))

                VStack(alignment: .leading, spacing: 4) {
                    TabiTag(spot.contentType.label, color: spot.contentType.tagColor)

                    TabiLabel(
                        title: spot.title,
                        style: .bodyMBold,
                        color: .tabiTextPrimary,
                        lineLimit: 2
                    )
                    .frame(width: 160, alignment: .leading)

                    if let distance = spot.formattedDistance {
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(TabiColor.tabiTextTertiary)
                            TabiLabel(title: distance, style: .captionM, color: .tabiTextTertiary)
                        }
                    }
                }
            }
            .frame(width: 160)
        }
        .buttonStyle(TabiPressStyle())
    }

    func nearbyTouristSpotSkeletonRow() -> some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    self.nearbyTouristSpotSkeletonCard()
                }
            }
        }
        .scrollIndicators(.hidden)
        .allowsHitTesting(false)
    }

    func nearbyTouristSpotSkeletonCard() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: .tabiRadiusMd)
                .fill(TabiColor.tabiBorder.opacity(0.3))
                .frame(width: 160, height: 110)

            VStack(alignment: .leading, spacing: 6) {
                Capsule()
                    .fill(TabiColor.tabiBorder.opacity(0.3))
                    .frame(width: 60, height: 20)

                RoundedRectangle(cornerRadius: 4)
                    .fill(TabiColor.tabiBorder.opacity(0.3))
                    .frame(width: 140, height: 16)

                RoundedRectangle(cornerRadius: 4)
                    .fill(TabiColor.tabiBorder.opacity(0.3))
                    .frame(width: 80, height: 16)

                RoundedRectangle(cornerRadius: 4)
                    .fill(TabiColor.tabiBorder.opacity(0.2))
                    .frame(width: 50, height: 14)
            }
        }
        .frame(width: 160)
    }

    func nearbyTouristSpotEmptyState() -> some View {
        TabiCard {
            HStack(spacing: 10) {
                Image(systemName: "mappin.slash")
                    .font(.system(size: 22))
                    .foregroundStyle(TabiColor.tabiTextTertiary)

                VStack(alignment: .leading, spacing: 3) {
                    TabiLabel(title: "観光地が見つかりませんでした", style: .bodySBold, color: .tabiTextSecondary)
                    TabiLabel(title: "周辺に観光スポットはありません。", style: .captionM, color: .tabiTextTertiary, isExpanded: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    func nearbyRestaurantRow(_ spot: NearbySpot) -> some View {
        Button {
            self.store.send(.nearbySpotTapped(spot))
        } label: {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: spot.thumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.getTabiColor(.tabiBorder).opacity(0.25)
                        .overlay {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 16))
                                .foregroundStyle(TabiColor.tabiTextTertiary)
                        }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))

                VStack(alignment: .leading, spacing: 4) {
                    TabiLabel(title: spot.title, style: .bodyMBold, color: .tabiTextPrimary, lineLimit: 2)
                    TabiTag(spot.contentType.label, color: spot.contentType.tagColor)
                }

                Spacer()

                if let distance = spot.formattedDistance {
                    HStack(spacing: 3) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(TabiColor.tabiTextTertiary)
                        TabiLabel(title: distance, style: .captionM, color: .tabiTextTertiary)
                    }
                }
            }
            .padding(16)
        }
        .buttonStyle(TabiPressStyle())
    }

    func nearbyRestaurantSkeletonCard() -> some View {
        TabiCard {
            VStack(spacing: 0) {
                ForEach(0 ..< 3, id: \.self) { index in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
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
            }
        }
        .allowsHitTesting(false)
    }

    func nearbyRestaurantEmptyState() -> some View {
        TabiCard {
            HStack(spacing: 10) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 22))
                    .foregroundStyle(TabiColor.tabiTextTertiary)

                VStack(alignment: .leading, spacing: 3) {
                    TabiLabel(title: "飲食店が見つかりませんでした", style: .bodySBold, color: .tabiTextSecondary)
                    TabiLabel(title: "周辺に飲食店はありません。", style: .captionM, color: .tabiTextTertiary, isExpanded: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    func categoryView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TabiLabel(title: Strings.Common.categoryTitle, style: .titleM, color: .tabiTextPrimary)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(CategoryType.allItems, id: \.self) { type in
                        self.categoryItemButton(type)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    func recommendedEventBanner() -> some View {
        Button {
        } label: {
            TabiCard {
                HStack(alignment: .center, spacing: 10) {
                    Image(.seoulTower)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 70)
                        .colorMultiply(Color.getTabiColor(.tabiSecondary))
                        .opacity(0.6)

                    VStack(alignment: .leading, spacing: 3) {
                        TabiLabel(title: Strings.Home.festivalRecommendationTitle(6), style: .bodyLBold, color: .tabiTextPrimary)
                        TabiLabel(
                            title: Strings.Home.eventFestivalTitle,
                            style: .bodyS,
                            color: .tabiTextSecondary,
                            isExpanded: true
                        )
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TabiColor.tabiTextTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
            }
            .contentShape(RoundedRectangle(cornerRadius: .tabiRadiusLg))
        }
        .buttonStyle(TabiPressStyle())
    }

    func recommendedRegionBanner() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TabiLabel(title: Strings.Home.popularSpotsTitle, style: .titleM, color: .tabiTextPrimary)

            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(KoreanRegion.allItems, id: \.self) { region in
                        self.regionCard(region)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    func regionCard(_ region: KoreanRegion) -> some View {
        Button {
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Image(region.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))
                    .padding(.bottom, 4)

                TabiLabel(title: region.jaTitle, style: .bodyMBold, color: .tabiTextPrimary)
                TabiLabel(title: region.koTitle, style: .captionM, color: .tabiTextSecondary)
            }
        }
        .buttonStyle(TabiPressStyle())
    }

    func categoryItemButton(_ item: CategoryType) -> some View {
        Button {
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: .tabiRadiusMd)
                    .fill(item.color.opacity(0.1))
                    .frame(width: 55, height: 55)
                    .overlay {
                        Image(item.icon)
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundStyle(item.color)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: .tabiRadiusMd)
                            .stroke(item.color.opacity(0.3), lineWidth: 1)
                    }

                TabiLabel(title: item.label, style: .captionM, color: .tabiTextSecondary)
            }
            .frame(width: 55)
        }
        .buttonStyle(TabiPressStyle())
    }

    func exchangeRateCard() -> some View {
        TabiCard {
            HStack(spacing: 0) {
                self.currencyAmountField(
                    flag: "🇰🇷",
                    code: "KRW",
                    symbol: "₩",
                    field: .krw,
                    text: self.$store.krwAmountText,
                    fractionDigits: 0,
                    valueColor: .tabiTextPrimary
                )
                .frame(maxWidth: .infinity)

                VStack(spacing: 6) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(TabiColor.tabiTextTertiary)
                    Text("=")
                        .font(.system(size: 12))
                        .foregroundStyle(TabiColor.tabiTextTertiary)
                }

                self.currencyAmountField(
                    flag: "🇯🇵",
                    code: "JPY",
                    symbol: "¥",
                    field: .jpy,
                    text: self.$store.jpyAmountText,
                    fractionDigits: 1,
                    valueColor: .tabiPrimary
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
    }

    func currencyAmountField(
        flag: String,
        code: String,
        symbol: String,
        field: ExchangeField,
        text: Binding<String>,
        fractionDigits: Int,
        valueColor: TabiColor
    ) -> some View {
        let isFocused = self.focusedExchangeField == field

        return VStack(spacing: 6) {
            Text(flag)
                .font(.system(size: 32))

            HStack(spacing: 2) {
                Text(symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(valueColor)

                ZStack {
                    TextField("0", text: text)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .opacity(isFocused ? 1 : 0.02)
                        .focused(self.$focusedExchangeField, equals: field)

                    if !isFocused {
                        Group {
                            if let value = Double(text.wrappedValue) {
                                Text(value, format: .number.precision(.fractionLength(fractionDigits)))
                            } else {
                                Text(text.wrappedValue)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: 70)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(valueColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(TabiColor.tabiBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? valueColor : TabiColor.tabiBorder, lineWidth: isFocused ? 1.5 : 1)
            }

            Text(code)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(TabiColor.tabiTextTertiary)
                .tracking(0.8)
        }
    }

    func inKoreaBanner() -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(.regionSeoul)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 160)
            LinearGradient(
                colors: [.clear, Color.getTabiColor(.tabiScrim).opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                TabiLabel(title: Strings.Region.seoul, style: .titleM, color: .tabiOnColor)
                TabiLabel(title: "ソウルにいますね！", style: .bodyS, color: .tabiOnColor)
                    .opacity(0.85)
                Spacer()
            }
            .padding(16)

            HStack(spacing: 0) {
                Spacer()
                TabiButton("プランへ移動", style: .glass(on: .accent)) {}
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusLg))
    }
}
#Preview {
    HomeView(store: .init(
        initialState: .init(),
        reducer: { HomeFeature() }
    ))
}

//
//  OnboardingHomeStepView.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct OnboardingHomeStepView: View {
    let selectedCategory: CategoryType?
    let onCategoryTapped: (CategoryType) -> Void

    var body: some View {
        OnboardingStepFrame(
            title: OnboardingStep.home.title,
            description: OnboardingStep.home.description
        ) {
            VStack(alignment: .leading, spacing: 20) {
                TabiSearchField(placeholder: Strings.Map.searchPlaceholder) {}
                self.exchangeRateCard()
                self.regionBanner()
                self.categorySection()
                self.nearbySpotSection()
            }
        }
    }
}

// MARK: - View

private extension OnboardingHomeStepView {
    func exchangeRateCard() -> some View {
        TabiCard {
            HStack(spacing: 12) {
                self.currencySummary(flag: "🇰🇷", code: "KRW", amountText: "1,000")
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(TabiColor.tabiTextTertiary)
                self.currencySummary(flag: "🇯🇵", code: "JPY", amountText: "108.5")
            }
            .padding(16)
        }
    }

    func currencySummary(flag: String, code: String, amountText: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            TabiLabel(title: "\(flag) \(code)", style: .captionM, color: .tabiTextSecondary)
            TabiLabel(title: amountText, style: .bodyMBold, color: .tabiTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func regionBanner() -> some View {
        Image(TabiImage.regionSeoul)
            .resizable()
            .scaledToFill()
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusLg))
    }

    func categorySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TabiLabel(title: Strings.Common.categoryTitle, style: .titleM, color: .tabiTextPrimary)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(CategoryType.allItems, id: \.self) { type in
                        TabiChip(type.label, isSelected: type == self.selectedCategory) {
                            self.onCategoryTapped(type)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    func nearbySpotSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TabiLabel(title: Strings.Home.nearbyTouristSpotsTitle, style: .titleM, color: .tabiTextPrimary)

            VStack(spacing: 12) {
                ForEach(OnboardingMock.nearbySpots) { spot in
                    TabiCard {
                        MapSearchResultRowView(spot: spot, onTapped: {})
                    }
                }
            }
        }
    }
}

//
//  PlanDetailAddSpotAddressView.swift
//  Presentation
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

/// PlanDetailAddSpot 시트의 "カスタム" 탭. 제목/주소를 입력하고 주소 필드에서 엔터를 누르면
/// 지오코딩된 좌표를 지도에 미리보기로 표시한다. 카테고리로 "지하철"을 선택하면 제목 필드가 역명 검색어로
/// 전환되어 지하철역 검색 모드로 들어간다. 카테고리를 선택하고 확정하면 상위(Feature)가
/// TouristSpot을 만들어 기존 시간설정 단계로 넘긴다
struct PlanDetailAddSpotAddressView: View {
    @Binding var title: String
    @Binding var address: String
    let selectedCategory: CategoryType?
    let previewCoordinate: Coordinate?
    let previewFitToken: Int
    let isGeocoding: Bool
    let isConfirmEnabled: Bool
    let isSubwayMode: Bool
    let isSubwaySearching: Bool
    let subwayResults: [SubwayStation]
    let matchedStation: TouristSpot?
    let isAutoTranslateSearchEnabled: Bool
    let isTranslating: Bool
    let titleFocus: FocusState<Bool>.Binding
    let addressFocus: FocusState<Bool>.Binding
    let onAddressSubmit: () -> Void
    let onCategorySelected: (CategoryType) -> Void
    let onStationNameSubmit: () -> Void
    let onStationTapped: (SubwayStation) -> Void
    let onTranslateTapped: () -> Void
    let onConfirmTapped: () -> Void

    private var trimmedTitle: String {
        self.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                self.categorySection()
                self.titleField()
                self.bottomSection()
                self.confirmButton()
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 24)
            .animation(.tabiStandard, value: self.previewCoordinate)
            .animation(.tabiStandard, value: self.isSubwayMode)
            .animation(.tabiStandard, value: self.subwayResults)
            .animation(.tabiStandard, value: self.matchedStation)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

// MARK: - View

private extension PlanDetailAddSpotAddressView {
    func categorySection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.Common.categoryTitle, style: .bodyMBold, color: .tabiTextPrimary)
            BookmarkCategoryFilterBar(
                selectedCategory: self.isSubwayMode ? .subway : self.selectedCategory,
                includesAllChip: false,
                includesSubwayChip: true
            ) { category in
                guard let category else { return }
                self.onCategorySelected(category)
            }
        }
    }

    func titleField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(
                title: self.isSubwayMode ? Strings.AddCustomPlace.stationTitleLabel : Strings.AddCustomPlace.titleLabel,
                style: .bodyMBold,
                color: .tabiTextPrimary
            )
            HStack(spacing: 8) {
                TabiTextField(
                    placeholder: self.isSubwayMode ? Strings.AddCustomPlace.stationTitlePlaceholder : Strings.AddCustomPlace.titlePlaceholder,
                    text: self.$title,
                    focus: self.titleFocus
                )
                .onSubmit {
                    guard self.isSubwayMode else { return }
                    self.onStationNameSubmit()
                }

                if self.isSubwayMode, self.isAutoTranslateSearchEnabled {
                    self.stationTranslateButton()
                }
            }
            if self.isSubwayMode {
                TabiLabel(
                    title: self.trimmedTitle.isEmpty ? Strings.Common.subwayKatakanaGuide : Strings.Common.subwaySearchEnterGuide,
                    style: .captionM,
                    color: .tabiTextSecondary
                )
            }
            if self.isSubwayMode, self.isSubwaySearching {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    func bottomSection() -> some View {
        if self.isSubwayMode {
            if self.matchedStation != nil {
                self.mapPreviewSection()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                self.subwayResultsSection()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        } else {
            self.addressField()
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    func addressField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.AddCustomPlace.addressLabel, style: .bodyMBold, color: .tabiTextPrimary)
            TabiTextField(
                placeholder: Strings.AddCustomPlace.addressPlaceholder,
                text: self.$address,
                focus: self.addressFocus
            )
            .onSubmit {
                self.onAddressSubmit()
            }
            // 주소를 한국어로 검색하라는 안내이므로, 시스템 로케일이 이미 한국어인 사용자에게는 노출하지 않는다
            if Locale.isKoreanLanguage == false {
                TabiLabel(
                    title: Strings.AddCustomPlace.addressKoreanSearchGuide,
                    style: .captionM,
                    color: .tabiTextSecondary
                )
            }
            if self.isGeocoding {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            self.mapPreviewSection()
        }
    }

    /// "カスタム" 탭 지하철 검색의 번역 버튼. "検索" 탭의 번역 버튼과 동일한 조건(자동 번역 검색 활성화 시)으로
    /// 노출되며, 공유 `translateSearch` Scope에 역명(title)을 검색어로 실어 번역을 요청한다
    func stationTranslateButton() -> some View {
        TabiButton(
            Strings.Map.translateButtonTitle,
            style: .surface,
            isLoading: self.isTranslating,
            cornerRadius: .tabiRadiusMd
        ) {
            self.onTranslateTapped()
        }
        .accessibilityLabel(Strings.Map.translateSearchButtonAccessibilityLabel)
    }

    @ViewBuilder
    func subwayResultsSection() -> some View {
        if self.subwayResults.isEmpty == false {
            VStack(spacing: 0) {
                ForEach(Array(self.subwayResults.enumerated()), id: \.element.stationCode) { index, station in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    TabiSpotRow(
                        thumbnailURL: nil,
                        japaneseTitle: station.displayJapaneseName,
                        koreanTitle: station.koreanName,
                        address: station.lineNumbers.joined(separator: "・"),
                        tagTitle: CategoryType.subway.label,
                        tagColor: CategoryType.subway.color,
                        isCustom: false,
                        distance: nil,
                        onTap: { self.onStationTapped(station) }
                    )
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: .tabiRadiusLg)
                    .stroke(TabiColor.tabiBorder.opacity(0.4), lineWidth: 1)
            }
        }
    }

    func mapPreviewSection() -> some View {
        let coordinate = self.previewCoordinate ?? .seoulCityHall
        let category = self.isSubwayMode ? CategoryType.subway : (self.selectedCategory ?? .sightseeing)
        let markerTitle = self.isSubwayMode
            ? (self.matchedStation?.japaneseTitle ?? self.trimmedTitle.removingHangul)
            : self.trimmedTitle.removingHangul
        let markers: [TabiMapMarker] = self.previewCoordinate == nil ? [] : [
            TabiMapMarker(
                id: "preview",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                title: markerTitle,
                icon: category.icon,
                color: category.color
            )
        ]

        return TabiMapView(
            centerLatitude: coordinate.latitude,
            centerLongitude: coordinate.longitude,
            markers: markers,
            boundsFitToken: self.previewFitToken,
            onMapTapped: { _, _ in },
            onMarkerTapped: { _ in }
        )
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusLg))
        .overlay {
            RoundedRectangle(cornerRadius: .tabiRadiusLg)
                .stroke(TabiColor.tabiBorder.opacity(0.4), lineWidth: 1)
        }
    }

    func confirmButton() -> some View {
        TabiButton(
            Strings.AddToItinerary.saveButton,
            style: .primary,
            isExpanded: true,
            height: 45,
            cornerRadius: .tabiRadiusFull
        ) {
            self.onConfirmTapped()
        }
        .disabled(!self.isConfirmEnabled)
    }
}

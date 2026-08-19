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

/// PlanDetailAddSpot 시트의 "주소로 추가" 탭. 제목/주소를 입력하고 주소 필드에서 엔터를 누르면
/// 지오코딩된 좌표를 지도에 미리보기로 표시한다. 카테고리를 선택하고 확정하면 상위(Feature)가
/// TouristSpot을 만들어 기존 시간설정 단계로 넘긴다
struct PlanDetailAddSpotAddressView: View {
    @Binding var title: String
    @Binding var address: String
    let selectedCategory: CategoryType?
    let previewCoordinate: Coordinate?
    let previewFitToken: Int
    let isGeocoding: Bool
    let isConfirmEnabled: Bool
    let titleFocus: FocusState<Bool>.Binding
    let addressFocus: FocusState<Bool>.Binding
    let onAddressSubmit: () -> Void
    let onCategorySelected: (CategoryType) -> Void
    let onConfirmTapped: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                self.categorySection()
                self.titleField()
                self.addressField()
                self.mapPreviewSection()
                self.confirmButton()
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 24)
            .animation(.tabiStandard, value: self.previewCoordinate)
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
                selectedCategory: self.selectedCategory,
                includesAllChip: false,
                includesSubwayChip: false
            ) { category in
                guard let category else { return }
                self.onCategorySelected(category)
            }
        }
    }

    func titleField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.AddCustomPlace.titleLabel, style: .bodyMBold, color: .tabiTextPrimary)
            TabiTextField(
                placeholder: Strings.AddCustomPlace.titlePlaceholder,
                text: self.$title,
                focus: self.titleFocus
            )
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
            TabiLabel(
                title: Strings.AddCustomPlace.addressKoreanSearchGuide,
                style: .captionM,
                color: .tabiTextSecondary
            )
            if self.isGeocoding {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    func mapPreviewSection() -> some View {
        let coordinate = self.previewCoordinate ?? .seoulCityHall
        let category = self.selectedCategory ?? .sightseeing
        let markerTitle = self.title.trimmingCharacters(in: .whitespacesAndNewlines)
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

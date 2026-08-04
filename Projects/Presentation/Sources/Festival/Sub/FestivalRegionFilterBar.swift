//
//  FestivalRegionFilterBar.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct FestivalRegionFilterBar: View {
    var regions: [LDongRegion]
    var selectedRegionCode: String?
    var onSelect: (String?) -> Void

    @State private var isAllRegionsPresented: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    TabiChip(
                        Strings.Common.contentTypeAll,
                        isSelected: self.selectedRegionCode == nil
                    ) {
                        self.onSelect(nil)
                    }

                    ForEach(self.regions) { region in
                        TabiChip(
                            region.name,
                            isSelected: self.selectedRegionCode == region.code
                        ) {
                            self.onSelect(region.code)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)

            Button {
                self.isAllRegionsPresented = true
            } label: {
                Image(systemName: "chevron.down")
                    .foregroundStyle(TabiColor.tabiTextSecondary)
            }
        }
        .sheet(isPresented: self.$isAllRegionsPresented) {
            self.allRegionsSheet()
        }
    }
}

// MARK: - View

private extension FestivalRegionFilterBar {
    func allRegionsSheet() -> some View {
        ScrollView {
            VStack(spacing: 0) {
                self.regionRow(
                    title: Strings.Common.contentTypeAll,
                    isSelected: self.selectedRegionCode == nil
                ) {
                    self.onSelect(nil)
                    self.isAllRegionsPresented = false
                }

                ForEach(self.regions) { region in
                    self.regionRow(
                        title: region.name,
                        isSelected: self.selectedRegionCode == region.code
                    ) {
                        self.onSelect(region.code)
                        self.isAllRegionsPresented = false
                    }
                }
            }
            .padding(.top, 10)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    func regionRow(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                TabiLabel(
                    title: title,
                    style: isSelected ? .bodyMBold : .bodyM,
                    color: isSelected ? .tabiPrimary : .tabiTextPrimary
                )

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(TabiColor.tabiPrimary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        Divider()
            .padding(.leading, 20)
    }
}

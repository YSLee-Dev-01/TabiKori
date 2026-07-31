//
//  AddPlanRegionGridView.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct AddPlanRegionGridView: View {
    let selectedRegion: KoreanRegion?
    @Binding var customRegionText: String
    let onSelect: (KoreanRegion) -> Void

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(KoreanRegion.planGridItems, id: \.self) { region in
                    self.regionCell(region)
                }
            }

            if self.selectedRegion == .etc {
                TabiTextField(placeholder: Strings.Plan.customRegionPlaceholder, text: self.$customRegionText)
            }
        }
    }
}

// MARK: - View

private extension AddPlanRegionGridView {
    func regionCell(_ region: KoreanRegion) -> some View {
        let isSelected = self.selectedRegion == region

        return Button {
            self.onSelect(region)
        } label: {
            VStack(spacing: 4) {
                Text(region == .etc ? "✏️" : (region.emoji ?? ""))
                    .font(.system(size: 28))
                TabiLabel(
                    title: region.jaTitle,
                    style: .captionMBold,
                    color: isSelected ? .tabiOnColor : .tabiTextPrimary
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? TabiColor.tabiPrimary : TabiColor.tabiSurface)
            .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: .tabiRadiusMd)
                        .stroke(TabiColor.tabiBorder, lineWidth: 1)
                }
            }
        }
        .buttonStyle(TabiPressStyle())
    }
}

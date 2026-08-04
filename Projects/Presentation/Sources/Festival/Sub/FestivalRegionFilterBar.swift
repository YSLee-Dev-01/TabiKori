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

    var body: some View {
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
    }
}

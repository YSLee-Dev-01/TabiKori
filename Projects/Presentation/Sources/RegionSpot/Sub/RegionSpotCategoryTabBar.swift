//
//  RegionSpotCategoryTabBar.swift
//  Presentation
//
//  Created by 이윤수 on 8/10/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain

struct RegionSpotCategoryTabBar: View {
    var selectedCategory: CategoryType
    var onSelect: (CategoryType) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(CategoryType.allItems, id: \.self) { category in
                        TabiChip(
                            category.label,
                            isSelected: self.selectedCategory == category
                        ) {
                            self.onSelect(category)
                        }
                        .id(category)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .onChange(of: self.selectedCategory) { _, newValue in
                withAnimation(.tabiStandard) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}

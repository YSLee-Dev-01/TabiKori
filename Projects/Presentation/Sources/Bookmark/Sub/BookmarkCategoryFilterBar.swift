//
//  BookmarkCategoryFilterBar.swift
//  Presentation
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct BookmarkCategoryFilterBar: View {

    var selectedCategory: CategoryType?
    var includesAllChip: Bool = true
    var includesSubwayChip: Bool = false
    var onSelect: (CategoryType?) -> Void

    private let allChipID: String = "BookmarkCategoryFilterBar.all"

    private var selectedChipID: String {
        self.selectedCategory?.rawValue ?? self.allChipID
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    if self.includesAllChip {
                        TabiChip(
                            Strings.Common.contentTypeAll,
                            isSelected: self.selectedCategory == nil
                        ) {
                            self.onSelect(nil)
                        }
                        .id(self.allChipID)
                    }

                    if self.includesSubwayChip {
                        TabiChip(
                            CategoryType.subway.label,
                            isSelected: self.selectedCategory == .subway
                        ) {
                            self.onSelect(.subway)
                        }
                        .id(CategoryType.subway.rawValue)
                    }

                    ForEach(CategoryType.allItems, id: \.self) { category in
                        TabiChip(
                            category.label,
                            isSelected: self.selectedCategory == category
                        ) {
                            self.onSelect(category)
                        }
                        .id(category.rawValue)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .onChange(of: self.selectedCategory) { _, _ in
                withAnimation(.tabiStandard) {
                    proxy.scrollTo(self.selectedChipID, anchor: .center)
                }
            }
        }
    }
}

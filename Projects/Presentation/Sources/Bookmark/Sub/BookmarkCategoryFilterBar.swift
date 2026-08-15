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
    var onSelect: (CategoryType?) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                if self.includesAllChip {
                    TabiChip(
                        Strings.Common.contentTypeAll,
                        isSelected: self.selectedCategory == nil
                    ) {
                        self.onSelect(nil)
                    }
                }

                ForEach(CategoryType.allItems, id: \.self) { category in
                    TabiChip(
                        category.label,
                        isSelected: self.selectedCategory == category
                    ) {
                        self.onSelect(category)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

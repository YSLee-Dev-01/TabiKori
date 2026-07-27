//
//  MapRecentSearchListView.swift
//  Presentation
//
//  Created by 이윤수 on 7/27/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct MapRecentSearchListView: View {

    var histories: [SearchHistory]
    var onTapped: (SearchHistory) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(self.histories.enumerated()), id: \.element.keyword) { index, history in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    self.row(history)
                }
            }
        }
    }
}

// MARK: - View

private extension MapRecentSearchListView {
    func row(_ history: SearchHistory) -> some View {
        Button {
            self.onTapped(history)
        } label: {
            HStack(spacing: 8) {
                TabiLabel(title: history.keyword, style: .bodyLBold, color: .tabiTextPrimary, lineLimit: 1)

                Spacer()

                TabiLabel(title: history.searchedAt.recentSearchDateTitle, style: .captionM, color: .tabiTextTertiary)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabiPressStyle())
    }
}

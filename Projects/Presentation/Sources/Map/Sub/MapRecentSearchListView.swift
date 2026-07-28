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
    var onDeleteTapped: (SearchHistory) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TabiLabel(title: Strings.Map.recentSearchTitle, style: .titleM, color: .tabiTextPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(self.histories.enumerated()), id: \.element.keyword) { index, history in
                        if index > 0 {
                            Divider()
                                .padding(.horizontal, 20)
                        }
                        self.row(history)
                    }
                }
            }
        }
    }
}

// MARK: - View

private extension MapRecentSearchListView {
    func row(_ history: SearchHistory) -> some View {
        HStack(spacing: 8) {
            Button {
                self.onTapped(history)
            } label: {
                HStack(spacing: 8) {
                    TabiLabel(title: history.keyword, style: .bodyLBold, color: .tabiTextPrimary, lineLimit: 1)

                    Spacer()

                    TabiLabel(title: history.searchedAt.recentSearchDateTitle, style: .captionM, color: .tabiTextTertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(TabiPressStyle())

            Button {
                self.onDeleteTapped(history)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TabiColor.tabiTextTertiary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(TabiPressStyle())
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

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

            List {
                ForEach(Array(self.histories.enumerated()), id: \.element.keyword) { index, history in
                    self.row(history, index: index)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                self.onDeleteTapped(history)
                            } label: {
                                Label(Strings.Common.delete, systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

// MARK: - View

private extension MapRecentSearchListView {
    func row(_ history: SearchHistory, index: Int) -> some View {
        VStack (alignment: .center, spacing: 0) {
            if index > 0 {
                Divider()
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            
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
            .padding(.vertical, 16)
        }
        .padding(.horizontal, 20)
    }
}

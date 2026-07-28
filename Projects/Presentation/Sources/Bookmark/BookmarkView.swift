//
//  BookmarkView.swift
//  Presentation
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

public struct BookmarkView: View {

    @Bindable private var store: StoreOf<BookmarkFeature>

    public init(store: StoreOf<BookmarkFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            if self.store.filteredBookmarks.isEmpty {
                BookmarkEmptyState()
            } else {
                self.bookmarkList()
            }
        }
        .safeAreaBar(edge: .top) {
            TabiNavigationBar(title: Strings.Bookmark.title)
        }
        .onAppear {
            self.store.send(.onAppear)
        }
    }
}

// MARK: - View

private extension BookmarkView {
    func bookmarkList() -> some View {
        List {
            Section {
                ForEach(self.store.filteredBookmarks) { bookmark in
                    TabiSpotRow(
                        thumbnailURL: bookmark.touristSpot.thumbnailURL,
                        japaneseTitle: bookmark.touristSpot.japaneseTitle,
                        koreanTitle: bookmark.touristSpot.koreanTitle,
                        tagTitle: bookmark.touristSpot.contentType.label,
                        tagColor: bookmark.touristSpot.contentType.color,
                        distance: nil,
                        onTap: { self.store.send(.spotTapped(bookmark.touristSpot)) }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            self.store.send(.deleteSwiped(contentId: bookmark.id))
                        } label: {
                            Label(Strings.Bookmark.delete, systemImage: "trash")
                        }
                    }
                }
            } header: {
                BookmarkCategoryFilterBar(
                    selectedCategory: self.store.selectedCategory
                ) { category in
                    self.store.send(.categoryFilterTapped(category))
                }

                TabiLabel(
                    title: Strings.Bookmark.savedCountTitle(self.store.bookmarks.count),
                    style: .captionMBold,
                    color: .tabiTextSecondary
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

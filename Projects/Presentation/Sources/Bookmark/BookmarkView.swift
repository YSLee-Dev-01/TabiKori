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
    @State private var headerHeight: CGFloat = 0

    public init(store: StoreOf<BookmarkFeature>) {
        self.store = store
    }
    
    public var body: some View {
        self.bookmarkList()
            .safeAreaBar(edge: .top) {
                TabiNavigationBar(title: Strings.Bookmark.title) {
                    self.addCustomPlaceButton()
                }
            }
            .sheet(item: self.$store.scope(state: \.addCustomPlaceState, action: \.addCustomPlace)) { store in
                AddCustomPlaceView(store: store)
            }
            .onAppear {
                self.store.send(.onAppear)
            }
    }
}

// MARK: - View

private extension BookmarkView {
    func addCustomPlaceButton() -> some View {
        TabiCircleIconButton(systemName: "plus", foregroundColor: .tabiPrimary) {
            self.store.send(.addCustomPlaceButtonTapped)
        }
    }

    func bookmarkList() -> some View {
        GeometryReader { proxy in
            List {
                Section {
                    if self.store.isLoading {
                        ProgressView()
                            .frame(height: max(proxy.size.height - self.headerHeight, 0))
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                    } else if self.store.filteredBookmarks.isEmpty {
                        BookmarkEmptyState()
                            .frame(height: max(proxy.size.height - self.headerHeight, 0))
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                    } else {
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
                                    Label(Strings.Common.delete, systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 8) {
                        BookmarkCategoryFilterBar(
                            selectedCategory: self.store.selectedCategory
                        ) { category in
                            self.store.send(.categoryFilterTapped(category), animation: .tabiStandard)
                        }

                        TabiLabel(
                            title: Strings.Bookmark.savedCountTitle(self.store.bookmarks.count),
                            style: .captionMBold,
                            color: .tabiTextSecondary
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onGeometryChange(for: CGFloat.self) { headerProxy in
                        headerProxy.size.height
                    } action: { newValue in
                        self.headerHeight = newValue
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 0, for: .scrollContent)
        }
    }
}

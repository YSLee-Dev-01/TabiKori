//
//  BookmarkFeature.swift
//  Presentation
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

@Reducer
public struct BookmarkFeature: Sendable {

    @Dependency(\.bookmarkUseCase) var bookmarkUseCase

    @ObservableState
    public struct State: Equatable {
        var bookmarks: [Bookmark] = []
        var selectedCategory: CategoryType?
        var isLoading: Bool = false
        @Presents var addCustomPlaceState: AddCustomPlaceFeature.State?

        public init() {}

        var filteredBookmarks: [Bookmark] {
            guard let selectedCategory = self.selectedCategory else { return self.bookmarks }
            return self.bookmarks.filter { $0.touristSpot.contentType == selectedCategory }
        }
    }

    public enum Action: Equatable {
        case onAppear
        case categoryFilterTapped(CategoryType?)
        case spotTapped(TouristSpot)
        case deleteSwiped(contentId: String)
        case bookmarksResult([Bookmark])
        case addCustomPlaceButtonTapped
        case addCustomPlace(PresentationAction<AddCustomPlaceFeature.Action>)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return self.fetchBookmarksEffect()

            case .categoryFilterTapped(let category):
                state.selectedCategory = state.selectedCategory == category ? nil : category
                return .none

            case .spotTapped:
                return .none

            case .deleteSwiped(let contentId):
                state.bookmarks.removeAll { $0.id == contentId }
                return self.removeBookmarkEffect(contentId: contentId)

            case .bookmarksResult(let bookmarks):
                state.bookmarks = bookmarks
                state.isLoading = false
                return .none

            case .addCustomPlaceButtonTapped:
                state.addCustomPlaceState = AddCustomPlaceFeature.State()
                return .none

            case .addCustomPlace(.presented(.saveResult(true))):
                state.addCustomPlaceState = nil
                return self.fetchBookmarksEffect()

            case .addCustomPlace:
                return .none
            }
        }
        .ifLet(\.$addCustomPlaceState, action: \.addCustomPlace) {
            AddCustomPlaceFeature()
        }
    }
}

// MARK: - Method

private extension BookmarkFeature {
    func fetchBookmarksEffect() -> Effect<Action> {
        .run { [bookmarkUseCase = self.bookmarkUseCase] send in
            do {
                let bookmarks = try await bookmarkUseCase.fetch()
                await send(.bookmarksResult(bookmarks))
            } catch {
                AppLogger.view.log(.error, "북마크 목록 조회 실패: \(error.localizedDescription)")
                await send(.bookmarksResult([]))
            }
        }
    }

    func removeBookmarkEffect(contentId: String) -> Effect<Action> {
        .run { [bookmarkUseCase = self.bookmarkUseCase] send in
            do {
                try await bookmarkUseCase.remove(contentId: contentId)
            } catch {
                AppLogger.view.log(.error, "북마크 삭제 실패: \(error.localizedDescription)")
                await send(.onAppear)
            }
        }
    }
}

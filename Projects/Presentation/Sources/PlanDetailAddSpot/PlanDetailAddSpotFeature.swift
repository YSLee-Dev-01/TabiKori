//
//  PlanDetailAddSpotFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/5/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// PlanDetail "+" 버튼으로 여는 하단 시트. Step 1(관광지 검색/즐겨찾기에서 스팟 선택)과
/// Step 2(시작/종료 시각 입력)를 같은 시트 안에서 전환한다
@Reducer
public struct PlanDetailAddSpotFeature: Sendable {

    @Dependency(\.touristSpotUseCase) var touristSpotUseCase
    @Dependency(\.bookmarkUseCase) var bookmarkUseCase
    @Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase
    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
        let planId: UUID
        let dayIndex: Int
        let date: Date
        var step: Step = .selectingSpot
        var tab: Tab = .search
        var searchKeyword: String = ""
        var searchResults: [TouristSpot] = []
        var isSearchLoading: Bool = false
        var hasSearched: Bool = false
        var bookmarks: [Bookmark] = []
        var isBookmarkLoading: Bool = false
        var selectedSpot: TouristSpot? = nil
        var startTime: Date = Date()
        var endTime: Date = Date()
        var isSaving: Bool = false
        fileprivate let existingDetail: TravelPlanDetail?

        public init(planId: UUID, dayIndex: Int, date: Date, detail: TravelPlanDetail?) {
            self.planId = planId
            self.dayIndex = dayIndex
            self.date = date
            self.existingDetail = detail
        }

        public enum Step: Equatable {
            case selectingSpot
            case configuringTime
        }

        public enum Tab: Equatable {
            case search
            case bookmark
        }

        var durationMinutes: Int {
            let minutes = Calendar.current.dateComponents([.minute], from: self.startTime, to: self.endTime).minute ?? 0
            return max(minutes, 0)
        }

        var isSaveEnabled: Bool {
            self.endTime > self.startTime
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case tabSelected(State.Tab)
        case searchSubmitted
        case spotRowTapped(TouristSpot)
        case backButtonTapped
        case closeButtonTapped
        case saveButtonTapped
        case searchResultsResult([TouristSpot])
        case bookmarksResult([Bookmark])
        case saveFailed
        case spotAdded
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.searchKeyword):
                guard state.searchKeyword.isEmpty else { return .none }
                state.searchResults = []
                state.hasSearched = false
                return .cancel(id: CancelID.search)

            case .binding:
                return .none

            case .tabSelected(let tab):
                guard state.tab != tab else { return .none }
                state.tab = tab
                guard tab == .bookmark else { return .none }
                state.isBookmarkLoading = true
                return self.fetchBookmarksEffect()
                    .cancellable(id: CancelID.fetchBookmarks, cancelInFlight: true)

            case .searchSubmitted:
                let keyword = state.searchKeyword.trimmingCharacters(in: .whitespaces)
                guard keyword.isEmpty == false else { return .none }
                state.isSearchLoading = true
                state.hasSearched = true
                return self.searchEffect(keyword: keyword)
                    .cancellable(id: CancelID.search, cancelInFlight: true)

            case .spotRowTapped(let spot):
                state.selectedSpot = spot
                let range = TravelPlanDetailSpotScheduler.defaultTimeRange(
                    dayIndex: state.dayIndex,
                    date: state.date,
                    existingDetail: state.existingDetail
                )
                state.startTime = range.start
                state.endTime = range.end
                state.step = .configuringTime
                return .none

            case .backButtonTapped:
                state.selectedSpot = nil
                state.step = .selectingSpot
                return .none

            case .closeButtonTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }

            case .saveButtonTapped:
                guard
                    state.isSaveEnabled,
                    state.isSaving == false,
                    let spot = state.selectedSpot
                else { return .none }
                state.isSaving = true
                let order = TravelPlanDetailSpotScheduler.nextOrder(dayIndex: state.dayIndex, existingDetail: state.existingDetail)
                let detailSpot = TravelPlanDetailSpot(
                    id: UUID(),
                    dayIndex: state.dayIndex,
                    order: order,
                    category: spot.contentType,
                    title: spot.japaneseTitle,
                    subtitle: spot.koreanTitle,
                    startTime: state.startTime,
                    durationMinutes: state.durationMinutes,
                    contentId: spot.id,
                    coordinate: spot.coordinate,
                    thumbnailURLString: spot.thumbnailURLString,
                    isCustom: spot.isCustom,
                    address: spot.address
                )
                return self.saveEffect(planId: state.planId, spot: detailSpot)

            case .searchResultsResult(let results):
                state.searchResults = results
                state.isSearchLoading = false
                return .none

            case .bookmarksResult(let bookmarks):
                state.bookmarks = bookmarks
                state.isBookmarkLoading = false
                return .none

            case .saveFailed:
                state.isSaving = false
                return .none

            case .spotAdded:
                return .none
            }
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case search
    case fetchBookmarks
}

// MARK: - Method

private extension PlanDetailAddSpotFeature {
    func searchEffect(keyword: String) -> Effect<Action> {
        .run { [touristSpotUseCase = self.touristSpotUseCase] send in
            do {
                let results = try await touristSpotUseCase.searchByKeyword(keyword: keyword, pageNo: 1)
                await send(.searchResultsResult(results))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "관광지 키워드 검색 실패: \(error.localizedDescription)")
                await send(.searchResultsResult([]))
            }
        }
    }

    func fetchBookmarksEffect() -> Effect<Action> {
        .run { [bookmarkUseCase = self.bookmarkUseCase] send in
            do {
                let bookmarks = try await bookmarkUseCase.fetch()
                await send(.bookmarksResult(bookmarks))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "북마크 목록 조회 실패: \(error.localizedDescription)")
                await send(.bookmarksResult([]))
            }
        }
    }

    func saveEffect(planId: UUID, spot: TravelPlanDetailSpot) -> Effect<Action> {
        .run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in
            do {
                try await travelPlanDetailUseCase.add(TravelPlanDetail(planId: planId, spots: [spot]))
                await send(.spotAdded)
            } catch {
                AppLogger.view.log(.error, "일정에 스팟 추가 실패: \(error.localizedDescription)")
                await send(.saveFailed)
            }
        }
    }
}

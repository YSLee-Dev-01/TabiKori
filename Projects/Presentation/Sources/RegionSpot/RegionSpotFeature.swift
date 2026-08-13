//
//  RegionSpotFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/10/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain
import Resource

public enum RegionSpotLoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed
}

public enum RegionSpotContentTab: String, CaseIterable, Equatable, Sendable {
    case spot
    case festival

    var label: String {
        switch self {
        case .spot: return Strings.RegionSpot.spotTabLabel
        case .festival: return Strings.RegionSpot.festivalTabLabel
        }
    }
}

@Reducer
public struct RegionSpotFeature: Sendable {

    @Dependency(\.touristSpotUseCase) var touristSpotUseCase
    @Dependency(\.festivalUseCase) var festivalUseCase

    @ObservableState
    public struct State: Equatable {
        let region: KoreanRegion
        var selectedContentTab: RegionSpotContentTab = .spot
        var selectedCategory: CategoryType = .sightseeing
        var spots: [TouristSpot] = []
        var spotLoadState: RegionSpotLoadState = .idle
        var festivals: [Festival] = []
        var festivalLoadState: RegionSpotLoadState = .idle

        fileprivate var hasLoadedInitialContent: Bool = false
        @Presents var addPlanState: AddTravelPlanFeature.State?

        public init(region: KoreanRegion) {
            self.region = region
        }
    }

    public enum Action: Equatable {
        case onAppear
        case contentTabSelected(RegionSpotContentTab)
        case categoryTabTapped(CategoryType)
        case retryButtonTapped
        case spotTapped(TouristSpot)
        case festivalTapped(Festival)
        case addPlanButtonTapped
        case spotsResult(CategoryType, [TouristSpot])
        case spotsFailed(CategoryType)
        case festivalsResult([Festival])
        case festivalsFailed
        case addPlan(PresentationAction<AddTravelPlanFeature.Action>)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasLoadedInitialContent == false else { return .none }
                state.hasLoadedInitialContent = true
                state.spotLoadState = .loading
                state.festivalLoadState = .loading
                return .merge(
                    self.fetchSpotsEffect(state: state),
                    self.fetchFestivalsEffect(state: state)
                )

            case .contentTabSelected(let tab):
                guard state.selectedContentTab != tab else { return .none }
                state.selectedContentTab = tab
                return .none

            case .categoryTabTapped(let category):
                guard state.selectedCategory != category else { return .none }
                state.selectedCategory = category
                state.spotLoadState = .loading
                return self.fetchSpotsEffect(state: state)

            case .retryButtonTapped:
                state.spotLoadState = .loading
                state.festivalLoadState = .loading
                return .merge(
                    self.fetchSpotsEffect(state: state),
                    self.fetchFestivalsEffect(state: state)
                )

            case .spotTapped, .festivalTapped:
                return .none

            case .addPlanButtonTapped:
                var addPlanState = AddTravelPlanFeature.State()
                addPlanState.selectedRegion = state.region
                if let emoji = state.region.emoji {
                    addPlanState.emojiText = emoji
                }
                state.addPlanState = addPlanState
                return .none

            case .spotsResult(let category, let spots):
                guard state.selectedCategory == category else { return .none }
                state.spots = spots
                state.spotLoadState = .loaded
                return .none

            case .spotsFailed(let category):
                guard state.selectedCategory == category else { return .none }
                state.spotLoadState = .failed
                return .none

            case .festivalsResult(let festivals):
                state.festivals = festivals
                state.festivalLoadState = .loaded
                return .none

            case .festivalsFailed:
                state.festivalLoadState = .failed
                return .none

            case .addPlan(.presented(.saveResult(true))):
                state.addPlanState = nil
                return .none

            case .addPlan:
                return .none
            }
        }
        .ifLet(\.$addPlanState, action: \.addPlan) {
            AddTravelPlanFeature()
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case regionSpots
    case regionFestivals
}

// MARK: - Method

private extension RegionSpotFeature {
    func fetchSpotsEffect(state: State) -> Effect<Action> {
        let region = state.region
        let category = state.selectedCategory

        return .run { [touristSpotUseCase = self.touristSpotUseCase] send in
            do {
                let spots = try await touristSpotUseCase.fetchRegionSpots(
                    region: region,
                    contentType: category,
                    pageNo: 1
                )
                await send(.spotsResult(category, spots))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "지역 관광지 조회 취소됨")
                    return
                }
                AppLogger.view.log(.error, "지역 관광지 조회 실패: \(error.localizedDescription)")
                await send(.spotsFailed(category))
            }
        }
        .cancellable(id: CancelID.regionSpots, cancelInFlight: true)
    }

    func fetchFestivalsEffect(state: State) -> Effect<Action> {
        let region = state.region

        return .run { [festivalUseCase = self.festivalUseCase] send in
            do {
                let festivals = try await festivalUseCase.fetchRegionFestivals(
                    startDate: Date(),
                    endDate: nil,
                    region: region,
                    pageNo: 1
                )
                await send(.festivalsResult(festivals))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "지역 축제 조회 취소됨")
                    return
                }
                AppLogger.view.log(.error, "지역 축제 조회 실패: \(error.localizedDescription)")
                await send(.festivalsFailed)
            }
        }
        .cancellable(id: CancelID.regionFestivals, cancelInFlight: true)
    }
}

//
//  TabBarFeature.swift
//  Presentation
//
//  Created by 이윤수 on 6/16/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct TabBarFeature {

    @ObservableState
    public struct State: Equatable {
        var selectedTab: AppTab = .home
        
        var homeState: HomeFeature.State = .init()
        var mapState: MapFeature.State = .init()
        var planState: PlanFeature.State = .init()
        var bookmarkState: BookmarkFeature.State = .init()
        var toolboxState: TravelItemsFeature.State = .init()

        var path = StackState<StackPath.State>()

        public init() {}
    }

    public enum Action: Equatable {
        case tabSelected(AppTab)
        case home(HomeFeature.Action)
        case map(MapFeature.Action)
        case plan(PlanFeature.Action)
        case bookmark(BookmarkFeature.Action)
        case toolbox(TravelItemsFeature.Action)
        case path(StackActionOf<StackPath>)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.homeState, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.mapState, action: \.map) {
            MapFeature()
        }
        Scope(state: \.bookmarkState, action: \.bookmark) {
            BookmarkFeature()
        }
        Scope(state: \.planState, action: \.plan) {
            PlanFeature()
        }
        Scope(state: \.toolboxState, action: \.toolbox) {
            TravelItemsFeature()
        }

        Reduce { state, action in
            switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none

            case .home(.nearbySpotTapped(let spot)):
                state.path.append(.detail(DetailFeature.State(touristSpot: spot)))
                return .none

            case .home(.searchBarTapped):
                state.selectedTab = .map
                return .send(.map(.searchFieldTapped))

            case .home(.categoryTapped):
                state.selectedTab = .map
                return .none

            case .home(.categoryCoordinateResolved(let category, let coordinate)):
                guard state.selectedTab == .map else { return .none }
                return .send(.map(.categorySelected(category, coordinate: coordinate)))

            case .home(.festivalMoreButtonTapped):
                state.path.append(.festival(FestivalFeature.State()))
                return .none

            case .home(.festivalTapped(let festival)):
                state.path.append(.detail(DetailFeature.State(touristSpot: festival.touristSpot)))
                return .none

            case .home(.regionCardTapped(let region)):
                state.path.append(.region(RegionSpotFeature.State(region: region)))
                return .none

            case .home(.settingButtonTapped):
                state.path.append(.setting(SettingFeature.State()))
                return .none

            case .home(.moveToPlanButtonTapped):
                state.selectedTab = .plan
                if let matchedPlan = state.homeState.ongoingMatchedPlan {
                    state.path.append(.planDetail(PlanDetailFeature.State(
                        plan: matchedPlan,
                        initialDayIndex: state.homeState.ongoingMatchedPlanDayIndex
                    )))
                }
                return .none

            case .home:
                return .none

            case .map(.searchResultTapped(let spot)):
                state.path.append(.detail(DetailFeature.State(touristSpot: spot)))
                return .none

            case .map:
                return .none

            case .bookmark(.spotTapped(let spot)):
                state.path.append(.detail(DetailFeature.State(touristSpot: spot)))
                return .none

            case .bookmark:
                return .none

            case .toolbox:
                return .none

            case .plan(.planTapped(let plan)):
                state.path.append(.planDetail(PlanDetailFeature.State(plan: plan)))
                return .none

            case .plan:
                return .none

            case .path(.element(id: _, action: .planDetail(.spotRowTapped(let spot)))):
                let touristSpot = TouristSpot(
                    id: spot.contentId,
                    title: spot.title,
                    thumbnailURLString: spot.thumbnailURLString,
                    distanceMeters: nil,
                    contentType: spot.category,
                    coordinate: spot.coordinate,
                    isCustom: spot.isCustom,
                    isStation: spot.isStation,
                    address: spot.address
                )
                state.path.append(.detail(DetailFeature.State(touristSpot: touristSpot)))
                return .none

            case .path(.element(id: _, action: .detail(.isBookmarkedResult))):
                return .send(.bookmark(.onAppear))

            case .path(.element(id: _, action: .setting(.resetCompleted))):
                return .merge(.send(.bookmark(.onAppear)), .send(.plan(.onAppear)))

            case .path(.element(id: let id, action: .detail(.photoCellTapped(let index)))):
                guard case .detail(let detailState) = state.path[id: id] else { return .none }
                state.path.append(.photoViewer(PhotoViewerFeature.State(
                    images: detailState.images,
                    startIndex: index,
                    title: detailState.detail.japaneseTitle
                )))
                return .none

            case .path(.element(id: let id, action: .planDetail(.travelItemsButtonTapped))):
                guard case .planDetail(let planDetailState) = state.path[id: id] else { return .none }
                state.path.append(.planTravelItems(PlanTravelItemsFeature.State(plan: planDetailState.plan)))
                return .none

            case .path(.element(id: _, action: .festival(.festivalTapped(let festival)))):
                state.path.append(.detail(DetailFeature.State(touristSpot: festival.touristSpot)))
                return .none

            case .path(.element(id: _, action: .region(.spotTapped(let spot)))):
                state.path.append(.detail(DetailFeature.State(touristSpot: spot)))
                return .none

            case .path(.element(id: _, action: .region(.festivalTapped(let festival)))):
                state.path.append(.detail(DetailFeature.State(touristSpot: festival.touristSpot)))
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

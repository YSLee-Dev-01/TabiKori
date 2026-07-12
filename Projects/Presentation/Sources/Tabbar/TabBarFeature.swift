//
//  TabBarFeature.swift
//  Presentation
//
//  Created by 이윤수 on 6/16/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct TabBarFeature {

    @ObservableState
    public struct State: Equatable {
        var selectedTab: AppTab = .home
        
        var homeState: HomeFeature.State = .init()
        var mapState: MapState = .init()
        var planState: PlanState = .init()
        var saveState: SaveState = .init()
        var searchState: SearchState = .init()

        // 임시
        public struct MapState: Equatable { public init() {} }
        public struct PlanState: Equatable { public init() {} }
        public struct SaveState: Equatable { public init() {} }
        public struct SearchState: Equatable { public init() {} }

        var path = StackState<StackPath.State>()

        public init() {}
    }

    public enum Action: Equatable {
        case tabSelected(AppTab)
        case home(HomeFeature.Action)
        case path(StackActionOf<StackPath>)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.homeState, action: \.home) {
            HomeFeature()
        }

        Reduce { state, action in
            switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none

            case .home(.nearbySpotTapped(let spot)):
                state.path.append(.detail(DetailFeature.State(touristSpot: spot)))
                return .none

            case .home:
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

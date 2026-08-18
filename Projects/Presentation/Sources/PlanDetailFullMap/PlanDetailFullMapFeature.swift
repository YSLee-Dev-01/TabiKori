//
//  PlanDetailFullMapFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain

/// PlanDetail 지도 섹션의 "전체화면 보기" 버튼으로 push되는 화면.
/// 상단에 전체화면 지도, 하단에 해당 일자 일정을 가로 스크롤 카드로 보여준다. 카드 탭 시 지도 카메라가 포커스된다
@Reducer
public struct PlanDetailFullMapFeature: Sendable {

    @ObservableState
    public struct State: Equatable {
        let dayTitle: String
        let dateTitle: String
        let spots: [TravelPlanDetailSpot]
        var selectedSpotId: UUID?
        var focusToken: Int = 0

        public init(dayTitle: String, dateTitle: String, spots: [TravelPlanDetailSpot]) {
            self.dayTitle = dayTitle
            self.dateTitle = dateTitle
            self.spots = spots
            self.selectedSpotId = spots.first?.id
        }
    }

    public enum Action: Equatable {
        case cardTapped(UUID)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .cardTapped(let id):
                guard state.selectedSpotId != id else { return .none }
                state.selectedSpotId = id
                state.focusToken += 1
                return .none
            }
        }
    }
}

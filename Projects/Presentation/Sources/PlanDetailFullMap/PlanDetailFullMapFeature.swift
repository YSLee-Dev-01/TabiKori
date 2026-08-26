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
/// 배경 전체화면 지도 위에 좌측 세로 스팟 리스트를 겹쳐 보여준다. 리스트 탭 또는 스크롤 정착 시 지도 카메라가 포커스된다
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

    // 리스트 행 탭과 스크롤 스냅 정착 모두에서 발생하므로 "카드 탭" 전용이 아닌 spotSelected로 명명 (기존 cardTapped에서 변경)
    public enum Action: Equatable {
        case spotSelected(UUID)
        /// 카드를 직접 탭한 경우에만 보내는 액션. 이미 선택된 스팟을 다시 탭하면 재포커스 대신
        /// DetailView 진입 델리게이트를 방출한다. 스크롤 스냅 정착·마커 탭은 spotSelected를 그대로 사용해
        /// 우연히 같은 스팟에 재정착해도 의도치 않게 DetailView로 넘어가지 않는다
        case cardTapped(UUID)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case spotReselected(TravelPlanDetailSpot)
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .spotSelected(let id):
                guard state.selectedSpotId != id else { return .none }
                state.selectedSpotId = id
                state.focusToken += 1
                return .none

            case .cardTapped(let id):
                guard state.selectedSpotId != id else {
                    guard let spot = state.spots.first(where: { $0.id == id }) else { return .none }
                    return .send(.delegate(.spotReselected(spot)))
                }
                return .send(.spotSelected(id))

            case .delegate:
                return .none
            }
        }
    }
}

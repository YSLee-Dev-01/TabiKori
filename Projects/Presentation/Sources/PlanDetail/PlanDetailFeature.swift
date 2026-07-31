//
//  PlanDetailFeature.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

/// 일정 상세 화면 스켈레톤. 목록에서 넘겨받은 `id`로 Detail 전용 데이터를 조회하는 실제 화면은 이후 별도 기능에서 구현한다
@Reducer
public struct PlanDetailFeature: Sendable {

    @ObservableState
    public struct State: Equatable {
        let id: UUID

        public init(id: UUID) {
            self.id = id
        }
    }

    public enum Action: Equatable {}

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { _, _ in .none }
    }
}

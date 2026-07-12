//
//  DetailFeature.swift
//  Presentation
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain

@Reducer
public struct DetailFeature {

    @ObservableState
    public struct State: Equatable {
        let touristSpot: TouristSpot
    }

    public enum Action: Equatable {

    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            default: return .none
            }
        }
    }
}

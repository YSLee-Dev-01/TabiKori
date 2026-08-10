//
//  RegionSpotFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/10/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain

@Reducer
public struct RegionSpotFeature: Sendable {

    @ObservableState
    public struct State: Equatable {
        let region: KoreanRegion

        public init(region: KoreanRegion) {
            self.region = region
        }
    }

    public enum Action: Equatable {
        case onAppear
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}

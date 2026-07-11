//
//  RootFeature.swift
//  Presentation
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain

@Reducer
public struct RootFeature {

    @ObservableState
    public struct State: Equatable {
        var tabBarState: TabBarFeature.State? = nil

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case onboardingChecking
        case testBtnTapped
        case tabBar(TabBarFeature.Action)
    }
    
    @Dependency(\.onboardingUseCase) var onboardingUsecase
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.tabBarState == nil else { return .none }
                return .send(.onboardingChecking)

            case .onboardingChecking:
                if onboardingUsecase.isCompleted() {
                    state.tabBarState = .init()
                }
                return .none
                
            case .testBtnTapped:
                onboardingUsecase.markAsCompleted()
                return .send(.onboardingChecking)

            case .tabBar:
                return .none
            }
        }
        .ifLet(\.tabBarState, action: \.tabBar) {
            TabBarFeature()
        }
    }
}

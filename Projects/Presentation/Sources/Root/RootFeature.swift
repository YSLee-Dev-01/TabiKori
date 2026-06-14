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
        var text = "RootView"
        var isOnboardingCompleted: Bool = false
        
        public init() {
            
        }
    }
    
    public enum Action: Equatable {
        case onAppear
        case testBtnTapped
    }
    
    @Dependency(\.onboardingUseCase) var onboardingUsecase
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isOnboardingCompleted = onboardingUsecase.isCompleted()
                return .none
                
            case .testBtnTapped:
                onboardingUsecase.markAsCompleted()
                return .none
            }
        }
    }
}

//
//  HomeFeature.swift
//  Presentation
//
//  Created by 이윤수 on 6/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct HomeFeature {
    
    @ObservableState
    public struct State: Equatable {
        var text = "Home"
    }
    
    public enum Action: Equatable {
        
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            default: .none
            }
        }
    }
}

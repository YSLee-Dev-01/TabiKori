//
//  AppDIContainer.swift
//  DIContainer
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Presentation
import Domain
import Data

@MainActor
public final class AppDIContainer {
    
    // MARK: - init
    
    public init() {}
    
    // MARK: - Home
    
    public func makeHomeView() -> HomeView {
        return HomeView(store: self.homeStore)
    }
    
    private lazy var homeStore: StoreOf<HomeFeature> = .init(
        initialState: .init(),
        reducer: { HomeFeature() }
    )
    
    // MARK: - Root
    
    public func makeRootView() -> HomeView {
        return HomeView(store: self.homeStore)
    }
    
    private lazy var rootStore: StoreOf<RootFeature> = .init(
        initialState: .init(),
        reducer: { RootFeature() }
    )
}

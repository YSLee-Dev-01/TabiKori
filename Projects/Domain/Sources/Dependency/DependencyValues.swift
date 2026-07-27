//
//  DependencyValues.swift
//  Domain
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

extension DependencyValues {
    public var onboardingUseCase: OnboardingUseCaseProtocol {
        get {self[OnboardingUseCaseDependencyKey.self]}
        set {self[OnboardingUseCaseDependencyKey.self] = newValue}
    }
    
    public var locationUseCase: LocationUseCaseProtocol {
        get {self[LocationUseCaseDependencyKey.self]}
        set {self[LocationUseCaseDependencyKey.self] = newValue}
    }

    public var exchangeRateUseCase: ExchangeRateUseCaseProtocol {
        get {self[ExchangeRateUseCaseDependencyKey.self]}
        set {self[ExchangeRateUseCaseDependencyKey.self] = newValue}
    }

    public var touristSpotUseCase: TouristSpotUseCaseProtocol {
        get {self[TouristSpotUseCaseDependencyKey.self]}
        set {self[TouristSpotUseCaseDependencyKey.self] = newValue}
    }

    public var naverMapUseCase: NaverMapUseCaseProtocol {
        get {self[NaverMapUseCaseDependencyKey.self]}
        set {self[NaverMapUseCaseDependencyKey.self] = newValue}
    }

    public var searchHistoryUseCase: SearchHistoryUseCaseProtocol {
        get {self[SearchHistoryUseCaseDependencyKey.self]}
        set {self[SearchHistoryUseCaseDependencyKey.self] = newValue}
    }
}

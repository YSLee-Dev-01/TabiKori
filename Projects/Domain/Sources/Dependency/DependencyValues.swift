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

    public var bookmarkUseCase: BookmarkUseCaseProtocol {
        get {self[BookmarkUseCaseDependencyKey.self]}
        set {self[BookmarkUseCaseDependencyKey.self] = newValue}
    }

    public var travelPlanUseCase: TravelPlanUseCaseProtocol {
        get {self[TravelPlanUseCaseDependencyKey.self]}
        set {self[TravelPlanUseCaseDependencyKey.self] = newValue}
    }

    public var travelPlanDetailUseCase: TravelPlanDetailUseCaseProtocol {
        get {self[TravelPlanDetailUseCaseDependencyKey.self]}
        set {self[TravelPlanDetailUseCaseDependencyKey.self] = newValue}
    }

    public var travelPlanShareUseCase: TravelPlanShareUseCaseProtocol {
        get {self[TravelPlanShareUseCaseDependencyKey.self]}
        set {self[TravelPlanShareUseCaseDependencyKey.self] = newValue}
    }

    public var festivalUseCase: FestivalUseCaseProtocol {
        get {self[FestivalUseCaseDependencyKey.self]}
        set {self[FestivalUseCaseDependencyKey.self] = newValue}
    }

    public var naverGeocodingUseCase: NaverGeocodingUseCaseProtocol {
        get {self[NaverGeocodingUseCaseDependencyKey.self]}
        set {self[NaverGeocodingUseCaseDependencyKey.self] = newValue}
    }

    public var dataResetUseCase: DataResetUseCaseProtocol {
        get {self[DataResetUseCaseDependencyKey.self]}
        set {self[DataResetUseCaseDependencyKey.self] = newValue}
    }
}

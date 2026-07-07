//
//  HomeFeature.swift
//  Presentation
//
//  Created by 이윤수 on 6/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

// MARK: - HomeFeature

@Reducer
public struct HomeFeature: Sendable {

    @Dependency(\.locationUseCase) var locationUseCase
    @Dependency(\.exchangeRateUseCase) var exchangeRateUseCase

    @ObservableState
    public struct State: Equatable {
        var currentDate: String = Date().homeDateTitle
        var locationStatus: LocationAuthorizationStatus = .denied
        var currentRegion: TravelRegion = .unsupported
        var nearbyTouristSpots: [TouristSpot] = TouristSpot.touristDummies
        var nearbyRestaurants: [TouristSpot] = TouristSpot.restaurantDummies
        var isLoadingTouristSpots: Bool = false
        var isLoadingRestaurants: Bool = false
        var krwAmountText: String = "1000"
        var jpyAmountText: String = "0"
        fileprivate var krwToJPYRate: Double = 0

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case requestLocationPermission
        case locationPermissionResult(LocationAuthorizationStatus)
        case regionResult(TravelRegion)
        case exchangeRateResult(Double)
        case planCreateButtonTapped
        case nearbySpotTapped(TouristSpot)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.krwAmountText):
                if let krw = Double(state.krwAmountText) {
                    state.jpyAmountText = String(format: "%.1f", krw * state.krwToJPYRate)
                }
                return .none

            case .binding(\.jpyAmountText):
                if let jpy = Double(state.jpyAmountText), state.krwToJPYRate != 0 {
                    state.krwAmountText = String(format: "%.0f", jpy / state.krwToJPYRate)
                }
                return .none

            case .binding:
                return .none

            case .onAppear:
                state.locationStatus = self.locationUseCase.checkAuthorization()

                let locationEffect: Effect<Action>
                switch state.locationStatus {
                case .undetermined:
                    locationEffect = .send(.requestLocationPermission)

                case .allowed:
                    locationEffect = .run { [locationUseCase = self.locationUseCase] send in
                        try? await Task.sleep(for: .seconds(1))
                        do {
                            let region = try await locationUseCase.fetchCurrentRegion()
                            await send(.regionResult(region))
                        } catch {
                            AppLogger.view.log(.error, "현재 지역 조회 실패: \(error.localizedDescription)")
                        }
                    }

                case .denied:
                    locationEffect = .none
                }

                let exchangeRateEffect: Effect<Action> = .run { [exchangeRateUseCase = self.exchangeRateUseCase] send in
                    do {
                        let rate = try await exchangeRateUseCase.fetchKRWToJPYRate()
                        await send(.exchangeRateResult(rate))
                    } catch {
                        AppLogger.view.log(.error, "환율 조회 실패: \(error.localizedDescription)")
                    }
                }

                return .merge(locationEffect, exchangeRateEffect)

            case .requestLocationPermission:
                return .run { send in
                    let result = await self.locationUseCase.requestAuthorization()
                    await send(.locationPermissionResult(result))
                }

            case .locationPermissionResult(let status):
                state.locationStatus = status
                return .none

            case .regionResult(let region):
                state.currentRegion = region
                return .none

            case .exchangeRateResult(let rate):
                state.krwToJPYRate = rate
                if let krw = Double(state.krwAmountText) {
                    state.jpyAmountText = String(format: "%.1f", krw * rate)
                }
                return .none

            case .planCreateButtonTapped:
                return .none

            case .nearbySpotTapped:
                return .none
            }
        }
    }
}

// MARK: - TouristSpot Dummy

private extension TouristSpot {
    static let touristDummies: [TouristSpot] = [
        TouristSpot(id: "1", title: "景福宮", thumbnailURL: nil, distanceMeters: 320, contentType: .sightseeing),
        TouristSpot(id: "2", title: "ソウル市立美術館", thumbnailURL: nil, distanceMeters: 1200, contentType: .sightseeing),
        TouristSpot(id: "3", title: "北村韓屋村", thumbnailURL: nil, distanceMeters: 680, contentType: .sightseeing),
    ]

    static let restaurantDummies: [TouristSpot] = [
        TouristSpot(id: "4", title: "土俗村サムゲタン", thumbnailURL: nil, distanceMeters: 430, contentType: .food),
        TouristSpot(id: "5", title: "明洞餃子", thumbnailURL: nil, distanceMeters: 210, contentType: .food),
        TouristSpot(id: "6", title: "広蔵市場", thumbnailURL: nil, distanceMeters: 890, contentType: .food),
    ]
}

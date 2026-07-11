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
    @Dependency(\.touristSpotUseCase) var touristSpotUseCase

    private let nearbySpotRadiusMeters = 10000

    @ObservableState
    public struct State: Equatable {
        var currentDate: String = Date().homeDateTitle
        var locationStatus: LocationAuthorizationStatus = .denied
        var currentRegion: TravelRegion = .unsupported
        var nearbyTouristSpots: [TouristSpot] = []
        var nearbyRestaurants: [TouristSpot] = []
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
        case nearbyTouristSpotsResult([TouristSpot])
        case nearbyRestaurantsResult([TouristSpot])
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
                guard region.isKorea else { return .none }

                state.isLoadingTouristSpots = true
                state.isLoadingRestaurants = true

                return .run { [
                    locationUseCase = self.locationUseCase,
                    touristSpotUseCase = self.touristSpotUseCase,
                    radius = self.nearbySpotRadiusMeters
                ] send in
                    do {
                        let coordinate = try await locationUseCase.fetchCurrentCoordinate()

                        async let touristSpots = touristSpotUseCase.fetchNearbySpots(
                            contentType: .sightseeing,
                            coordinate: coordinate,
                            radiusMeters: radius
                        )
                        async let restaurants = touristSpotUseCase.fetchNearbySpots(
                            contentType: .food,
                            coordinate: coordinate,
                            radiusMeters: radius
                        )

                        await send(.nearbyTouristSpotsResult(try await touristSpots))
                        await send(.nearbyRestaurantsResult(try await restaurants))
                    } catch {
                        await send(.nearbyTouristSpotsResult([]))
                        await send(.nearbyRestaurantsResult([]))
                        AppLogger.view.log(.error, "주변 관광정보 조회 실패: \(error.localizedDescription)")
                    }
                }

            case .exchangeRateResult(let rate):
                state.krwToJPYRate = rate
                if let krw = Double(state.krwAmountText) {
                    state.jpyAmountText = String(format: "%.1f", krw * rate)
                }
                return .none

            case .nearbyTouristSpotsResult(let spots):
                state.nearbyTouristSpots = spots
                state.isLoadingTouristSpots = false
                return .none

            case .nearbyRestaurantsResult(let spots):
                state.nearbyRestaurants = spots
                state.isLoadingRestaurants = false
                return .none

            case .planCreateButtonTapped:
                return .none

            case .nearbySpotTapped:
                return .none
            }
        }
    }
}

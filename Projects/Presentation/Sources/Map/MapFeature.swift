//
//  MapFeature.swift
//  Presentation
//
//  Created by 이윤수 on 7/21/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

// MARK: - MapFeature

@Reducer
public struct MapFeature: Sendable {

    @Dependency(\.locationUseCase) var locationUseCase

    private let seoulCityHallLatitude = 37.5666102
    private let seoulCityHallLongitude = 126.9783881

    @ObservableState
    public struct State: Equatable {
        var centerLatitude: Double = 37.5666102
        var centerLongitude: Double = 126.9783881
        var showsUserLocation: Bool = false
        var hasResolvedInitialCenter: Bool = false
        var locationStatus: LocationAuthorizationStatus = .undetermined
        var isSearching: Bool = false
        var searchQuery: String = ""
        var panelStage: MapPanelStage = .half
        fileprivate var hasLoadedInitial: Bool = false

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case searchFieldTapped
        case searchCancelTapped
        case mapDragged
        case searchSubmitted
        case panelDragEnded(MapPanelStage)
        case requestLocationPermission
        case locationPermissionResult(LocationAuthorizationStatus)
        case coordinateResult(Coordinate)
        case fallbackToSeoul
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .searchFieldTapped:
                state.isSearching = true
                state.panelStage = .half
                return .none

            case .searchCancelTapped:
                state.isSearching = false
                state.searchQuery = ""
                state.panelStage = .half
                return .none

            case .mapDragged:
                state.panelStage = .collapsed
                return .none

            case .searchSubmitted:
                state.panelStage = .full
                return .none

            case .panelDragEnded(let stage):
                state.panelStage = stage
                return .none

            case .onAppear:
                guard state.hasLoadedInitial == false else { return .none }
                state.hasLoadedInitial = true
                state.locationStatus = self.locationUseCase.checkAuthorization()

                switch state.locationStatus {
                case .undetermined:
                    return .send(.requestLocationPermission)

                case .allowed:
                    return self.fetchCoordinateEffect()

                case .denied:
                    return .send(.fallbackToSeoul)
                }

            case .requestLocationPermission:
                return .run { [locationUseCase = self.locationUseCase] send in
                    let result = await locationUseCase.requestAuthorization()
                    await send(.locationPermissionResult(result))
                }

            case .locationPermissionResult(let status):
                state.locationStatus = status
                guard status == .allowed else { return .send(.fallbackToSeoul) }
                return self.fetchCoordinateEffect()

            case .coordinateResult(let coordinate):
                state.centerLatitude = coordinate.latitude
                state.centerLongitude = coordinate.longitude
                state.showsUserLocation = true
                state.hasResolvedInitialCenter = true
                return .none

            case .fallbackToSeoul:
                state.centerLatitude = self.seoulCityHallLatitude
                state.centerLongitude = self.seoulCityHallLongitude
                state.showsUserLocation = false
                state.hasResolvedInitialCenter = true
                return .none
            }
        }
    }
}

// MARK: - Method

private extension MapFeature {
    func fetchCoordinateEffect() -> Effect<Action> {
        .run { [locationUseCase = self.locationUseCase] send in
            do {
                let coordinate = try await locationUseCase.fetchCurrentCoordinate()
                await send(.coordinateResult(coordinate))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "좌표 조회 취소됨")
                    return
                }
                await send(.fallbackToSeoul)
                AppLogger.view.log(.error, "현재 좌표 조회 실패: \(error.localizedDescription)")
            }
        }
    }
}

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
    @Dependency(\.touristSpotUseCase) var touristSpotUseCase

    private let seoulCityHallLatitude = 37.5666102
    private let seoulCityHallLongitude = 126.9783881
    private let searchPageSize = 50

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
        var searchResults: [TouristSpot] = []
        var isSearchLoading: Bool = false
        var isSearchNextPageLoading: Bool = false
        fileprivate var hasLoadedInitial: Bool = false
        fileprivate var searchPage: Int = 1
        fileprivate var hasMoreSearchResults: Bool = true

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case searchFieldTapped
        case searchCancelTapped
        case mapDragged
        case searchSubmitted
        case searchResultTapped(TouristSpot)
        case searchNextPageTriggered
        case panelDragEnded(MapPanelStage)
        case requestLocationPermission
        case locationPermissionResult(LocationAuthorizationStatus)
        case coordinateResult(Coordinate)
        case fallbackToSeoul
        case searchResultsResult([TouristSpot])
        case searchNextPageResultsResult([TouristSpot])
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
                state.searchResults = []
                state.isSearchLoading = false
                state.isSearchNextPageLoading = false
                state.searchPage = 1
                state.hasMoreSearchResults = true
                return .none

            case .mapDragged:
                state.panelStage = .collapsed
                return .none

            case .searchSubmitted:
                guard state.searchQuery.isEmpty == false else { return .none }
                state.panelStage = .full
                state.searchResults = []
                state.isSearchLoading = true
                state.searchPage = 1
                state.hasMoreSearchResults = true
                return self.searchEffect(keyword: state.searchQuery)

            case .searchResultTapped:
                return .none

            case .searchNextPageTriggered:
                guard state.isSearchNextPageLoading == false,
                      state.hasMoreSearchResults,
                      state.searchQuery.isEmpty == false else { return .none }
                state.isSearchNextPageLoading = true
                state.searchPage += 1
                return self.searchNextPageEffect(keyword: state.searchQuery, pageNo: state.searchPage)

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

            case .searchResultsResult(let spots):
                state.searchResults = spots
                state.isSearchLoading = false
                state.hasMoreSearchResults = spots.count >= self.searchPageSize
                return .none

            case .searchNextPageResultsResult(let spots):
                state.searchResults.append(contentsOf: spots)
                state.isSearchNextPageLoading = false
                state.hasMoreSearchResults = spots.count >= self.searchPageSize
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

    func searchEffect(keyword: String) -> Effect<Action> {
        .run { [touristSpotUseCase = self.touristSpotUseCase] send in
            do {
                let results = try await touristSpotUseCase.searchByKeyword(keyword: keyword, pageNo: 1)
                await send(.searchResultsResult(results))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "키워드 검색 취소됨")
                    return
                }
                await send(.searchResultsResult([]))
                AppLogger.view.log(.error, "키워드 검색 실패: \(error.localizedDescription)")
            }
        }
    }

    func searchNextPageEffect(keyword: String, pageNo: Int) -> Effect<Action> {
        .run { [touristSpotUseCase = self.touristSpotUseCase] send in
            do {
                let results = try await touristSpotUseCase.searchByKeyword(keyword: keyword, pageNo: pageNo)
                await send(.searchNextPageResultsResult(results))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "키워드 검색 다음 페이지 조회 취소됨")
                    return
                }
                await send(.searchNextPageResultsResult([]))
                AppLogger.view.log(.error, "키워드 검색 다음 페이지 조회 실패: \(error.localizedDescription)")
            }
        }
    }
}

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
    @Dependency(\.searchHistoryUseCase) var searchHistoryUseCase

    private let searchPageSize = 50
    private let categorySearchRadiusMeters = TouristSpotSearchRadius.nearbyMeters

    @ObservableState
    public struct State: Equatable {
        var centerLatitude: Double = Coordinate.seoulCityHall.latitude
        var centerLongitude: Double = Coordinate.seoulCityHall.longitude
        var showsUserLocation: Bool = false
        var hasResolvedInitialCenter: Bool = false
        var locationStatus: LocationAuthorizationStatus = .undetermined
        var mode: MapMode = .map
        var searchQuery: String = ""
        var panelStage: MapPanelStage = .half
        var searchResults: [TouristSpot] = []
        var searchResultFitToken: Int = 0
        var isSearchLoading: Bool = false
        var isSearchNextPageLoading: Bool = false
        var recentSearches: [SearchHistory] = []
        fileprivate var hasLoadedInitial: Bool = false
        fileprivate var searchPage: Int = 1
        fileprivate var hasMoreSearchResults: Bool = true
        fileprivate var activeCategory: CategoryType?
        fileprivate var activeCategoryCoordinate: Coordinate?

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case searchFieldTapped
        case searchCancelTapped
        case mapDragged
        case searchSubmitted
        case categorySelected(CategoryType, coordinate: Coordinate?)
        case searchResultTapped(TouristSpot)
        case recentSearchTapped(SearchHistory)
        case recentSearchDeleteTapped(SearchHistory)
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
                state.mode = .typing
                state.panelStage = .half
                state.recentSearches = self.searchHistoryUseCase.fetch()
                return .none

            case .searchCancelTapped:
                self.resetSearchState(&state)
                return .none

            case .mapDragged:
                state.panelStage = .collapsed
                return .none

            case .searchSubmitted:
                guard state.searchQuery.isEmpty == false else { return .none }
                self.searchHistoryUseCase.add(keyword: state.searchQuery)
                state.activeCategory = nil
                state.activeCategoryCoordinate = nil
                state.mode = .result
                state.panelStage = .half
                state.searchResults = []
                state.isSearchLoading = true
                state.searchPage = 1
                state.hasMoreSearchResults = true
                return self.searchEffect(keyword: state.searchQuery)

            case .categorySelected(let category, let coordinate):
                let resolvedCoordinate = coordinate ?? Coordinate(latitude: state.centerLatitude, longitude: state.centerLongitude)
                state.searchQuery = ""
                state.activeCategory = category
                state.activeCategoryCoordinate = resolvedCoordinate
                state.mode = .result
                state.panelStage = .half
                state.searchResults = []
                state.isSearchLoading = true
                state.searchPage = 1
                state.hasMoreSearchResults = true
                return self.categorySearchEffect(category: category, coordinate: resolvedCoordinate)

            case .searchResultTapped:
                state.mode = .map
                return .none

            case .recentSearchTapped(let history):
                state.searchQuery = history.keyword
                return .send(.searchSubmitted)

            case .recentSearchDeleteTapped(let history):
                self.searchHistoryUseCase.remove(keyword: history.keyword)
                state.recentSearches = self.searchHistoryUseCase.fetch()
                return .none

            case .searchNextPageTriggered:
                guard state.isSearchNextPageLoading == false,
                      state.hasMoreSearchResults else { return .none }

                if let category = state.activeCategory, let coordinate = state.activeCategoryCoordinate {
                    state.isSearchNextPageLoading = true
                    state.searchPage += 1
                    return self.categoryNextPageEffect(category: category, coordinate: coordinate, pageNo: state.searchPage)
                }

                guard state.searchQuery.isEmpty == false else { return .none }
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
                state.centerLatitude = Coordinate.seoulCityHall.latitude
                state.centerLongitude = Coordinate.seoulCityHall.longitude
                state.showsUserLocation = false
                state.hasResolvedInitialCenter = true
                return .none

            case .searchResultsResult(let spots):
                state.searchResults = spots
                state.isSearchLoading = false
                state.hasMoreSearchResults = spots.count >= self.searchPageSize
                if spots.contains(where: { $0.coordinate.isValid }) {
                    state.searchResultFitToken += 1
                }
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

    func categorySearchEffect(category: CategoryType, coordinate: Coordinate) -> Effect<Action> {
        .run { [touristSpotUseCase = self.touristSpotUseCase, radius = self.categorySearchRadiusMeters] send in
            do {
                let results = try await touristSpotUseCase.fetchNearbySpots(
                    contentType: category,
                    coordinate: coordinate,
                    radiusMeters: radius,
                    pageNo: 1
                )
                await send(.searchResultsResult(results))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "카테고리 검색 취소됨")
                    return
                }
                await send(.searchResultsResult([]))
                AppLogger.view.log(.error, "카테고리 검색 실패: \(error.localizedDescription)")
            }
        }
    }

    func categoryNextPageEffect(category: CategoryType, coordinate: Coordinate, pageNo: Int) -> Effect<Action> {
        .run { [touristSpotUseCase = self.touristSpotUseCase, radius = self.categorySearchRadiusMeters] send in
            do {
                let results = try await touristSpotUseCase.fetchNearbySpots(
                    contentType: category,
                    coordinate: coordinate,
                    radiusMeters: radius,
                    pageNo: pageNo
                )
                await send(.searchNextPageResultsResult(results))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "카테고리 검색 다음 페이지 조회 취소됨")
                    return
                }
                await send(.searchNextPageResultsResult([]))
                AppLogger.view.log(.error, "카테고리 검색 다음 페이지 조회 실패: \(error.localizedDescription)")
            }
        }
    }

    func resetSearchState(_ state: inout State) {
        state.mode = .map
        state.searchQuery = ""
        state.panelStage = .half
        state.searchResults = []
        state.isSearchLoading = false
        state.isSearchNextPageLoading = false
        state.searchPage = 1
        state.hasMoreSearchResults = true
        state.activeCategory = nil
        state.activeCategoryCoordinate = nil
    }
}

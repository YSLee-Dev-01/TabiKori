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
    @Dependency(\.subwayStationUseCase) var subwayStationUseCase
    @Dependency(\.toastCenter) var toastCenter

    private let searchPageSize = 50
    private let minimumLoadingDuration: TimeInterval = 0.2

    @ObservableState
    public struct State: Equatable {
        var centerLatitude: Double = Coordinate.seoulCityHall.latitude
        var centerLongitude: Double = Coordinate.seoulCityHall.longitude
        var centerRadiusMeters: Double = Double(TouristSpotSearchRadius.nearbyMeters)
        var showsUserLocation: Bool = false
        var hasResolvedInitialCenter: Bool = false
        var locationStatus: LocationAuthorizationStatus = .undetermined
        var mode: MapMode = .map
        var searchQuery: String = ""
        var panelStage: MapPanelStage = .half
        var searchResults: [TouristSpot] = []
        var subwayResults: [SubwayStation] = []
        var searchResultFitToken: Int = 0
        var isSearchLoading: Bool = false
        var isSearchNextPageLoading: Bool = false
        var recentSearches: [SearchHistory] = []
        var hasMapMovedSinceSearch: Bool = false
        var translateSearch: TranslateSearchFeature.State = .init()
        var isCategorySearchActive: Bool { self.activeCategory != nil }
        var activeCategoryLabel: String? { self.activeCategory?.label }
        var showsResearchButton: Bool { self.mode == .result && self.isCategorySearchActive && self.hasMapMovedSinceSearch }
        var showsTranslateSearchButton: Bool { self.translateSearch.isAutoTranslateSearchEnabled && self.mode == .typing }
        fileprivate var hasLoadedInitial: Bool = false
        fileprivate var searchPage: Int = 1
        fileprivate var hasMoreSearchResults: Bool = true
        fileprivate var activeCategory: CategoryType?
        fileprivate var activeCategoryCoordinate: Coordinate?
        fileprivate var activeCategoryRadiusMeters: Int?
        fileprivate var isTrackingUserDrag: Bool = false

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case searchFieldTapped
        case searchCancelTapped
        case mapDragged
        case mapCenterChanged(Coordinate, radiusMeters: Double)
        case searchSubmitted
        case categorySelected(CategoryType, coordinate: Coordinate?)
        case researchAtCurrentLocationTapped
        case searchResultTapped(TouristSpot)
        case subwayStationTapped(SubwayStation)
        case recentSearchTapped(SearchHistory)
        case recentSearchDeleteTapped(SearchHistory)
        case searchNextPageTriggered
        case panelDragEnded(MapPanelStage)
        case requestLocationPermission
        case locationPermissionResult(LocationAuthorizationStatus)
        case coordinateResult(Coordinate)
        case fallbackToSeoul
        case searchResultsResult([TouristSpot])
        case subwayResultsResult([SubwayStation])
        case researchResultsResult([TouristSpot])
        case searchNextPageResultsResult([TouristSpot])
        case recentSearchesLoaded([SearchHistory])
        case translateSearch(TranslateSearchFeature.Action)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Scope(state: \.translateSearch, action: \.translateSearch) {
            TranslateSearchFeature()
        }
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .searchFieldTapped:
                state.mode = .typing
                state.panelStage = .full
                return .merge(.send(.translateSearch(.onAppear)), self.fetchRecentSearchesEffect())

            case .searchCancelTapped:
                self.resetSearchState(&state)
                return .merge(
                    .send(.translateSearch(.reset)),
                    .cancel(id: CancelID.search),
                    .cancel(id: CancelID.subwaySearch)
                )

            case .mapDragged:
                state.panelStage = .collapsed
                state.isTrackingUserDrag = true
                return .none

            case .mapCenterChanged(let coordinate, let radiusMeters):
                state.centerLatitude = coordinate.latitude
                state.centerLongitude = coordinate.longitude
                state.centerRadiusMeters = radiusMeters
                if state.isTrackingUserDrag, state.mode == .result, state.isCategorySearchActive {
                    state.hasMapMovedSinceSearch = true
                }
                state.isTrackingUserDrag = false
                return .none

            case .searchSubmitted:
                guard state.searchQuery.isEmpty == false else { return .none }
                let keyword = state.searchQuery
                state.activeCategory = nil
                state.activeCategoryCoordinate = nil
                state.mode = .result
                state.panelStage = .half
                state.searchResults = []
                state.subwayResults = []
                state.isSearchLoading = true
                state.searchPage = 1
                state.hasMoreSearchResults = true
                state.hasMapMovedSinceSearch = false
                return .merge(
                    .send(.translateSearch(.reset)),
                    self.addSearchHistoryEffect(keyword: keyword),
                    self.searchEffect(keyword: keyword),
                    self.subwaySearchEffect(keyword: keyword)
                )

            case .categorySelected(let category, let coordinate):
                let resolvedCoordinate = coordinate ?? Coordinate(latitude: state.centerLatitude, longitude: state.centerLongitude)
                let resolvedRadiusMeters = coordinate == nil
                    ? self.clampedRadiusMeters(state.centerRadiusMeters)
                    : TouristSpotSearchRadius.nearbyMeters
                state.searchQuery = ""
                state.activeCategory = category
                state.activeCategoryCoordinate = resolvedCoordinate
                state.activeCategoryRadiusMeters = resolvedRadiusMeters
                state.mode = .result
                state.panelStage = .half
                state.searchResults = []
                state.subwayResults = []
                state.isSearchLoading = true
                state.searchPage = 1
                state.hasMoreSearchResults = true
                state.hasMapMovedSinceSearch = false
                return .merge(
                    self.categorySearchEffect(category: category, coordinate: resolvedCoordinate, radiusMeters: resolvedRadiusMeters),
                    .cancel(id: CancelID.subwaySearch)
                )

            case .researchAtCurrentLocationTapped:
                let resolvedCoordinate = Coordinate(latitude: state.centerLatitude, longitude: state.centerLongitude)
                let resolvedRadiusMeters = self.clampedRadiusMeters(state.centerRadiusMeters)
                guard let category = state.activeCategory else { return .none }
                state.activeCategoryCoordinate = resolvedCoordinate
                state.activeCategoryRadiusMeters = resolvedRadiusMeters
                state.searchResults = []
                state.isSearchLoading = true
                state.searchPage = 1
                state.hasMoreSearchResults = true
                state.hasMapMovedSinceSearch = false
                return self.categoryResearchEffect(category: category, coordinate: resolvedCoordinate, radiusMeters: resolvedRadiusMeters)

            case .searchResultTapped:
                return .none

            case .subwayStationTapped(let station):
                return self.selectSubwayStationEffect(station: station)

            case .recentSearchTapped(let history):
                state.searchQuery = history.keyword
                return .send(.searchSubmitted)

            case .recentSearchDeleteTapped(let history):
                return self.deleteSearchHistoryEffect(keyword: history.keyword)

            case .searchNextPageTriggered:
                guard state.isSearchNextPageLoading == false,
                      state.hasMoreSearchResults else { return .none }

                if let category = state.activeCategory,
                   let coordinate = state.activeCategoryCoordinate,
                   let radiusMeters = state.activeCategoryRadiusMeters {
                    state.isSearchNextPageLoading = true
                    state.searchPage += 1
                    return self.categoryNextPageEffect(category: category, coordinate: coordinate, radiusMeters: radiusMeters, pageNo: state.searchPage)
                }

                guard state.searchQuery.isEmpty == false else { return .none }
                state.isSearchNextPageLoading = true
                state.searchPage += 1
                return self.searchNextPageEffect(keyword: state.searchQuery, pageNo: state.searchPage)

            case .panelDragEnded(let stage):
                state.panelStage = stage
                return .none

            case .onAppear:
                let translateSearchOnAppearEffect: Effect<Action> = .send(.translateSearch(.onAppear))
                guard state.hasLoadedInitial == false else { return translateSearchOnAppearEffect }
                state.hasLoadedInitial = true
                state.locationStatus = self.locationUseCase.checkAuthorization()

                switch state.locationStatus {
                case .undetermined:
                    return .merge(translateSearchOnAppearEffect, .send(.requestLocationPermission))

                case .allowed:
                    return .merge(translateSearchOnAppearEffect, self.fetchCoordinateEffect())

                case .denied:
                    return .merge(translateSearchOnAppearEffect, .send(.fallbackToSeoul))
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
                let hasResults = spots.isEmpty == false || state.subwayResults.isEmpty == false
                return .send(.translateSearch(.searchCompleted(query: state.searchQuery, hasResults: hasResults)))

            case .subwayResultsResult(let stations):
                state.subwayResults = stations
                return .none

            case .researchResultsResult(let spots):
                state.searchResults = spots
                state.isSearchLoading = false
                state.hasMoreSearchResults = spots.count >= self.searchPageSize
                return .none

            case .searchNextPageResultsResult(let spots):
                state.searchResults.append(contentsOf: spots)
                state.isSearchNextPageLoading = false
                state.hasMoreSearchResults = spots.count >= self.searchPageSize
                return .none

            case .recentSearchesLoaded(let histories):
                state.recentSearches = histories
                return .none

            case .translateSearch(.delegate(.toastActionConfirmed)):
                return .send(.translateSearch(.translateButtonRequested(query: state.searchQuery)))

            case .translateSearch(.delegate(.retranslatedQueryReady(let translatedQuery))):
                state.searchQuery = translatedQuery
                return .send(.searchSubmitted)

            case .translateSearch:
                return .none
            }
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case search
    case subwaySearch
    case resolveStation
}

// MARK: - Method

private extension MapFeature {
    func fetchCoordinateEffect() -> Effect<Action> {
        .run { [locationUseCase = self.locationUseCase, toastCenter = self.toastCenter] send in
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
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
            }
        }
    }

    func fetchRecentSearchesEffect() -> Effect<Action> {
        .run { [searchHistoryUseCase = self.searchHistoryUseCase] send in
            await send(.recentSearchesLoaded(searchHistoryUseCase.fetch()))
        }
    }

    func addSearchHistoryEffect(keyword: String) -> Effect<Action> {
        .run { [searchHistoryUseCase = self.searchHistoryUseCase] _ in
            searchHistoryUseCase.add(keyword: keyword)
        }
    }

    func deleteSearchHistoryEffect(keyword: String) -> Effect<Action> {
        .run { [searchHistoryUseCase = self.searchHistoryUseCase] send in
            searchHistoryUseCase.remove(keyword: keyword)
            await send(.recentSearchesLoaded(searchHistoryUseCase.fetch()))
        }
    }

    func searchEffect(keyword: String) -> Effect<Action> {
        .run { [
            touristSpotUseCase = self.touristSpotUseCase,
            minimumLoadingDuration = self.minimumLoadingDuration,
            toastCenter = self.toastCenter
        ] send in
            do {
                let results = try await Task.withMinimumDuration(seconds: minimumLoadingDuration) {
                    try await touristSpotUseCase.searchByKeyword(keyword: keyword, pageNo: 1)
                }
                await send(.searchResultsResult(results))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "키워드 검색 취소됨")
                    return
                }
                await send(.searchResultsResult([]))
                AppLogger.view.log(.error, "키워드 검색 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
            }
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)
    }

    func searchNextPageEffect(keyword: String, pageNo: Int) -> Effect<Action> {
        .run { [
            touristSpotUseCase = self.touristSpotUseCase,
            minimumLoadingDuration = self.minimumLoadingDuration,
            toastCenter = self.toastCenter
        ] send in
            do {
                let results = try await Task.withMinimumDuration(seconds: minimumLoadingDuration) {
                    try await touristSpotUseCase.searchByKeyword(keyword: keyword, pageNo: pageNo)
                }
                await send(.searchNextPageResultsResult(results))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "키워드 검색 다음 페이지 조회 취소됨")
                    return
                }
                await send(.searchNextPageResultsResult([]))
                AppLogger.view.log(.error, "키워드 검색 다음 페이지 조회 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
            }
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)
    }

    func subwaySearchEffect(keyword: String) -> Effect<Action> {
        .run { [subwayStationUseCase = self.subwayStationUseCase] send in
            let results = await subwayStationUseCase.search(keyword: keyword)
            guard !Task.isCancelled else {
                AppLogger.view.log(.debug, "지하철역 검색 취소됨")
                return
            }
            await send(.subwayResultsResult(results))
        }
        .cancellable(id: CancelID.subwaySearch, cancelInFlight: true)
    }

    func selectSubwayStationEffect(station: SubwayStation) -> Effect<Action> {
        .run { [subwayStationUseCase = self.subwayStationUseCase, toastCenter = self.toastCenter] send in
            do {
                let spot = try await subwayStationUseCase.selectStation(station)
                await send(.searchResultTapped(spot))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "지하철역 선택 취소됨")
                    return
                }
                AppLogger.network.log(.error, "지하철역 좌표 조회 실패: \(station.koreanName) - \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
            }
        }
        .cancellable(id: CancelID.resolveStation, cancelInFlight: true)
    }

    func categorySearchEffect(category: CategoryType, coordinate: Coordinate, radiusMeters: Int) -> Effect<Action> {
        .run { [
            touristSpotUseCase = self.touristSpotUseCase,
            minimumLoadingDuration = self.minimumLoadingDuration,
            toastCenter = self.toastCenter
        ] send in
            do {
                let results = try await Task.withMinimumDuration(seconds: minimumLoadingDuration) {
                    try await touristSpotUseCase.fetchNearbySpots(
                        contentType: category,
                        coordinate: coordinate,
                        radiusMeters: radiusMeters,
                        pageNo: 1
                    )
                }
                await send(.searchResultsResult(results))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "카테고리 검색 취소됨")
                    return
                }
                await send(.searchResultsResult([]))
                AppLogger.view.log(.error, "카테고리 검색 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
            }
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)
    }

    func categoryResearchEffect(category: CategoryType, coordinate: Coordinate, radiusMeters: Int) -> Effect<Action> {
        .run { [
            touristSpotUseCase = self.touristSpotUseCase,
            minimumLoadingDuration = self.minimumLoadingDuration,
            toastCenter = self.toastCenter
        ] send in
            do {
                let results = try await Task.withMinimumDuration(seconds: minimumLoadingDuration) {
                    try await touristSpotUseCase.fetchNearbySpots(
                        contentType: category,
                        coordinate: coordinate,
                        radiusMeters: radiusMeters,
                        pageNo: 1
                    )
                }
                await send(.researchResultsResult(results))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "위치 재검색 취소됨")
                    return
                }
                await send(.researchResultsResult([]))
                AppLogger.view.log(.error, "위치 재검색 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
            }
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)
    }

    func categoryNextPageEffect(category: CategoryType, coordinate: Coordinate, radiusMeters: Int, pageNo: Int) -> Effect<Action> {
        .run { [
            touristSpotUseCase = self.touristSpotUseCase,
            minimumLoadingDuration = self.minimumLoadingDuration,
            toastCenter = self.toastCenter
        ] send in
            do {
                let results = try await Task.withMinimumDuration(seconds: minimumLoadingDuration) {
                    try await touristSpotUseCase.fetchNearbySpots(
                        contentType: category,
                        coordinate: coordinate,
                        radiusMeters: radiusMeters,
                        pageNo: pageNo
                    )
                }
                await send(.searchNextPageResultsResult(results))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "카테고리 검색 다음 페이지 조회 취소됨")
                    return
                }
                await send(.searchNextPageResultsResult([]))
                AppLogger.view.log(.error, "카테고리 검색 다음 페이지 조회 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
            }
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)
    }

    func clampedRadiusMeters(_ radiusMeters: Double) -> Int {
        let clamped = min(
            max(radiusMeters, Double(TouristSpotSearchRadius.minMeters)),
            Double(TouristSpotSearchRadius.maxMeters)
        )
        return Int(clamped.rounded())
    }

    func resetSearchState(_ state: inout State) {
        state.mode = .map
        state.searchQuery = ""
        state.panelStage = .half
        state.searchResults = []
        state.subwayResults = []
        state.isSearchLoading = false
        state.isSearchNextPageLoading = false
        state.searchPage = 1
        state.hasMoreSearchResults = true
        state.activeCategory = nil
        state.activeCategoryCoordinate = nil
        state.activeCategoryRadiusMeters = nil
        state.hasMapMovedSinceSearch = false
        state.isTrackingUserDrag = false
    }
}

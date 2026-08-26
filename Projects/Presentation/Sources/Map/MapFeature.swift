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
import Resource

// MARK: - MapFeature

@Reducer
public struct MapFeature: Sendable {

    @Dependency(\.locationUseCase) var locationUseCase
    @Dependency(\.touristSpotUseCase) var touristSpotUseCase
    @Dependency(\.searchHistoryUseCase) var searchHistoryUseCase
    @Dependency(\.subwayStationUseCase) var subwayStationUseCase
    @Dependency(\.autoTranslateSearchUseCase) var autoTranslateSearchUseCase
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
        var isAutoTranslateSearchEnabled: Bool = false
        /// View가 관찰해 Translation 프레임워크로 번역을 실행해야 하는 트리거. 값이 채워지면 View가 번역을 실행하고 결과를 돌려준다
        var pendingTranslationQuery: String?
        var isCategorySearchActive: Bool { self.activeCategory != nil }
        var activeCategoryLabel: String? { self.activeCategory?.label }
        var showsResearchButton: Bool { self.mode == .result && self.isCategorySearchActive && self.hasMapMovedSinceSearch }
        var showsTranslateSearchButton: Bool { self.isAutoTranslateSearchEnabled && self.mode == .typing }
        fileprivate var hasLoadedInitial: Bool = false
        fileprivate var searchPage: Int = 1
        fileprivate var hasMoreSearchResults: Bool = true
        fileprivate var activeCategory: CategoryType?
        fileprivate var activeCategoryCoordinate: Coordinate?
        fileprivate var activeCategoryRadiusMeters: Int?
        fileprivate var isTrackingUserDrag: Bool = false
        /// 번역 유도 Toast를 띄웠을 때의 id. ToastCenter의 액션 탭 이벤트가 이 id와 일치할 때만 번역을 트리거한다
        fileprivate var translationToastId: UUID?

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
        case translateSearchButtonTapped
        case toastActionTapReceived(UUID)
        case translationResultReceived(String)
        case translationFailed
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
                state.panelStage = .full
                state.isAutoTranslateSearchEnabled = self.autoTranslateSearchUseCase.isEnabled()
                return self.fetchRecentSearchesEffect()

            case .searchCancelTapped:
                self.resetSearchState(&state)
                return .merge(
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
                state.translationToastId = nil
                return .merge(
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
                state.isAutoTranslateSearchEnabled = self.autoTranslateSearchUseCase.isEnabled()
                guard state.hasLoadedInitial == false else { return .none }
                state.hasLoadedInitial = true
                state.locationStatus = self.locationUseCase.checkAuthorization()

                let toastSubscriptionEffect = self.subscribeToastActionTapEffect()
                switch state.locationStatus {
                case .undetermined:
                    return .merge(toastSubscriptionEffect, .send(.requestLocationPermission))

                case .allowed:
                    return .merge(toastSubscriptionEffect, self.fetchCoordinateEffect())

                case .denied:
                    return .merge(toastSubscriptionEffect, .send(.fallbackToSeoul))
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
                return self.showTranslationSuggestionIfNeededEffect(&state)

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

            case .translateSearchButtonTapped:
                guard state.searchQuery.isEmpty == false else {
                    return self.showEmptyQueryGuideEffect()
                }
                state.pendingTranslationQuery = state.searchQuery
                return .none

            case .toastActionTapReceived(let toastId):
                guard state.translationToastId == toastId else { return .none }
                guard state.searchQuery.isEmpty == false else {
                    return self.showEmptyQueryGuideEffect()
                }
                state.pendingTranslationQuery = state.searchQuery
                return .none

            case .translationResultReceived(let translatedQuery):
                state.pendingTranslationQuery = nil
                guard translatedQuery.isEmpty == false else { return .none }
                state.searchQuery = translatedQuery
                return .send(.searchSubmitted)

            case .translationFailed:
                state.pendingTranslationQuery = nil
                return self.showTranslationFailedEffect()
            }
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case search
    case subwaySearch
    case resolveStation
    case toastActionSubscription
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

    /// 검색어가 비어 있는 상태로 번역 버튼(아이콘 또는 Toast 액션)이 눌렸을 때, 조용히 무시하는 대신
    /// 안내 Toast를 띄운다
    func showEmptyQueryGuideEffect() -> Effect<Action> {
        .run { [toastCenter = self.toastCenter] _ in
            toastCenter.show(ToastItem(
                message: Strings.Map.translateSearchEmptyQueryGuideMessage,
                type: .info
            ))
        }
    }

    /// 번역 실패 시 에러 Toast를 띄운다
    func showTranslationFailedEffect() -> Effect<Action> {
        .run { [toastCenter = self.toastCenter] _ in
            toastCenter.show(ToastItem(message: Strings.Map.translateFailedMessage, type: .error))
        }
    }

    func subscribeToastActionTapEffect() -> Effect<Action> {
        .run { [toastCenter = self.toastCenter] send in
            for await toastId in toastCenter.actionTapEvents {
                await send(.toastActionTapReceived(toastId))
            }
        }
        .cancellable(id: CancelID.toastActionSubscription, cancelInFlight: true)
    }

    /// 자동 번역 검색 flag가 켜져 있고, 검색어가 일본어이며, 검색 결과(관광지·지하철역)가 모두 비어 있을 때만
    /// "한국어로 번역 후 검색" 유도 Toast를 노출한다
    func showTranslationSuggestionIfNeededEffect(_ state: inout State) -> Effect<Action> {
        guard state.isAutoTranslateSearchEnabled,
              state.searchQuery.isEmpty == false,
              state.searchQuery.containsJapanese,
              state.searchResults.isEmpty,
              state.subwayResults.isEmpty else { return .none }

        let toastId = UUID()
        state.translationToastId = toastId
        return .run { [toastCenter = self.toastCenter] _ in
            toastCenter.show(ToastItem(
                id: toastId,
                message: Strings.Map.searchResultEmptyTitle,
                type: .info,
                actionButtonTitle: Strings.Map.translateAndSearchButtonTitle
            ))
        }
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
        state.translationToastId = nil
        state.pendingTranslationQuery = nil
    }
}

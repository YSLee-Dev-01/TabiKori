//
//  AddCustomPlaceFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain
import Resource

// MARK: - AddCustomPlaceFeature

@Reducer
public struct AddCustomPlaceFeature: Sendable {

    @Dependency(\.naverGeocodingUseCase) var naverGeocodingUseCase
    @Dependency(\.subwayStationUseCase) var subwayStationUseCase
    @Dependency(\.touristSpotUseCase) var touristSpotUseCase
    @Dependency(\.bookmarkUseCase) var bookmarkUseCase
    @Dependency(\.toastCenter) var toastCenter
    @Dependency(\.dismiss) var dismiss

    private let searchPageSize = 50

    @ObservableState
    public struct State: Equatable {
        var selectedTab: AddCustomPlaceTab = .search
        var editingContentId: String?

        var title: String = ""
        var address: String = ""
        var selectedCategory: CategoryType?
        var isSaving: Bool = false
        var previewCoordinate: Coordinate?
        var previewFitToken: Int = 0
        var isSubwayMode: Bool = false
        var isSubwaySearching: Bool = false
        var subwayResults: [SubwayStation] = []
        var matchedStation: TouristSpot?
        var isAddressPreviewLoading: Bool = false

        // 검색 탭 전용 상태
        var searchQuery: String = ""
        var searchResults: [TouristSpot] = []
        var searchStationResults: [SubwayStation] = []
        var isSearchLoading: Bool = false
        var hasSearched: Bool = false
        var isSearchNextPageLoading: Bool = false
        var translateSearch: TranslateSearchFeature.State = .init()
        fileprivate var searchPage: Int = 1
        fileprivate var hasMoreSearchResults: Bool = true

        @Presents var alert: AlertState<Action.Alert>?

        public init() {}

        var trimmedSearchQuery: String {
            self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var trimmedTitle: String {
            self.title.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var trimmedAddress: String {
            self.address.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var isConfirmEnabled: Bool {
            if self.isSubwayMode {
                return self.isSaving == false && self.matchedStation != nil
            }
            guard self.selectedCategory != nil else { return false }
            guard !self.trimmedTitle.isEmpty else { return false }
            guard !self.trimmedAddress.isEmpty else { return false }
            return true
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case closeTapped
        case tabSelected(AddCustomPlaceTab)
        case categorySelected(CategoryType)
        case confirmTapped
        case addressSubmitted
        case stationNameSubmitted
        case saveResult(Bool)
        case addressNotFound
        case addressPreviewResult(Coordinate)
        case addressPreviewFailed
        case stationSearchResult([SubwayStation])
        case subwayStationTapped(SubwayStation)
        case stationResolveResult(TouristSpot?)
        case stationResolveFailed
        case alert(PresentationAction<Alert>)

        // 검색 탭
        case searchSubmitted
        case searchNextPageTriggered
        case searchSpotTapped(TouristSpot)
        case searchStationTapped(SubwayStation)
        case searchResultsResult([TouristSpot])
        case searchStationResultsResult([SubwayStation])
        case searchNextPageResultsResult([TouristSpot])
        case translateSearch(TranslateSearchFeature.Action)

        public enum Alert: Equatable {}
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Scope(state: \.translateSearch, action: \.translateSearch) {
            TranslateSearchFeature()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.translateSearch(.onAppear))

            case .binding(\.address):
                state.previewCoordinate = nil
                return .none

            case .binding(\.title):
                guard state.isSubwayMode else { return .none }
                state.matchedStation = nil
                state.previewCoordinate = nil
                state.subwayResults = []
                state.isSubwaySearching = false
                return .cancel(id: CancelID.stationSearch)

            case .binding(\.searchQuery):
                guard state.searchQuery.isEmpty == false else { return .none }
                state.searchResults = []
                state.searchStationResults = []
                state.hasSearched = false
                return .merge(
                    .send(.translateSearch(.reset)),
                    .cancel(id: CancelID.searchSpots),
                    .cancel(id: CancelID.searchStations)
                )

            case .binding:
                return .none

            case .closeTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }

            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none

            case .categorySelected(let category):
                if category == .subway {
                    guard state.isSubwayMode == false else { return .none }
                    state.isSubwayMode = true
                } else {
                    state.selectedCategory = category
                    guard state.isSubwayMode else { return .none }
                    state.isSubwayMode = false
                }
                state.matchedStation = nil
                state.previewCoordinate = nil
                state.subwayResults = []
                return .none

            case .confirmTapped:
                guard state.isSaving == false, state.isConfirmEnabled else { return .none }

                if state.isSubwayMode {
                    guard let station = state.matchedStation else { return .none }
                    state.isSaving = true
                    return self.saveSpotEffect(spot: station)
                }

                guard let category = state.selectedCategory else { return .none }
                state.isSaving = true
                return self.saveEffect(
                    category: category,
                    title: state.trimmedTitle,
                    address: state.trimmedAddress,
                    editingContentId: state.editingContentId
                )

            case .addressSubmitted:
                guard state.trimmedAddress.isEmpty == false else { return .none }
                state.isAddressPreviewLoading = true
                return self.addressPreviewEffect(address: state.trimmedAddress)

            case .stationNameSubmitted:
                guard state.trimmedTitle.isEmpty == false else { return .none }
                state.isSubwaySearching = true
                state.subwayResults = []
                return self.subwaySearchEffect(keyword: state.trimmedTitle)

            case .saveResult(true):
                return .none

            case .saveResult(false):
                state.isSaving = false
                state.alert = AlertState {
                    TextState(Strings.Plan.saveFailedAlertTitle)
                } actions: {
                    ButtonState {
                        TextState(Strings.Plan.alertConfirm)
                    }
                } message: {
                    TextState(Strings.Plan.saveFailedAlertMessage)
                }
                return .none

            case .addressNotFound:
                state.isSaving = false
                state.isAddressPreviewLoading = false
                state.alert = AlertState {
                    TextState(Strings.AddCustomPlace.addressNotFoundAlertTitle)
                } actions: {
                    ButtonState {
                        TextState(Strings.Plan.alertConfirm)
                    }
                } message: {
                    TextState(Strings.AddCustomPlace.addressNotFoundAlertMessage)
                }
                return .none

            case .addressPreviewResult(let coordinate):
                state.isAddressPreviewLoading = false
                state.previewCoordinate = coordinate
                state.previewFitToken += 1
                return .none

            case .addressPreviewFailed:
                state.isAddressPreviewLoading = false
                return .none

            case .stationSearchResult(let stations):
                state.isSubwaySearching = false
                state.subwayResults = stations
                return .none

            case .subwayStationTapped(let station):
                return self.selectSubwayStationEffect(station: station)

            case .stationResolveResult(let spot):
                guard let spot else { return .none }
                state.matchedStation = spot
                state.previewCoordinate = spot.coordinate
                state.previewFitToken += 1
                state.subwayResults = []
                return .none

            case .stationResolveFailed:
                state.alert = AlertState {
                    TextState(Strings.AddCustomPlace.stationResolveFailedAlertTitle)
                } actions: {
                    ButtonState {
                        TextState(Strings.Plan.alertConfirm)
                    }
                } message: {
                    TextState(Strings.AddCustomPlace.stationResolveFailedAlertMessage)
                }
                return .none

            case .alert:
                return .none

            case .searchSubmitted:
                guard state.trimmedSearchQuery.isEmpty == false else { return .none }
                let keyword = state.trimmedSearchQuery
                state.searchResults = []
                state.searchStationResults = []
                state.isSearchLoading = true
                state.hasSearched = true
                state.searchPage = 1
                state.hasMoreSearchResults = true
                return .merge(
                    .send(.translateSearch(.reset)),
                    self.searchSpotsEffect(keyword: keyword, pageNo: 1),
                    self.searchStationsEffect(keyword: keyword)
                )

            case .searchNextPageTriggered:
                guard state.isSearchNextPageLoading == false, state.hasMoreSearchResults else { return .none }
                guard state.trimmedSearchQuery.isEmpty == false else { return .none }
                state.isSearchNextPageLoading = true
                state.searchPage += 1
                return self.searchSpotsNextPageEffect(keyword: state.trimmedSearchQuery, pageNo: state.searchPage)

            case .searchSpotTapped(let spot):
                guard state.isSaving == false else { return .none }
                state.isSaving = true
                return self.saveSpotEffect(spot: spot)

            case .searchStationTapped(let station):
                guard state.isSaving == false else { return .none }
                state.isSaving = true
                return self.searchSaveStationEffect(station: station)

            case .searchResultsResult(let spots):
                state.searchResults = spots
                state.isSearchLoading = false
                state.hasMoreSearchResults = spots.count >= self.searchPageSize
                let hasResults = spots.isEmpty == false || state.searchStationResults.isEmpty == false
                return .send(.translateSearch(.searchCompleted(query: state.trimmedSearchQuery, hasResults: hasResults)))

            case .searchStationResultsResult(let stations):
                state.searchStationResults = stations
                return .none

            case .searchNextPageResultsResult(let spots):
                state.searchResults.append(contentsOf: spots)
                state.isSearchNextPageLoading = false
                state.hasMoreSearchResults = spots.count >= self.searchPageSize
                return .none

            case .translateSearch(.delegate(.toastActionConfirmed)):
                return .send(.translateSearch(.translateButtonRequested(query: state.trimmedSearchQuery)))

            case .translateSearch(.delegate(.retranslatedQueryReady(let translatedQuery))):
                state.searchQuery = translatedQuery
                return .send(.searchSubmitted)

            case .translateSearch:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - CancelID

private enum CancelID {
    case save
    case preview
    case stationSearch
    case resolveStation
    case searchSpots
    case searchStations
}

// MARK: - Method

private extension AddCustomPlaceFeature {
    func saveEffect(category: CategoryType, title: String, address: String, editingContentId: String?) -> Effect<Action> {
        .run { [
            naverGeocodingUseCase = self.naverGeocodingUseCase,
            bookmarkUseCase = self.bookmarkUseCase,
            toastCenter = self.toastCenter
        ] send in
            let geocoded: GeocodedAddress
            do {
                geocoded = try await naverGeocodingUseCase.geocode(address: address)
            } catch TabiError.dataNotFound {
                AppLogger.view.log(.error, "커스텀 장소 주소 변환 실패: 주소를 찾을 수 없음")
                await send(.addressNotFound)
                return
            } catch {
                AppLogger.view.log(.error, "커스텀 장소 주소 변환 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.saveResult(false))
                return
            }
            await send(.addressPreviewResult(geocoded.coordinate))
            let spot = TouristSpot(
                id: editingContentId ?? "custom_" + UUID().uuidString,
                title: title,
                thumbnailURLString: nil,
                distanceMeters: nil,
                contentType: category,
                coordinate: geocoded.coordinate,
                isCustom: true,
                address: geocoded.formattedAddress.isEmpty ? address : geocoded.formattedAddress
            )
            do {
                if let editingContentId {
                    try await bookmarkUseCase.update(spot)
                } else {
                    try await bookmarkUseCase.add(spot)
                }
                await send(.saveResult(true))
            } catch {
                AppLogger.view.log(.error, "커스텀 장소 저장 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.saveResult(false))
            }
        }
        .cancellable(id: CancelID.save, cancelInFlight: true)
    }

    /// 확정된 TouristSpot을 북마크에 저장한다. 커스텀 탭의 지하철역 확인 저장, 검색 탭의 스팟 즉시 저장에서 공용으로 사용
    func saveSpotEffect(spot: TouristSpot) -> Effect<Action> {
        .run { [bookmarkUseCase = self.bookmarkUseCase, toastCenter = self.toastCenter] send in
            do {
                try await bookmarkUseCase.add(spot)
                await send(.saveResult(true))
            } catch {
                AppLogger.view.log(.error, "스팟 북마크 저장 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.saveResult(false))
            }
        }
        .cancellable(id: CancelID.save, cancelInFlight: true)
    }

    func subwaySearchEffect(keyword: String) -> Effect<Action> {
        .run { [subwayStationUseCase = self.subwayStationUseCase] send in
            let results = await subwayStationUseCase.search(keyword: keyword)
            guard !Task.isCancelled else { return }
            await send(.stationSearchResult(results))
        }
        .cancellable(id: CancelID.stationSearch, cancelInFlight: true)
    }

    func selectSubwayStationEffect(station: SubwayStation) -> Effect<Action> {
        .run { [subwayStationUseCase = self.subwayStationUseCase, toastCenter = self.toastCenter] send in
            do {
                let spot = try await subwayStationUseCase.selectStation(station)
                await send(.stationResolveResult(spot))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.network.log(.error, "지하철역 좌표 조회 실패: \(station.koreanName) - \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.stationResolveFailed)
            }
        }
        .cancellable(id: CancelID.resolveStation, cancelInFlight: true)
    }

    func addressPreviewEffect(address: String) -> Effect<Action> {
        .run { [naverGeocodingUseCase = self.naverGeocodingUseCase, toastCenter = self.toastCenter] send in
            do {
                let geocoded = try await naverGeocodingUseCase.geocode(address: address)
                await send(.addressPreviewResult(geocoded.coordinate))
            } catch TabiError.dataNotFound {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "커스텀 장소 주소 미리보기 실패: 주소를 찾을 수 없음")
                await send(.addressNotFound)
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "커스텀 장소 주소 미리보기 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.addressPreviewFailed)
            }
        }
        .cancellable(id: CancelID.preview, cancelInFlight: true)
    }

    func searchSpotsEffect(keyword: String, pageNo: Int) -> Effect<Action> {
        .run { [touristSpotUseCase = self.touristSpotUseCase, toastCenter = self.toastCenter] send in
            do {
                let results = try await touristSpotUseCase.searchByKeyword(keyword: keyword, pageNo: pageNo)
                await send(.searchResultsResult(results))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "스팟 검색 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.searchResultsResult([]))
            }
        }
        .cancellable(id: CancelID.searchSpots, cancelInFlight: true)
    }

    func searchSpotsNextPageEffect(keyword: String, pageNo: Int) -> Effect<Action> {
        .run { [touristSpotUseCase = self.touristSpotUseCase, toastCenter = self.toastCenter] send in
            do {
                let results = try await touristSpotUseCase.searchByKeyword(keyword: keyword, pageNo: pageNo)
                await send(.searchNextPageResultsResult(results))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "스팟 검색 다음 페이지 조회 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.searchNextPageResultsResult([]))
            }
        }
        .cancellable(id: CancelID.searchSpots, cancelInFlight: true)
    }

    func searchStationsEffect(keyword: String) -> Effect<Action> {
        .run { [subwayStationUseCase = self.subwayStationUseCase] send in
            let results = await subwayStationUseCase.search(keyword: keyword)
            guard !Task.isCancelled else { return }
            await send(.searchStationResultsResult(results))
        }
        .cancellable(id: CancelID.searchStations, cancelInFlight: true)
    }

    func searchSaveStationEffect(station: SubwayStation) -> Effect<Action> {
        .run { [
            subwayStationUseCase = self.subwayStationUseCase,
            bookmarkUseCase = self.bookmarkUseCase,
            toastCenter = self.toastCenter
        ] send in
            do {
                let spot = try await subwayStationUseCase.selectStation(station)
                try await bookmarkUseCase.add(spot)
                await send(.saveResult(true))
            } catch {
                AppLogger.view.log(.error, "검색 지하철역 저장 실패: \(station.koreanName) - \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.saveResult(false))
            }
        }
        .cancellable(id: CancelID.save, cancelInFlight: true)
    }

}

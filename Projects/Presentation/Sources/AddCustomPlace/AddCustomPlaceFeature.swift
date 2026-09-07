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
        fileprivate var lastSubmittedSearchQuery: String?
        /// 현재 대기 중이거나 가장 최근에 요청된 번역이 검색 탭(searchQuery)이 아닌 커스텀 탭 지하철 검색(title)에서
        /// 시작된 것인지 구분한다. `translateSearch`가 두 탭에서 공유하는 단일 Scope이므로, 번역 결과(`retranslatedQueryReady`)나
        /// Toast 액션 확인(`toastActionConfirmed`)이 돌아왔을 때 어느 탭의 검색어를 갱신·재검색해야 하는지 이 값으로 판단한다
        fileprivate var isSubwayTranslateOrigin: Bool = false

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
                guard state.isSubwayMode else { return .none }
                state.isSubwayTranslateOrigin = true
                let hasResults = stations.isEmpty == false
                let searchCompletedEffect = Effect<Action>.send(
                    .translateSearch(.searchCompleted(query: state.trimmedTitle, hasResults: hasResults))
                )
                guard hasResults == false else { return searchCompletedEffect }
                return .merge(self.showStationSearchEmptyEffect(), searchCompletedEffect)

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
                // 검색어 변경 없이 동일한 검색어로 다시 제출된 경우, 결과가 이미 표시된 상태(hasSearched)라면
                // 결과 초기화·로딩 인디케이터·재요청 없이 그대로 유지한다. 검색어가 바뀌면 `.binding(\.searchQuery)`에서
                // hasSearched가 false로 리셋되므로, 이 가드는 오직 "완전히 동일한 검색어 재제출"만 걸러낸다
                guard state.hasSearched == false || keyword != state.lastSubmittedSearchQuery else { return .none }
                state.lastSubmittedSearchQuery = keyword
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
                state.isSubwayTranslateOrigin = false
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

            case .translateSearch(.translateButtonRequested(let query)):
                // translateSearch는 검색 탭·커스텀 탭(지하철) 양쪽이 공유하는 단일 Scope이므로, 실제로 어느 탭의
                // 검색어가 요청된 것인지를 여기서 판별해 isSubwayTranslateOrigin에 기록해둔다. 아래 두 조건 중
                // 어느 쪽에도 해당하지 않으면(toastActionConfirmed로부터 재전송된 요청인데, 그사이 사용자가 탭을
                // 전환해 현재 탭 상태와 query의 출처 탭이 서로 달라진 경우) 기존 값을 그대로 유지해 origin이
                // 잘못 덮어써지지 않도록 한다
                let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
                if state.isSubwayMode, trimmedQuery == state.trimmedTitle {
                    state.isSubwayTranslateOrigin = true
                } else if state.selectedTab == .search, trimmedQuery == state.trimmedSearchQuery {
                    state.isSubwayTranslateOrigin = false
                }
                return .none

            case .translateSearch(.delegate(.toastActionConfirmed)):
                let query = state.isSubwayTranslateOrigin ? state.trimmedTitle : state.trimmedSearchQuery
                return .send(.translateSearch(.translateButtonRequested(query: query)))

            case .translateSearch(.delegate(.retranslatedQueryReady(let translatedQuery))):
                if state.isSubwayTranslateOrigin {
                    state.title = translatedQuery
                    return .send(.stationNameSubmitted)
                }
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

    /// 커스텀 탭 지하철 검색 결과가 없을 때(빈 문자열 제출이 아닌, 실제 검색이 수행된 경우에 한해) 안내하는 Toast.
    /// 검색 탭은 결과 없음 상태를 리스트 내 `TabiEmptyState`로 표시하지만, 지하철 검색 결과는 별도의 리스트 UI가
    /// 없어 결과가 사라졌다는 사실 자체를 알 수 없으므로 Toast로 안내한다
    func showStationSearchEmptyEffect() -> Effect<Action> {
        .run { [toastCenter = self.toastCenter] _ in
            toastCenter.show(ToastItem(message: Strings.Map.searchResultEmptyTitle, type: .info))
        }
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

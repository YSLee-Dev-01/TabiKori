//
//  PlanDetailAddSpotFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/5/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain
import Resource

/// PlanDetail "+" 버튼으로 여는 하단 시트. Step 1(관광지 검색/즐겨찾기에서 스팟 선택)과
/// Step 2(시작/종료 시각 입력)를 같은 시트 안에서 전환한다
@Reducer
public struct PlanDetailAddSpotFeature: Sendable {

    @Dependency(\.touristSpotUseCase) var touristSpotUseCase
    @Dependency(\.bookmarkUseCase) var bookmarkUseCase
    @Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase
    @Dependency(\.subwayStationUseCase) var subwayStationUseCase
    @Dependency(\.naverGeocodingUseCase) var naverGeocodingUseCase
    @Dependency(\.toastCenter) var toastCenter
    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
        let planId: UUID
        let dayIndex: Int
        let date: Date
        var step: Step = .selectingSpot
        var tab: Tab = .search
        var searchKeyword: String = ""
        var searchResults: [TouristSpot] = []
        var subwayResults: [SubwayStation] = []
        var isSearchLoading: Bool = false
        var hasSearched: Bool = false
        var translateSearch: TranslateSearchFeature.State = .init()
        var bookmarks: [Bookmark] = []
        var isBookmarkLoading: Bool = false
        var selectedSpot: TouristSpot? = nil
        var startTime: Date = Date()
        var endTime: Date = Date()
        var isTimeUnset: Bool = false
        var isSaving: Bool = false
        // 주소로 추가 탭 (카스텀)
        var addressTitle: String = ""
        var addressInput: String = ""
        var addressSelectedCategory: CategoryType? = nil
        var addressPreviewCoordinate: Coordinate? = nil
        var addressPreviewFitToken: Int = 0
        var isAddressGeocoding: Bool = false
        var isAddressSubwayMode: Bool = false
        var isAddressSubwaySearching: Bool = false
        var addressSubwayResults: [SubwayStation] = []
        var addressMatchedStation: TouristSpot?
        fileprivate let existingDetail: TravelPlanDetail?
        /// 현재 대기 중이거나 가장 최근에 요청된 번역이 "検索" 탭(searchKeyword)이 아닌 "カスタム" 탭 지하철 검색(addressTitle)에서
        /// 시작된 것인지 구분한다. `translateSearch`가 두 탭에서 공유하는 단일 Scope이므로, 번역 결과(`retranslatedQueryReady`)나
        /// Toast 액션 확인(`toastActionConfirmed`)이 돌아왔을 때 어느 탭의 검색어를 갱신·재검색해야 하는지 이 값으로 판단한다
        fileprivate var isAddressSubwayTranslateOrigin: Bool = false
        @Presents var alert: AlertState<Action.Alert>?

        public init(planId: UUID, dayIndex: Int, date: Date, detail: TravelPlanDetail?) {
            self.planId = planId
            self.dayIndex = dayIndex
            self.date = date
            self.existingDetail = detail
        }

        public enum Step: Equatable {
            case selectingSpot
            case configuringTime
        }

        public enum Tab: Equatable {
            case search
            case address
            case bookmark
        }

        var trimmedSearchKeyword: String {
            self.searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var durationMinutes: Int {
            let minutes = Calendar.current.dateComponents([.minute], from: self.startTime, to: self.endTime).minute ?? 0
            return max(minutes, 0)
        }

        var isSaveEnabled: Bool {
            self.isTimeUnset || self.endTime > self.startTime
        }

        var trimmedAddressTitle: String {
            self.addressTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var trimmedAddressInput: String {
            self.addressInput.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var isAddressConfirmEnabled: Bool {
            if self.isAddressSubwayMode {
                return self.addressMatchedStation != nil
            }
            guard self.addressSelectedCategory != nil else { return false }
            guard self.trimmedAddressTitle.isEmpty == false else { return false }
            guard self.addressPreviewCoordinate != nil else { return false }
            return true
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case tabSelected(State.Tab)
        case searchSubmitted
        case translateSearch(TranslateSearchFeature.Action)
        case spotRowTapped(TouristSpot)
        case subwayStationTapped(SubwayStation)
        case addressSubmitted
        case addressCategorySelected(CategoryType)
        case addressStationNameSubmitted
        case addressStationTapped(SubwayStation)
        case addressConfirmTapped
        case backButtonTapped
        case closeButtonTapped
        case saveButtonTapped
        case searchResultsResult([TouristSpot])
        case subwayResultsResult([SubwayStation])
        case bookmarksResult([Bookmark])
        case addressPreviewResult(Coordinate)
        case addressStationSearchResult([SubwayStation])
        case addressStationResolveResult(TouristSpot?)
        case addressNotFound
        case stationResolveFailed
        case saveFailed
        case spotAdded
        case alert(PresentationAction<Alert>)

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

            case .binding(\.searchKeyword):
                guard state.searchKeyword.isEmpty else { return .none }
                state.searchResults = []
                state.subwayResults = []
                state.hasSearched = false
                return .merge(
                    .cancel(id: CancelID.search),
                    .cancel(id: CancelID.subwaySearch)
                )

            case .binding(\.addressInput):
                state.addressPreviewCoordinate = nil
                return .none

            case .binding(\.addressTitle):
                guard state.isAddressSubwayMode else { return .none }
                state.addressMatchedStation = nil
                state.addressPreviewCoordinate = nil
                state.addressSubwayResults = []
                state.isAddressSubwaySearching = false
                return .cancel(id: CancelID.addressStationSearch)

            case .binding:
                return .none

            case .tabSelected(let tab):
                guard state.tab != tab else { return .none }
                state.tab = tab
                guard tab == .bookmark else { return .none }
                state.isBookmarkLoading = true
                return self.fetchBookmarksEffect()
                    .cancellable(id: CancelID.fetchBookmarks, cancelInFlight: true)

            case .searchSubmitted:
                let keyword = state.searchKeyword.trimmingCharacters(in: .whitespaces)
                guard keyword.isEmpty == false else { return .none }
                state.isSearchLoading = true
                state.hasSearched = true
                return .merge(
                    .send(.translateSearch(.reset)),
                    self.searchEffect(keyword: keyword)
                        .cancellable(id: CancelID.search, cancelInFlight: true),
                    self.subwaySearchEffect(keyword: keyword)
                        .cancellable(id: CancelID.subwaySearch, cancelInFlight: true)
                )

            case .spotRowTapped(let spot):
                state.selectedSpot = spot
                let range = TravelPlanDetailSpotScheduler.defaultTimeRange(
                    dayIndex: state.dayIndex,
                    date: state.date,
                    existingDetail: state.existingDetail
                )
                state.startTime = range.start
                state.endTime = range.end
                state.step = .configuringTime
                return .none

            case .subwayStationTapped(let station):
                return self.selectSubwayStationEffect(station: station)

            case .addressSubmitted:
                guard state.trimmedAddressInput.isEmpty == false, state.isAddressGeocoding == false else { return .none }
                state.isAddressGeocoding = true
                return self.addressPreviewEffect(address: state.trimmedAddressInput)

            case .addressCategorySelected(let category):
                if category == .subway {
                    guard state.isAddressSubwayMode == false else { return .none }
                    state.isAddressSubwayMode = true
                } else {
                    state.addressSelectedCategory = category
                    guard state.isAddressSubwayMode else { return .none }
                    state.isAddressSubwayMode = false
                }
                state.addressMatchedStation = nil
                state.addressPreviewCoordinate = nil
                state.addressSubwayResults = []
                return .none

            case .addressStationNameSubmitted:
                guard state.trimmedAddressTitle.isEmpty == false else { return .none }
                state.isAddressSubwaySearching = true
                state.addressSubwayResults = []
                return self.addressSubwaySearchEffect(keyword: state.trimmedAddressTitle)

            case .addressStationTapped(let station):
                return self.resolveAddressStationEffect(station: station)

            case .addressConfirmTapped:
                guard state.isAddressConfirmEnabled else { return .none }

                if state.isAddressSubwayMode {
                    guard let station = state.addressMatchedStation else { return .none }
                    return .send(.spotRowTapped(station))
                }

                guard
                    let category = state.addressSelectedCategory,
                    let coordinate = state.addressPreviewCoordinate
                else { return .none }
                let spot = TouristSpot(
                    id: "custom_" + UUID().uuidString,
                    title: state.trimmedAddressTitle,
                    thumbnailURLString: nil,
                    distanceMeters: nil,
                    contentType: category,
                    coordinate: coordinate,
                    isCustom: true,
                    address: state.trimmedAddressInput
                )
                return .send(.spotRowTapped(spot))

            case .backButtonTapped:
                state.selectedSpot = nil
                state.step = .selectingSpot
                return .none

            case .closeButtonTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }

            case .saveButtonTapped:
                guard
                    state.isSaveEnabled,
                    state.isSaving == false,
                    let spot = state.selectedSpot
                else { return .none }
                state.isSaving = true
                let order = TravelPlanDetailSpotScheduler.nextOrder(dayIndex: state.dayIndex, existingDetail: state.existingDetail)
                let detailSpot = TravelPlanDetailSpot(
                    id: UUID(),
                    dayIndex: state.dayIndex,
                    order: order,
                    category: spot.contentType,
                    title: spot.japaneseTitle,
                    subtitle: spot.koreanTitle,
                    startTime: state.isTimeUnset ? nil : state.startTime,
                    durationMinutes: state.isTimeUnset ? nil : state.durationMinutes,
                    contentId: spot.id,
                    coordinate: spot.coordinate,
                    thumbnailURLString: spot.thumbnailURLString,
                    isCustom: spot.isCustom,
                    isStation: spot.isStation,
                    address: spot.address
                )
                return self.saveEffect(planId: state.planId, spot: detailSpot)

            case .searchResultsResult(let results):
                state.searchResults = results
                state.isSearchLoading = false
                state.isAddressSubwayTranslateOrigin = false
                let hasResults = results.isEmpty == false || state.subwayResults.isEmpty == false
                return .send(.translateSearch(.searchCompleted(query: state.searchKeyword, hasResults: hasResults)))

            case .translateSearch(.translateButtonRequested(let query)):
                // translateSearch는 "検索" 탭·"カスタム" 탭(지하철) 양쪽이 공유하는 단일 Scope이므로, 실제로 어느 탭의
                // 검색어가 요청된 것인지를 여기서 판별해 isAddressSubwayTranslateOrigin에 기록해둔다. 아래 두 조건 중
                // 어느 쪽에도 해당하지 않으면(toastActionConfirmed로부터 재전송된 요청인데, 그사이 사용자가 탭을
                // 전환해 현재 탭 상태와 query의 출처 탭이 서로 달라진 경우) 기존 값을 그대로 유지해 origin이
                // 잘못 덮어써지지 않도록 한다
                let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
                if state.isAddressSubwayMode, trimmedQuery == state.trimmedAddressTitle {
                    state.isAddressSubwayTranslateOrigin = true
                } else if state.tab == .search, trimmedQuery == state.trimmedSearchKeyword {
                    state.isAddressSubwayTranslateOrigin = false
                }
                return .none

            case .translateSearch(.delegate(.toastActionConfirmed)):
                let query = state.isAddressSubwayTranslateOrigin ? state.trimmedAddressTitle : state.trimmedSearchKeyword
                return .send(.translateSearch(.translateButtonRequested(query: query)))

            case .translateSearch(.delegate(.retranslatedQueryReady(let translatedQuery))):
                if state.isAddressSubwayTranslateOrigin {
                    state.addressTitle = translatedQuery
                    return .send(.addressStationNameSubmitted)
                }
                state.searchKeyword = translatedQuery
                return .send(.searchSubmitted)

            case .translateSearch:
                return .none

            case .subwayResultsResult(let stations):
                state.subwayResults = stations
                return .none

            case .addressStationSearchResult(let stations):
                state.isAddressSubwaySearching = false
                state.addressSubwayResults = stations
                guard state.isAddressSubwayMode else { return .none }
                state.isAddressSubwayTranslateOrigin = true
                let hasResults = stations.isEmpty == false
                let searchCompletedEffect = Effect<Action>.send(
                    .translateSearch(.searchCompleted(query: state.trimmedAddressTitle, hasResults: hasResults))
                )
                guard hasResults == false else { return searchCompletedEffect }
                return .merge(self.showAddressStationSearchEmptyEffect(), searchCompletedEffect)

            case .addressStationResolveResult(let spot):
                guard let spot else { return .none }
                state.addressMatchedStation = spot
                state.addressPreviewCoordinate = spot.coordinate
                state.addressPreviewFitToken += 1
                state.addressSubwayResults = []
                return .none

            case .bookmarksResult(let bookmarks):
                state.bookmarks = bookmarks
                state.isBookmarkLoading = false
                return .none

            case .addressPreviewResult(let coordinate):
                state.isAddressGeocoding = false
                state.addressPreviewCoordinate = coordinate
                state.addressPreviewFitToken += 1
                return .none

            case .addressNotFound:
                state.isAddressGeocoding = false
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

            case .saveFailed:
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

            case .spotAdded:
                return .none

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - CancelID

private enum CancelID {
    case search
    case subwaySearch
    case resolveStation
    case fetchBookmarks
    case addressPreview
    case addressStationSearch
    case resolveAddressStation
}

// MARK: - Method

private extension PlanDetailAddSpotFeature {
    func searchEffect(keyword: String) -> Effect<Action> {
        .run { [touristSpotUseCase = self.touristSpotUseCase, toastCenter = self.toastCenter] send in
            do {
                let results = try await touristSpotUseCase.searchByKeyword(keyword: keyword, pageNo: 1)
                await send(.searchResultsResult(results))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "관광지 키워드 검색 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.searchResultsResult([]))
            }
        }
    }

    func subwaySearchEffect(keyword: String) -> Effect<Action> {
        .run { [subwayStationUseCase = self.subwayStationUseCase] send in
            let results = await subwayStationUseCase.search(keyword: keyword)
            guard !Task.isCancelled else { return }
            await send(.subwayResultsResult(results))
        }
    }

    func selectSubwayStationEffect(station: SubwayStation) -> Effect<Action> {
        .run { [subwayStationUseCase = self.subwayStationUseCase, toastCenter = self.toastCenter] send in
            do {
                let spot = try await subwayStationUseCase.selectStation(station)
                await send(.spotRowTapped(spot))
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

    func addressSubwaySearchEffect(keyword: String) -> Effect<Action> {
        .run { [subwayStationUseCase = self.subwayStationUseCase] send in
            let results = await subwayStationUseCase.search(keyword: keyword)
            guard !Task.isCancelled else { return }
            await send(.addressStationSearchResult(results))
        }
        .cancellable(id: CancelID.addressStationSearch, cancelInFlight: true)
    }

    /// "カスタム" 탭 지하철 검색 결과가 없을 때(빈 문자열 제출이 아닌, 실제 검색이 수행된 경우에 한해) 안내하는 Toast.
    /// "検索" 탭은 결과 없음 상태를 리스트 내 빈 상태 UI로 표시하지만, 이 탭의 지하철 검색 결과는 별도의 리스트 UI가
    /// 없어 결과가 사라졌다는 사실 자체를 알 수 없으므로 Toast로 안내한다
    func showAddressStationSearchEmptyEffect() -> Effect<Action> {
        .run { [toastCenter = self.toastCenter] _ in
            toastCenter.show(ToastItem(message: Strings.Map.searchResultEmptyTitle, type: .info))
        }
    }

    func resolveAddressStationEffect(station: SubwayStation) -> Effect<Action> {
        .run { [subwayStationUseCase = self.subwayStationUseCase, toastCenter = self.toastCenter] send in
            do {
                let spot = try await subwayStationUseCase.selectStation(station)
                await send(.addressStationResolveResult(spot))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.network.log(.error, "지하철역 좌표 조회 실패: \(station.koreanName) - \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.stationResolveFailed)
            }
        }
        .cancellable(id: CancelID.resolveAddressStation, cancelInFlight: true)
    }

    func addressPreviewEffect(address: String) -> Effect<Action> {
        .run { [naverGeocodingUseCase = self.naverGeocodingUseCase, toastCenter = self.toastCenter] send in
            do {
                let geocoded = try await naverGeocodingUseCase.geocode(address: address)
                await send(.addressPreviewResult(geocoded.coordinate))
            } catch TabiError.dataNotFound {
                AppLogger.view.log(.error, "일정 주소 추가 미리보기 실패: 주소를 찾을 수 없음")
                await send(.addressNotFound)
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "일정 주소 추가 미리보기 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.addressNotFound)
            }
        }
        .cancellable(id: CancelID.addressPreview, cancelInFlight: true)
    }

    func fetchBookmarksEffect() -> Effect<Action> {
        .run { [bookmarkUseCase = self.bookmarkUseCase, toastCenter = self.toastCenter] send in
            do {
                let bookmarks = try await bookmarkUseCase.fetch()
                await send(.bookmarksResult(bookmarks))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "북마크 목록 조회 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.bookmarksResult([]))
            }
        }
    }

    func saveEffect(planId: UUID, spot: TravelPlanDetailSpot) -> Effect<Action> {
        .run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase, toastCenter = self.toastCenter] send in
            do {
                try await travelPlanDetailUseCase.add(TravelPlanDetail(planId: planId, spots: [spot]))
                await send(.spotAdded)
            } catch {
                AppLogger.view.log(.error, "일정에 스팟 추가 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.saveFailed)
            }
        }
    }
}

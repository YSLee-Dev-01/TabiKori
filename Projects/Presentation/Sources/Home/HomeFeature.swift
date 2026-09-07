//
//  HomeFeature.swift
//  Presentation
//
//  Created by 이윤수 on 6/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import UIKit

import ComposableArchitecture
import Core
import Domain

// MARK: - HomeFeature

@Reducer
public struct HomeFeature: Sendable {

    @Dependency(\.locationUseCase) var locationUseCase
    @Dependency(\.exchangeRateUseCase) var exchangeRateUseCase
    @Dependency(\.touristSpotUseCase) var touristSpotUseCase
    @Dependency(\.festivalUseCase) var festivalUseCase
    @Dependency(\.travelPlanUseCase) var travelPlanUseCase
    @Dependency(\.homeSheetAnnounceUseCase) var homeSheetAnnounceUseCase
    @Dependency(\.analyticsCenter) var analyticsCenter

    private let nearbySpotRadiusMeters = TouristSpotSearchRadius.nearbyMeters
    private let festivalListLimit = 10

    @ObservableState
    public struct State: Equatable {
        var hasLoadedInitialSpots: Bool = false
        var currentDate: String = Date().homeDateTitle
        var locationStatus: LocationAuthorizationStatus = .denied
        var currentRegion: TravelRegion = .unsupported
        var nearbyTouristSpots: [TouristSpot] = []
        var nearbyRestaurants: [TouristSpot] = []
        var isLoadingTouristSpots: Bool = false
        var isLoadingRestaurants: Bool = false
        var festivals: [Festival] = []
        var isLoadingFestivals: Bool = false
        var krwAmountText: String = "1000"
        var jpyAmountText: String = "0"
        var exchangeRateUpdatedAtTitle: String = ""
        var ongoingMatchedPlan: TravelPlan?
        var ongoingMatchedPlanDayIndex: Int = 0
        var activeHomeAnnouncement: Announcement? = nil
        var homeAnnouncementSheetItem: Announcement? = nil
        fileprivate var krwToJPYRate: Double = 0
        fileprivate var hasLoadedInitialFestivals: Bool = false
        fileprivate var hasLoadedInitialHomeAnnouncement: Bool = false

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case refreshTriggered
        case requestLocationPermission
        case locationPermissionResult(LocationAuthorizationStatus)
        case regionResult(TravelRegion)
        case exchangeRateResult(KRWToJPYRate)
        case nearbyCoordinateResolved(Coordinate)
        case nearbyTouristSpotsResult([TouristSpot])
        case nearbyRestaurantsResult([TouristSpot])
        case festivalsResult([Festival])
        case festivalsFailed
        case travelPlansResult([TravelPlan])
        case homeSheetAnnounceResult(Announcement?)
        case planCreateButtonTapped
        case nearbySpotTapped(TouristSpot)
        case festivalTapped(Festival)
        case searchBarTapped
        case categoryTapped(CategoryType)
        case categoryCoordinateResolved(CategoryType, Coordinate)
        case festivalMoreButtonTapped
        case openSettingsButtonTapped
        /// 앱 내 설정 화면으로 진입 (iOS 설정 앱으로 이동하는 openSettingsButtonTapped와 다름)
        case settingButtonTapped
        case regionCardTapped(KoreanRegion)
        case moveToPlanButtonTapped
        case moveToToolBoxButtonTapped
        case homeAnnouncementCardTapped
        case homeAnnouncementSheetDismissed
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
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
                        let krwToJPYRate = try await exchangeRateUseCase.fetchKRWToJPYRate()
                        await send(.exchangeRateResult(krwToJPYRate))
                    } catch {
                        AppLogger.view.log(.error, "환율 조회 실패: \(error.localizedDescription)")
                    }
                }

                let festivalEffect: Effect<Action>
                if state.hasLoadedInitialFestivals {
                    festivalEffect = .none
                } else {
                    state.hasLoadedInitialFestivals = true
                    state.isLoadingFestivals = true
                    festivalEffect = self.fetchFestivalsEffect()
                }

                let homeAnnouncementEffect: Effect<Action>
                if state.hasLoadedInitialHomeAnnouncement {
                    homeAnnouncementEffect = .none
                } else {
                    state.hasLoadedInitialHomeAnnouncement = true
                    homeAnnouncementEffect = self.fetchHomeSheetAnnounceEffect()
                }

                return .merge(locationEffect, exchangeRateEffect, festivalEffect, homeAnnouncementEffect)

            case .refreshTriggered:
                state.locationStatus = self.locationUseCase.checkAuthorization()

                let festivalEffect: Effect<Action>
                if state.festivals.isEmpty {
                    state.isLoadingFestivals = true
                    festivalEffect = self.fetchFestivalsEffect()
                } else {
                    festivalEffect = .none
                }

                guard state.currentRegion.isKorea else {
                    guard state.locationStatus == .allowed else { return festivalEffect }
                    return .merge(festivalEffect, self.fetchRegionEffect())
                }
                state.isLoadingTouristSpots = true
                state.isLoadingRestaurants = true
                return .merge(self.fetchNearbySpotsEffect(), festivalEffect)

            case .requestLocationPermission:
                return .run { send in
                    let result = await self.locationUseCase.requestAuthorization()
                    await send(.locationPermissionResult(result))
                }

            case .locationPermissionResult(let status):
                state.locationStatus = status
                guard status == .allowed else { return .none }

                return .run { [locationUseCase = self.locationUseCase] send in
                    do {
                        let region = try await locationUseCase.fetchCurrentRegion()
                        await send(.regionResult(region))
                    } catch {
                        AppLogger.view.log(.error, "현재 지역 조회 실패: \(error.localizedDescription)")
                    }
                }

            case .regionResult(let region):
                state.currentRegion = region

                guard region.isKorea else {
                    state.ongoingMatchedPlan = nil
                    return .none
                }

                let travelPlansEffect = self.fetchTravelPlansEffect()

                guard state.hasLoadedInitialSpots == false else { return travelPlansEffect }
                state.hasLoadedInitialSpots = true

                state.isLoadingTouristSpots = true
                state.isLoadingRestaurants = true

                return .merge(self.fetchNearbySpotsEffect(), travelPlansEffect)

            case .exchangeRateResult(let krwToJPYRate):
                state.krwToJPYRate = krwToJPYRate.rate
                state.exchangeRateUpdatedAtTitle = krwToJPYRate.updatedAt.exchangeRateUpdatedAtTitle
                if let krw = Double(state.krwAmountText) {
                    state.jpyAmountText = String(format: "%.1f", krw * krwToJPYRate.rate)
                }
                return .none

            case .nearbyCoordinateResolved(let coordinate):
                return .merge(
                    self.fetchNearbyTouristSpotsEffect(coordinate: coordinate),
                    self.fetchNearbyRestaurantsEffect(coordinate: coordinate)
                )

            case .nearbyTouristSpotsResult(let spots):
                state.nearbyTouristSpots = spots
                state.isLoadingTouristSpots = false
                return .none

            case .nearbyRestaurantsResult(let spots):
                state.nearbyRestaurants = Array(spots.prefix(10))
                state.isLoadingRestaurants = false
                return .none

            case .festivalsResult(let festivals):
                state.festivals = festivals
                state.isLoadingFestivals = false
                return .none

            case .festivalsFailed:
                state.isLoadingFestivals = false
                state.hasLoadedInitialFestivals = false
                return .none

            case .travelPlansResult(let plans):
                guard case .korea(let region) = state.currentRegion,
                      let matchedPlan = self.ongoingMatchedPlan(in: plans, region: region) else {
                    state.ongoingMatchedPlan = nil
                    state.ongoingMatchedPlanDayIndex = 0
                    return .none
                }

                state.ongoingMatchedPlan = matchedPlan
                state.ongoingMatchedPlanDayIndex = self.dayIndex(for: matchedPlan)
                return .none

            case .planCreateButtonTapped:
                return .none

            case .nearbySpotTapped:
                return .none

            case .festivalTapped:
                return .none

            case .searchBarTapped:
                return .none

            case .categoryTapped(let category):
                self.analyticsCenter.log(.homeCategorySelected(category: category.rawValue))
                return .run { [locationUseCase = self.locationUseCase] send in
                    do {
                        let coordinate = try await locationUseCase.fetchCurrentCoordinate()
                        await send(.categoryCoordinateResolved(category, coordinate))
                    } catch {
                        guard !Task.isCancelled else {
                            AppLogger.view.log(.debug, "카테고리 검색 좌표 조회 취소됨")
                            return
                        }
                        AppLogger.view.log(.error, "카테고리 검색 좌표 조회 실패: \(error.localizedDescription)")
                        await send(.categoryCoordinateResolved(category, .seoulCityHall))
                    }
                }
                .cancellable(id: CancelID.categoryCoordinate, cancelInFlight: true)

            case .categoryCoordinateResolved:
                return .none

            case .festivalMoreButtonTapped:
                return .none

            case .openSettingsButtonTapped:
                return .run { _ in
                    guard let url = URL(string: UIApplication.openSettingsURLString) else {
                        AppLogger.view.log(.error, "설정 앱 URL 생성 실패")
                        return
                    }
                    await MainActor.run {
                        UIApplication.shared.open(url)
                    }
                }

            case .settingButtonTapped:
                return .none

            case .regionCardTapped:
                return .none

            case .moveToPlanButtonTapped:
                return .none

            case .moveToToolBoxButtonTapped:
                self.analyticsCenter.log(.currencyWidgetTapped)
                return .none

            case .homeSheetAnnounceResult(let announcement):
                state.activeHomeAnnouncement = announcement
                return .none

            case .homeAnnouncementCardTapped:
                state.homeAnnouncementSheetItem = state.activeHomeAnnouncement
                return .none

            case .homeAnnouncementSheetDismissed:
                state.homeAnnouncementSheetItem = nil
                return .none
            }
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case categoryCoordinate
    case nearbySpotsCoordinate
    case nearbyTouristSpots
    case nearbyRestaurants
}

// MARK: - Method

private extension HomeFeature {
    func fetchRegionEffect() -> Effect<Action> {
        .run { [locationUseCase = self.locationUseCase] send in
            do {
                let region = try await locationUseCase.fetchCurrentRegion()
                await send(.regionResult(region))
            } catch {
                AppLogger.view.log(.error, "현재 지역 조회 실패: \(error.localizedDescription)")
            }
        }
    }

    /// 가까운 관광지/음식점을 병렬로 조회한다. 좌표는 한 번만 조회해 두 요청에 공유한다
    /// (LocationRepository.fetchCurrentCoordinate()는 동시에 하나의 요청만 진행 가능해, 좌표 조회까지
    /// 각 이펙트에서 독립적으로 하면 둘 중 하나가 항상 "이미 위치 요청이 진행 중입니다" 에러로 실패한다).
    /// 좌표 조회 이후의 관광지/음식점 조회는 별개의 이펙트로 분리해 취소 스코프를 독립적으로 관리하는
    /// 것은 물론, 한쪽 요청이 실패하더라도 다른 쪽이 이미 보낸 결과를 되돌리지 않도록 한다.
    ///
    /// 이 이펙트는 `HomeView`의 `.refreshable`에서 트리거된다. `.refreshable { await store.send(...).finish() }`
    /// 처럼 `.finish()`로 완료를 대기하면, `.run` 안에서 `send`로 액션을 여러 단계 우회시켜도 그 결과 이펙트가
    /// 결국 원래 `_send` 호출의 tasks 배열에 재귀적으로 포함되어 새로고침 제스처의 Task 취소가 그대로
    /// 전파된다(TCA의 `Send`가 캡처하는 `tasks`가 상위 `_send` 스코프의 것이라서 이펙트 체인이 끊기지 않음).
    /// 그래서 액션 우회로는 취소 전파를 막을 수 없고, `HomeView`가 `.finish()`를 호출하지 않도록 하는 쪽으로
    /// 해결했다 — 자세한 내용은 `HomeView.swift`의 `.refreshable` 주석 참고
    func fetchNearbySpotsEffect() -> Effect<Action> {
        .run { [locationUseCase = self.locationUseCase] send in
            do {
                let coordinate = try await locationUseCase.fetchCurrentCoordinate()
                await send(.nearbyCoordinateResolved(coordinate))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "주변 관광정보 좌표 조회 취소됨")
                    return
                }
                await send(.nearbyTouristSpotsResult([]))
                await send(.nearbyRestaurantsResult([]))
                AppLogger.view.log(.error, "주변 관광정보 좌표 조회 실패: \(error.localizedDescription)")
            }
        }
        .cancellable(id: CancelID.nearbySpotsCoordinate, cancelInFlight: true)
    }

    func fetchNearbyTouristSpotsEffect(coordinate: Coordinate) -> Effect<Action> {
        .run { [
            touristSpotUseCase = self.touristSpotUseCase,
            radius = self.nearbySpotRadiusMeters
        ] send in
            do {
                let spots = try await touristSpotUseCase.fetchNearbySpots(
                    contentType: .sightseeing,
                    coordinate: coordinate,
                    radiusMeters: radius,
                    pageNo: 1
                )
                await send(.nearbyTouristSpotsResult(spots))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "주변 관광지 조회 취소됨")
                    return
                }
                await send(.nearbyTouristSpotsResult([]))
                AppLogger.view.log(.error, "주변 관광지 조회 실패: \(error.localizedDescription)")
            }
        }
        .cancellable(id: CancelID.nearbyTouristSpots, cancelInFlight: true)
    }

    func fetchNearbyRestaurantsEffect(coordinate: Coordinate) -> Effect<Action> {
        .run { [
            touristSpotUseCase = self.touristSpotUseCase,
            radius = self.nearbySpotRadiusMeters
        ] send in
            do {
                let spots = try await touristSpotUseCase.fetchNearbySpots(
                    contentType: .food,
                    coordinate: coordinate,
                    radiusMeters: radius,
                    pageNo: 1
                )
                await send(.nearbyRestaurantsResult(spots))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "주변 음식점 조회 취소됨")
                    return
                }
                await send(.nearbyRestaurantsResult([]))
                AppLogger.view.log(.error, "주변 음식점 조회 실패: \(error.localizedDescription)")
            }
        }
        .cancellable(id: CancelID.nearbyRestaurants, cancelInFlight: true)
    }

    func fetchFestivalsEffect() -> Effect<Action> {
        .run { [festivalUseCase = self.festivalUseCase, limit = self.festivalListLimit] send in
            do {
                let festivals = try await festivalUseCase.fetchFestivals(
                    startDate: Date(),
                    endDate: nil,
                    regionCode: nil,
                    sigunguCode: nil,
                    pageNo: 1
                )
                await send(.festivalsResult(Array(festivals.prefix(limit))))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "축제 조회 취소됨")
                    return
                }
                await send(.festivalsFailed)
                AppLogger.view.log(.error, "축제 조회 실패: \(error.localizedDescription)")
            }
        }
    }

    func fetchTravelPlansEffect() -> Effect<Action> {
        .run { [travelPlanUseCase = self.travelPlanUseCase] send in
            do {
                let plans = try await travelPlanUseCase.fetch()
                await send(.travelPlansResult(plans))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "여행 플랜 조회 취소됨")
                    return
                }
                await send(.travelPlansResult([]))
                AppLogger.view.log(.error, "여행 플랜 조회 실패: \(error.localizedDescription)")
            }
        }
    }

    func fetchHomeSheetAnnounceEffect() -> Effect<Action> {
        .run { [homeSheetAnnounceUseCase = self.homeSheetAnnounceUseCase] send in
            do {
                let announcement = try await homeSheetAnnounceUseCase.fetchActiveAnnouncement()
                await send(.homeSheetAnnounceResult(announcement))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "홈 시트 공지 조회 취소됨")
                    return
                }
                await send(.homeSheetAnnounceResult(nil))
                AppLogger.view.log(.error, "홈 시트 공지 조회 실패: \(error.localizedDescription)")
            }
        }
    }

    func ongoingMatchedPlan(in plans: [TravelPlan], region: KoreanRegion) -> TravelPlan? {
        plans
            .filter { $0.section == .ongoing && $0.region == region }
            .min { $0.startDate < $1.startDate }
    }

    func dayIndex(for plan: TravelPlan) -> Int {
        // 호출 시점에 이미 plan.section == .ongoing(오늘이 기간 내)임이 보장되므로
        // todayDayIndex는 항상 non-nil이어야 하지만, 방어적으로 0으로 폴백한다
        plan.todayDayIndex ?? 0
    }
}

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

// MARK: - NearbySpot (임시)

public struct NearbySpot: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let thumbnailURL: String?
    public let distanceMeters: Double?
    public let contentType: TourismContentType
    
    public init(id: String, title: String, thumbnailURL: String?, distanceMeters: Double?, contentType: TourismContentType) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.distanceMeters = distanceMeters
        self.contentType = contentType
    }
}

// MARK: - TourismContentType (임시)

public enum TourismContentType: String, Equatable, CaseIterable, Sendable {
    case touristSpot
    case culturalFacility
    case restaurant
    case shopping
    case festival
    case accommodation
    case leisure

    static let chipFilterItems: [Self] = [
        .touristSpot, .restaurant, .culturalFacility, .shopping
    ]
}

// MARK: - HomeFeature

@Reducer
public struct HomeFeature: Sendable {

    @Dependency(\.locationUseCase) var locationUseCase

    // 환율 API 연동 전까지 사용하는 임시 고정값 (1 KRW = 0.1073 JPY)
    private let mockExchangeRate: Double = 0.1073

    @ObservableState
    public struct State: Equatable {
        var currentDate: String = Date().homeDateTitle
        var locationStatus: LocationAuthorizationStatus = .denied
        var currentRegion: TravelRegion = .unsupported
        var nearbyTouristSpots: [NearbySpot] = NearbySpot.touristDummies
        var nearbyRestaurants: [NearbySpot] = NearbySpot.restaurantDummies
        var isLoadingTouristSpots: Bool = false
        var isLoadingRestaurants: Bool = false
        var krwAmountText: String = "1000"
        var jpyAmountText: String = "107.3"

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case requestLocationPermission
        case locationPermissionResult(LocationAuthorizationStatus)
        case regionResult(TravelRegion)
        case planCreateButtonTapped
        case nearbySpotTapped(NearbySpot)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.krwAmountText):
                if let krw = Double(state.krwAmountText) {
                    state.jpyAmountText = String(format: "%.1f", krw * self.mockExchangeRate)
                }
                return .none

            case .binding(\.jpyAmountText):
                if let jpy = Double(state.jpyAmountText) {
                    state.krwAmountText = String(format: "%.0f", jpy / self.mockExchangeRate)
                }
                return .none

            case .binding:
                return .none

            case .onAppear:
                state.locationStatus = self.locationUseCase.checkAuthorization()

                switch state.locationStatus {
                case .undetermined:
                    return .send(.requestLocationPermission)

                case .allowed:
                    return .run { [locationUseCase = self.locationUseCase] send in
                        try? await Task.sleep(for: .seconds(1))
                        do {
                            let region = try await locationUseCase.fetchCurrentRegion()
                            await send(.regionResult(region))
                        } catch {
                            AppLogger.view.log(.error, "현재 지역 조회 실패: \(error.localizedDescription)")
                        }
                    }

                case .denied:
                    return .none
                }

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
                return .none

            case .planCreateButtonTapped:
                return .none

            case .nearbySpotTapped:
                return .none
            }
        }
    }
}

// MARK: - NearbySpot Dummy

private extension NearbySpot {
    static let touristDummies: [NearbySpot] = [
        NearbySpot(id: "1", title: "景福宮", thumbnailURL: nil, distanceMeters: 320, contentType: .touristSpot),
        NearbySpot(id: "2", title: "ソウル市立美術館", thumbnailURL: nil, distanceMeters: 1200, contentType: .culturalFacility),
        NearbySpot(id: "3", title: "北村韓屋村", thumbnailURL: nil, distanceMeters: 680, contentType: .touristSpot),
    ]

    static let restaurantDummies: [NearbySpot] = [
        NearbySpot(id: "4", title: "土俗村サムゲタン", thumbnailURL: nil, distanceMeters: 430, contentType: .restaurant),
        NearbySpot(id: "5", title: "明洞餃子", thumbnailURL: nil, distanceMeters: 210, contentType: .restaurant),
        NearbySpot(id: "6", title: "広蔵市場", thumbnailURL: nil, distanceMeters: 890, contentType: .restaurant),
    ]
}

//
//  DetailFeature.swift
//  Presentation
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain
import Resource

public enum DetailTab: String, CaseIterable, Equatable {
    case info
    case photos
    case map

    var label: String {
        switch self {
        case .info: return Strings.Detail.tabInfo
        case .photos: return Strings.Detail.tabPhotos
        case .map: return Strings.Detail.tabMap
        }
    }
}

@Reducer
public struct DetailFeature {

    @Dependency(\.touristSpotUseCase) var touristSpotUseCase

    @ObservableState
    public struct State: Equatable {
        let touristSpot: TouristSpot
        var detail: TouristSpotDetail
        var intro: TouristSpotIntro
        var images: [TouristSpotImage] = []
        var selectedTab: DetailTab = .info
        var isSaved: Bool = false
        var currentImageIndex: Int = 0
        var isLoading: Bool = false
        fileprivate var hasStartedLoading: Bool = false
        fileprivate var hasReceivedDetail: Bool = false
        fileprivate var hasReceivedIntro: Bool = false
        fileprivate var hasReceivedImages: Bool = false

        public init(touristSpot: TouristSpot) {
            self.touristSpot = touristSpot
            self.detail = TouristSpotDetail(
                id: touristSpot.id,
                title: touristSpot.title,
                contentType: touristSpot.contentType,
                tel: nil,
                homepageURLString: nil,
                imageURLString: touristSpot.thumbnailURLString,
                address: "",
                coordinate: Coordinate(latitude: 0, longitude: 0),
                overview: nil
            )
            self.intro = .empty(for: touristSpot.contentType)
        }

        fileprivate var hasReceivedAllResults: Bool {
            self.hasReceivedDetail && self.hasReceivedIntro && self.hasReceivedImages
        }
    }

    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case tabSelected(DetailTab)
        case saveButtonTapped
        case photoCellTapped(index: Int)
        case detailResult(TouristSpotDetail?)
        case introResult(TouristSpotIntro?)
        case imagesResult([TouristSpotImage]?)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasStartedLoading == false else { return .none }
                state.hasStartedLoading = true
                state.isLoading = true
                return .merge(
                    self.fetchDetailEffect(contentId: state.touristSpot.id),
                    self.fetchIntroEffect(contentId: state.touristSpot.id, contentType: state.touristSpot.contentType),
                    self.fetchImagesEffect(contentId: state.touristSpot.id)
                )

            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none

            case .saveButtonTapped:
                state.isSaved.toggle()
                return .none

            case .photoCellTapped:
                return .none

            case .detailResult(let detail):
                if let detail { state.detail = detail }
                state.hasReceivedDetail = true
                state.isLoading = !state.hasReceivedAllResults
                return .none

            case .introResult(let intro):
                if let intro { state.intro = intro }
                state.hasReceivedIntro = true
                state.isLoading = !state.hasReceivedAllResults
                return .none

            case .imagesResult(let images):
                if let images { state.images = images }
                state.hasReceivedImages = true
                state.isLoading = !state.hasReceivedAllResults
                if state.images.isEmpty, state.selectedTab == .photos {
                    state.selectedTab = .info
                }
                return .none

            case .binding:
                return .none
            }
        }
    }
}

// MARK: - Method

private extension DetailFeature {
    func fetchDetailEffect(contentId: String) -> Effect<Action> {
        .run { [touristSpotUseCase = self.touristSpotUseCase] send in
            do {
                let detail = try await touristSpotUseCase.fetchDetail(contentId: contentId)
                await send(.detailResult(detail))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "관광지 상세 조회 실패: \(error.localizedDescription)")
                await send(.detailResult(nil))
            }
        }
    }

    func fetchIntroEffect(contentId: String, contentType: CategoryType) -> Effect<Action> {
        .run { [touristSpotUseCase = self.touristSpotUseCase] send in
            do {
                let intro = try await touristSpotUseCase.fetchIntro(contentId: contentId, contentType: contentType)
                await send(.introResult(intro))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "관광지 소개정보 조회 실패: \(error.localizedDescription)")
                await send(.introResult(nil))
            }
        }
    }

    func fetchImagesEffect(contentId: String) -> Effect<Action> {
        .run { [touristSpotUseCase = self.touristSpotUseCase] send in
            do {
                let images = try await touristSpotUseCase.fetchImages(contentId: contentId)
                await send(.imagesResult(images))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "관광지 이미지 조회 실패: \(error.localizedDescription)")
                await send(.imagesResult(nil))
            }
        }
    }
}

// MARK: - TouristSpotIntro Placeholder

private extension TouristSpotIntro {
    static func empty(for contentType: CategoryType) -> TouristSpotIntro {
        switch contentType {
        case .sightseeing:
            return .sightseeing(SightseeingIntro(
                contact: nil, openTime: nil, restDate: nil, parking: nil, openDate: nil,
                experienceGuide: nil, experienceAgeRange: nil, useSeason: nil, accommodationCount: nil
            ))
        case .nature:
            return .nature(NatureIntro(
                contact: nil, openTime: nil, restDate: nil, parking: nil, parkingFee: nil,
                reservation: nil, openPeriod: nil, useFee: nil, scale: nil,
                experienceAgeRange: nil, accommodationCount: nil
            ))
        case .food:
            return .food(FoodIntro(
                contact: nil, openTime: nil, restDate: nil, parking: nil, mainMenu: nil,
                menu: nil, seatCount: nil, smokingInfo: nil, reservation: nil,
                openDate: nil, scale: nil, licenseNumber: nil
            ))
        case .hotel:
            return .hotel(HotelIntro(
                contact: nil, parking: nil, checkInTime: nil, checkOutTime: nil, roomCount: nil,
                roomType: nil, cookingAvailable: nil, diningPlace: nil, pickupService: nil,
                reservation: nil, reservationURL: nil, subFacility: nil, scale: nil, accommodationCount: nil
            ))
        case .festival:
            return .festival(FestivalIntro(
                eventPlace: nil, startDate: nil, endDate: nil, playTime: nil, program: nil,
                useFee: nil, ageLimit: nil, bookingPlace: nil, homePage: nil, discountInfo: nil,
                sponsor: nil, sponsorTel: nil, coSponsor: nil, coSponsorTel: nil,
                placeInfo: nil, spendTime: nil, subEvent: nil
            ))
        case .shopping:
            return .shopping(ShoppingIntro(
                contact: nil, openTime: nil, restDate: nil, parking: nil, saleItems: nil,
                openDate: nil, fairDay: nil, restroom: nil, scale: nil, shopGuide: nil
            ))
        }
    }
}

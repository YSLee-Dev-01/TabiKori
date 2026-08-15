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
    @Dependency(\.naverMapUseCase) var naverMapUseCase
    @Dependency(\.bookmarkUseCase) var bookmarkUseCase

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
        var shareText: String? = nil
        fileprivate var hasStartedLoading: Bool = false
        fileprivate var hasReceivedDetail: Bool = false
        fileprivate var hasReceivedIntro: Bool = false
        fileprivate var hasReceivedImages: Bool = false
        fileprivate var hasDetailFailed: Bool = false
        fileprivate var hasIntroFailed: Bool = false
        fileprivate var hasImagesFailed: Bool = false
        @Presents var addToItineraryState: AddToItineraryFeature.State?

        public init(touristSpot: TouristSpot) {
            self.touristSpot = touristSpot
            self.detail = TouristSpotDetail(
                id: touristSpot.id,
                title: touristSpot.title,
                contentType: touristSpot.contentType,
                tel: nil,
                homepageURLString: nil,
                imageURLString: touristSpot.thumbnailURLString,
                address: touristSpot.isCustom ? (touristSpot.address ?? "") : "",
                coordinate: touristSpot.isCustom ? touristSpot.coordinate : .zero,
                overview: nil
            )
            self.intro = .empty(for: touristSpot.contentType)
        }

        fileprivate var hasReceivedAllResults: Bool {
            self.touristSpot.isCustom || (self.hasReceivedDetail && self.hasReceivedIntro && self.hasReceivedImages)
        }

        var loadFailed: Bool {
            self.touristSpot.isCustom == false
                && self.hasReceivedAllResults
                && self.hasDetailFailed && self.hasIntroFailed && self.hasImagesFailed
        }
    }

    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case onDisappear
        case tabSelected(DetailTab)
        case saveButtonTapped
        case photoCellTapped(index: Int)
        case mapSearchButtonTapped
        case routeDirectionsButtonTapped
        case addToItineraryButtonTapped
        case retryButtonTapped
        case detailResult(TouristSpotDetail)
        case detailFailed
        case introResult(TouristSpotIntro)
        case introFailed
        case imagesResult([TouristSpotImage])
        case imagesFailed
        case isBookmarkedResult(Bool)
        case addToItinerary(PresentationAction<AddToItineraryFeature.Action>)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasStartedLoading == false else { return .none }
                state.hasStartedLoading = true

                if state.touristSpot.isCustom {
                    state.isLoading = false
                    let shareURL = self.naverMapUseCase.makeShareURL(query: state.touristSpot.japaneseTitle)
                    state.shareText = Self.makeShareText(spot: state.touristSpot, address: state.detail.address, shareURL: shareURL)
                    return self.fetchIsBookmarkedEffect(contentId: state.touristSpot.id)
                }

                state.isLoading = true
                return .merge(
                    self.fetchDetailEffect(contentId: state.touristSpot.id),
                    self.fetchIntroEffect(contentId: state.touristSpot.id, contentType: state.touristSpot.contentType),
                    self.fetchImagesEffect(contentId: state.touristSpot.id),
                    self.fetchIsBookmarkedEffect(contentId: state.touristSpot.id)
                )

            case .onDisappear:
                state.addToItineraryState = nil
                return .none

            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none

            case .saveButtonTapped:
                if state.isSaved {
                    state.isSaved = false
                    return self.removeBookmarkEffect(contentId: state.touristSpot.id)
                        .cancellable(id: CancelID.bookmarkToggle, cancelInFlight: true)
                } else {
                    state.isSaved = true
                    return self.addBookmarkEffect(spot: state.touristSpot, address: state.detail.address)
                        .cancellable(id: CancelID.bookmarkToggle, cancelInFlight: true)
                }

            case .photoCellTapped:
                return .none

            case .mapSearchButtonTapped:
                return .run { [naverMapUseCase = self.naverMapUseCase, query = state.touristSpot.japaneseTitle] _ in
                    await naverMapUseCase.searchPlace(query: query)
                }

            case .routeDirectionsButtonTapped:
                return .run { [naverMapUseCase = self.naverMapUseCase, coordinate = state.detail.coordinate, name = state.detail.japaneseTitle] _ in
                    await naverMapUseCase.routeToDestination(coordinate: coordinate, destinationName: name)
                }

            case .addToItineraryButtonTapped:
                state.addToItineraryState = AddToItineraryFeature.State(
                    touristSpot: state.touristSpot,
                    address: state.detail.address
                )
                return .none

            case .retryButtonTapped:
                state.hasReceivedDetail = false
                state.hasReceivedIntro = false
                state.hasReceivedImages = false
                state.hasDetailFailed = false
                state.hasIntroFailed = false
                state.hasImagesFailed = false
                state.isLoading = true
                return .merge(
                    self.fetchDetailEffect(contentId: state.touristSpot.id),
                    self.fetchIntroEffect(contentId: state.touristSpot.id, contentType: state.touristSpot.contentType),
                    self.fetchImagesEffect(contentId: state.touristSpot.id)
                )

            case .detailResult(let detail):
                state.hasReceivedDetail = true
                state.isLoading = !state.hasReceivedAllResults
                state.detail = detail
                let shareURL = self.naverMapUseCase.makeShareURL(query: state.touristSpot.japaneseTitle)
                state.shareText = Self.makeShareText(spot: state.touristSpot, address: detail.address, shareURL: shareURL)
                return .none

            case .detailFailed:
                state.hasReceivedDetail = true
                state.hasDetailFailed = true
                state.isLoading = !state.hasReceivedAllResults
                return .none

            case .introResult(let intro):
                state.intro = intro
                state.hasReceivedIntro = true
                state.isLoading = !state.hasReceivedAllResults
                return .none

            case .introFailed:
                state.hasReceivedIntro = true
                state.hasIntroFailed = true
                state.isLoading = !state.hasReceivedAllResults
                return .none

            case .imagesResult(let images):
                state.images = images
                state.hasReceivedImages = true
                state.isLoading = !state.hasReceivedAllResults
                if state.images.isEmpty, state.selectedTab == .photos {
                    state.selectedTab = .info
                }
                return .none

            case .imagesFailed:
                state.hasReceivedImages = true
                state.hasImagesFailed = true
                state.isLoading = !state.hasReceivedAllResults
                return .none

            case .isBookmarkedResult(let isSaved):
                state.isSaved = isSaved
                return .none

            case .addToItinerary(.presented(.spotAdded)):
                state.addToItineraryState = nil
                return .none

            case .addToItinerary:
                return .none

            case .binding:
                return .none
            }
        }
        .ifLet(\.$addToItineraryState, action: \.addToItinerary) {
            AddToItineraryFeature()
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case bookmarkToggle
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
                await send(.detailFailed)
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
                await send(.introFailed)
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
                await send(.imagesFailed)
            }
        }
    }

    func fetchIsBookmarkedEffect(contentId: String) -> Effect<Action> {
        .run { [bookmarkUseCase = self.bookmarkUseCase] send in
            do {
                let isSaved = try await bookmarkUseCase.isBookmarked(contentId: contentId)
                await send(.isBookmarkedResult(isSaved))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.view.log(.error, "북마크 여부 조회 실패: \(error.localizedDescription)")
            }
        }
    }

    func addBookmarkEffect(spot: TouristSpot, address: String) -> Effect<Action> {
        .run { [bookmarkUseCase = self.bookmarkUseCase] send in
            let spotToSave = TouristSpot(
                id: spot.id,
                title: spot.title,
                thumbnailURLString: spot.thumbnailURLString,
                distanceMeters: spot.distanceMeters,
                contentType: spot.contentType,
                coordinate: spot.coordinate,
                isCustom: spot.isCustom,
                address: address.isEmpty ? spot.address : address
            )
            do {
                try await bookmarkUseCase.add(spotToSave)
                await send(.isBookmarkedResult(true))
            } catch {
                AppLogger.view.log(.error, "북마크 저장 실패: \(error.localizedDescription)")
                await send(.isBookmarkedResult(false))
            }
        }
    }

    func removeBookmarkEffect(contentId: String) -> Effect<Action> {
        .run { [bookmarkUseCase = self.bookmarkUseCase] send in
            do {
                try await bookmarkUseCase.remove(contentId: contentId)
                await send(.isBookmarkedResult(false))
            } catch {
                AppLogger.view.log(.error, "북마크 삭제 실패: \(error.localizedDescription)")
                await send(.isBookmarkedResult(true))
            }
        }
    }

    static func makeShareText(spot: TouristSpot, address: String, shareURL: URL?) -> String {
        var lines: [String] = []
        if let koreanTitle = spot.koreanTitle {
            lines.append("\(Strings.Detail.shareTitlePrefix) \(spot.japaneseTitle)（\(koreanTitle)）")
        } else {
            lines.append("\(Strings.Detail.shareTitlePrefix) \(spot.japaneseTitle)")
        }
        lines.append("\(Strings.Detail.shareAddressPrefix) \(address)")
        if let shareURL {
            lines.append("\(Strings.Detail.shareLinkPrefix) \(shareURL.absoluteString)")
        }
        return lines.joined(separator: "\n")
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

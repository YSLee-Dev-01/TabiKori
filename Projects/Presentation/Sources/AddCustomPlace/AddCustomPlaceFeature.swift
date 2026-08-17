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
    @Dependency(\.bookmarkUseCase) var bookmarkUseCase
    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
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
        @Presents var alert: AlertState<Action.Alert>?

        public init() {}

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
        case closeTapped
        case categorySelected(CategoryType)
        case confirmTapped
        case addressSubmitted
        case stationNameSubmitted
        case saveResult(Bool)
        case addressNotFound
        case addressPreviewResult(Coordinate)
        case stationSearchResult([SubwayStation])
        case subwayStationTapped(SubwayStation)
        case stationResolveResult(TouristSpot?)
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {}
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
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

            case .binding(\.isSubwayMode):
                state.matchedStation = nil
                state.previewCoordinate = nil
                state.subwayResults = []
                return .none

            case .binding:
                return .none

            case .closeTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }

            case .categorySelected(let category):
                state.selectedCategory = category
                return .none

            case .confirmTapped:
                guard state.isSaving == false, state.isConfirmEnabled else { return .none }

                if state.isSubwayMode {
                    guard let station = state.matchedStation else { return .none }
                    state.isSaving = true
                    return self.saveStationEffect(station: station)
                }

                guard let category = state.selectedCategory else { return .none }
                state.isSaving = true
                return self.saveEffect(
                    category: category,
                    title: state.trimmedTitle,
                    address: state.trimmedAddress
                )

            case .addressSubmitted:
                guard state.trimmedAddress.isEmpty == false else { return .none }
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
                state.previewCoordinate = coordinate
                state.previewFitToken += 1
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

            case .alert:
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
}

// MARK: - Method

private extension AddCustomPlaceFeature {
    func saveEffect(category: CategoryType, title: String, address: String) -> Effect<Action> {
        .run { [naverGeocodingUseCase = self.naverGeocodingUseCase, bookmarkUseCase = self.bookmarkUseCase] send in
            do {
                let geocoded = try await naverGeocodingUseCase.geocode(address: address)
                await send(.addressPreviewResult(geocoded.coordinate))
                let spot = TouristSpot(
                    id: "custom_" + UUID().uuidString,
                    title: title,
                    thumbnailURLString: nil,
                    distanceMeters: nil,
                    contentType: category,
                    coordinate: geocoded.coordinate,
                    isCustom: true,
                    address: geocoded.formattedAddress.isEmpty ? address : geocoded.formattedAddress
                )
                try await bookmarkUseCase.add(spot)
                await send(.saveResult(true))
            } catch TabiError.dataNotFound {
                AppLogger.view.log(.error, "커스텀 장소 주소 변환 실패: 주소를 찾을 수 없음")
                await send(.addressNotFound)
            } catch {
                AppLogger.view.log(.error, "커스텀 장소 저장 실패: \(error.localizedDescription)")
                await send(.saveResult(false))
            }
        }
        .cancellable(id: CancelID.save, cancelInFlight: true)
    }

    func saveStationEffect(station: TouristSpot) -> Effect<Action> {
        .run { [bookmarkUseCase = self.bookmarkUseCase] send in
            do {
                try await bookmarkUseCase.add(station)
                await send(.saveResult(true))
            } catch {
                AppLogger.view.log(.error, "지하철역 북마크 저장 실패: \(error.localizedDescription)")
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
        .run { [subwayStationUseCase = self.subwayStationUseCase] send in
            do {
                let spot = try await subwayStationUseCase.selectStation(station)
                await send(.stationResolveResult(spot))
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.network.log(.error, "지하철역 좌표 조회 실패: \(station.koreanName) - \(error.localizedDescription)")
            }
        }
        .cancellable(id: CancelID.resolveStation, cancelInFlight: true)
    }

    func addressPreviewEffect(address: String) -> Effect<Action> {
        .run { [naverGeocodingUseCase = self.naverGeocodingUseCase] send in
            do {
                let geocoded = try await naverGeocodingUseCase.geocode(address: address)
                await send(.addressPreviewResult(geocoded.coordinate))
            } catch TabiError.dataNotFound {
                AppLogger.view.log(.error, "커스텀 장소 주소 미리보기 실패: 주소를 찾을 수 없음")
                await send(.addressNotFound)
            } catch {
                AppLogger.view.log(.error, "커스텀 장소 주소 미리보기 실패: \(error.localizedDescription)")
            }
        }
        .cancellable(id: CancelID.preview, cancelInFlight: true)
    }
}

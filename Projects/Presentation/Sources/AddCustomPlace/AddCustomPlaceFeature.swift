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
    @Dependency(\.bookmarkUseCase) var bookmarkUseCase
    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
        var title: String = ""
        var address: String = ""
        var selectedCategory: CategoryType?
        var isSaving: Bool = false
        @Presents var alert: AlertState<Action.Alert>?

        public init() {}

        var trimmedTitle: String {
            self.title.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var trimmedAddress: String {
            self.address.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var isConfirmEnabled: Bool {
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
        case saveResult(Bool)
        case addressNotFound
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {}
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .closeTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }

            case .categorySelected(let category):
                state.selectedCategory = category
                return .none

            case .confirmTapped:
                guard
                    state.isSaving == false,
                    state.isConfirmEnabled,
                    let category = state.selectedCategory
                else { return .none }

                state.isSaving = true
                return self.saveEffect(
                    category: category,
                    title: state.trimmedTitle,
                    address: state.trimmedAddress
                )

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
}

// MARK: - Method

private extension AddCustomPlaceFeature {
    func saveEffect(category: CategoryType, title: String, address: String) -> Effect<Action> {
        .run { [naverGeocodingUseCase = self.naverGeocodingUseCase, bookmarkUseCase = self.bookmarkUseCase] send in
            do {
                let coordinate = try await naverGeocodingUseCase.geocode(address: address)
                let spot = TouristSpot(
                    id: "custom_" + UUID().uuidString,
                    title: title,
                    thumbnailURLString: nil,
                    distanceMeters: nil,
                    contentType: category,
                    coordinate: coordinate,
                    isCustom: true,
                    address: address
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
}

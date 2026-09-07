//
//  AddTravelPlanFeature.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain
import Resource

// MARK: - AddTravelPlanFeature

@Reducer
public struct AddTravelPlanFeature: Sendable {

    @Dependency(\.travelPlanUseCase) var travelPlanUseCase
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.analyticsCenter) var analyticsCenter

    @ObservableState
    public struct State: Equatable {
        var title: String = ""
        var selectedRegion: KoreanRegion? = nil
        var customRegionText: String = ""
        var emojiText: String = ""
        var startDate: Date? = nil
        var endDate: Date? = nil
        var isSaving: Bool = false
        @Presents var alert: AlertState<Action.Alert>?

        var trimmedTitle: String {
            self.title.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var isConfirmEnabled: Bool {
            guard !self.trimmedTitle.isEmpty else { return false }
            guard let region = self.selectedRegion else { return false }
            if region == .etc, self.customRegionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return false
            }
            guard self.startDate != nil, self.endDate != nil else { return false }
            return true
        }

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case closeTapped
        case regionSelected(KoreanRegion)
        case confirmTapped
        case saveResult(Bool)
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

            case .regionSelected(let region):
                state.selectedRegion = region
                if region != .etc {
                    state.customRegionText = ""
                }
                if let emoji = region.emoji {
                    state.emojiText = emoji
                }
                return .none

            case .confirmTapped:
                guard
                    state.isSaving == false,
                    state.isConfirmEnabled,
                    let region = state.selectedRegion,
                    let startDate = state.startDate,
                    let endDate = state.endDate,
                    startDate <= endDate
                else { return .none }

                state.isSaving = true
                let customRegionText = state.customRegionText.trimmingCharacters(in: .whitespacesAndNewlines)
                let plan = TravelPlan(
                    id: UUID(),
                    title: state.trimmedTitle,
                    region: region,
                    customRegionText: region == .etc ? customRegionText : nil,
                    customEmoji: state.emojiText.isEmpty ? nil : state.emojiText,
                    startDate: startDate,
                    endDate: endDate
                )
                return self.saveEffect(plan: plan)

            case .saveResult(true):
                self.analyticsCenter.log(.travelPlanCreated)
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

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Method

private extension AddTravelPlanFeature {
    func saveEffect(plan: TravelPlan) -> Effect<Action> {
        .run { [travelPlanUseCase = self.travelPlanUseCase] send in
            do {
                try await travelPlanUseCase.add(plan)
                await send(.saveResult(true))
            } catch {
                AppLogger.view.log(.error, "일정 저장 실패: \(error.localizedDescription)")
                await send(.saveResult(false))
            }
        }
    }
}

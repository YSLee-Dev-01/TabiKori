//
//  PlanDetailEditFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain
import Resource

/// 플랜 자체(이름/날짜) 수정 시트. 날짜 축소 시 확인 알럿 후 초과 dayIndex 스팟을 일괄 삭제한다
@Reducer
public struct PlanDetailEditFeature: Sendable {

    @Dependency(\.travelPlanUseCase) var travelPlanUseCase
    @Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase
    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
        var title: String
        var startDate: Date?
        var endDate: Date?
        var isSaving: Bool = false
        fileprivate let plan: TravelPlan
        @Presents var alert: AlertState<Action.Alert>?

        public init(plan: TravelPlan) {
            self.plan = plan
            self.title = plan.title
            self.startDate = plan.startDate
            self.endDate = plan.endDate
        }

        var trimmedTitle: String {
            self.title.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var isConfirmEnabled: Bool {
            guard !self.trimmedTitle.isEmpty else { return false }
            return self.startDate != nil && self.endDate != nil
        }

        var currentDayCount: Int {
            self.plan.dayCount
        }

        var newDayCount: Int? {
            guard let startDate, let endDate else { return nil }
            return TravelPlan.dayCount(startDate: startDate, endDate: endDate)
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case closeButtonTapped
        case confirmButtonTapped
        case planUpdated(TravelPlan)
        case saveFailed
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {
            case shrinkConfirmed
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .closeButtonTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }

            case .confirmButtonTapped:
                guard
                    state.isSaving == false,
                    state.isConfirmEnabled,
                    let startDate = state.startDate,
                    let endDate = state.endDate,
                    startDate <= endDate,
                    let newDayCount = state.newDayCount
                else { return .none }

                let updatedPlan = TravelPlan(
                    id: state.plan.id,
                    title: state.trimmedTitle,
                    region: state.plan.region,
                    customRegionText: state.plan.customRegionText,
                    customEmoji: state.plan.customEmoji,
                    startDate: startDate,
                    endDate: endDate
                )

                if newDayCount >= state.currentDayCount {
                    state.isSaving = true
                    return self.saveEffect(plan: updatedPlan)
                        .cancellable(id: CancelID.save)
                }

                state.alert = AlertState {
                    TextState(Strings.Plan.dayShrinkAlertTitle)
                } actions: {
                    ButtonState(role: .destructive, action: .shrinkConfirmed) {
                        TextState(Strings.Plan.alertConfirm)
                    }
                    ButtonState(role: .cancel) {
                        TextState(Strings.Plan.alertCancel)
                    }
                } message: {
                    TextState(Strings.Plan.dayShrinkAlertMessage(newDayCount + 1))
                }
                return .none

            case .alert(.presented(.shrinkConfirmed)):
                guard
                    let startDate = state.startDate,
                    let endDate = state.endDate,
                    let newDayCount = state.newDayCount
                else { return .none }

                let updatedPlan = TravelPlan(
                    id: state.plan.id,
                    title: state.trimmedTitle,
                    region: state.plan.region,
                    customRegionText: state.plan.customRegionText,
                    customEmoji: state.plan.customEmoji,
                    startDate: startDate,
                    endDate: endDate
                )
                state.isSaving = true
                return self.shrinkAndSaveEffect(plan: updatedPlan, fromDayIndex: newDayCount)
                    .cancellable(id: CancelID.save)

            case .alert:
                return .none

            case .planUpdated:
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

private extension PlanDetailEditFeature {
    func saveEffect(plan: TravelPlan) -> Effect<Action> {
        .run { [travelPlanUseCase = self.travelPlanUseCase] send in
            do {
                try await travelPlanUseCase.update(plan)
                await send(.planUpdated(plan))
            } catch {
                AppLogger.view.log(.error, "일정 수정 실패 (planId: \(plan.id)): \(error.localizedDescription)")
                await send(.saveFailed)
            }
        }
    }

    func shrinkAndSaveEffect(plan: TravelPlan, fromDayIndex: Int) -> Effect<Action> {
        .run { [travelPlanUseCase = self.travelPlanUseCase, travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in
            do {
                try await travelPlanDetailUseCase.removeSpots(planId: plan.id, fromDayIndex: fromDayIndex)
                try await travelPlanUseCase.update(plan)
                await send(.planUpdated(plan))
            } catch {
                AppLogger.view.log(.error, "일정 수정(날짜 축소) 실패 (planId: \(plan.id)): \(error.localizedDescription)")
                await send(.saveFailed)
            }
        }
    }
}

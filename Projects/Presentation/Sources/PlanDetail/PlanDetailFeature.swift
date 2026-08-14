//
//  PlanDetailFeature.swift
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

/// 일정 상세 화면. NavigationBar와 일자 선택 탭, 선택된 날짜의 스팟 목록 표시 + 스와이프 삭제를 담당한다
@Reducer
public struct PlanDetailFeature: Sendable {

    @Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase

    @ObservableState
    public struct State: Equatable {
        var plan: TravelPlan
        var travelPlanDetail: TravelPlanDetail?
        var selectedDayIndex: Int = 0
        var isEditing: Bool = false
        var editingSpots: [TravelPlanDetailSpot] = []
        var isSaving: Bool = false
        var dayMapFitToken: Int = 0
        fileprivate var hasStartedLoading: Bool = false
        @Presents var addSpotState: PlanDetailAddSpotFeature.State?
        @Presents var editPlanState: PlanDetailEditFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        public init(plan: TravelPlan, initialDayIndex: Int = 0) {
            self.plan = plan
            self.selectedDayIndex = min(max(initialDayIndex, 0), plan.dayCount - 1)
        }

        var selectedDaySpots: [TravelPlanDetailSpot] {
            guard let spots = self.travelPlanDetail?.spots else { return [] }
            return spots
                .filter { $0.dayIndex == self.selectedDayIndex }
                .sorted { $0.order < $1.order }
        }

        var displayedSpots: [TravelPlanDetailSpot] {
            self.isEditing ? self.editingSpots : self.selectedDaySpots
        }
    }

    public enum Action: Equatable {
        case onAppear
        case dayButtonTapped(index: Int)
        case spotDeleteButtonTapped(id: UUID)
        case addSpotButtonTapped
        case spotRowTapped(TravelPlanDetailSpot)
        case planEditMenuButtonTapped
        case editButtonTapped
        case editCancelButtonTapped
        case editSaveButtonTapped
        case spotMovedInEditMode(source: IndexSet, destination: Int)
        case spotDeletedInEditMode(at: IndexSet)
        case travelPlanDetailResult(TravelPlanDetail?)
        case spotDeleted(id: UUID)
        case spotDeleteFailed
        case editSaveResult(TravelPlanDetail?)
        case addSpot(PresentationAction<PlanDetailAddSpotFeature.Action>)
        case editPlan(PresentationAction<PlanDetailEditFeature.Action>)
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {}
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasStartedLoading == false else { return .none }
                state.hasStartedLoading = true
                return self.fetchTravelPlanDetailEffect(id: state.plan.id)

            case .dayButtonTapped(let index):
                state.selectedDayIndex = index
                if self.hasValidCoordinateSpots(dayIndex: index, in: state) {
                    state.dayMapFitToken += 1
                }
                return .none

            case .spotDeleteButtonTapped(let id):
                return self.removeSpotEffect(planId: state.plan.id, spotId: id)

            case .editButtonTapped:
                state.isEditing = true
                state.editingSpots = state.selectedDaySpots
                return .none

            case .editCancelButtonTapped:
                state.isEditing = false
                state.editingSpots = []
                state.isSaving = false
                return .cancel(id: CancelID.saveEditedSpots)

            case .editSaveButtonTapped:
                guard state.isSaving == false else { return .none }
                state.isSaving = true
                return self.saveEditedSpotsEffect(
                    planId: state.plan.id,
                    dayIndex: state.selectedDayIndex,
                    orderedSpotIds: state.editingSpots.map(\.id)
                )
                .cancellable(id: CancelID.saveEditedSpots)

            case .spotMovedInEditMode(let source, let destination):
                state.editingSpots.move(fromOffsets: source, toOffset: destination)
                return .none

            case .spotDeletedInEditMode(let indexSet):
                state.editingSpots.remove(atOffsets: indexSet)
                return .none

            case .addSpotButtonTapped:
                guard state.plan.dayDates.indices.contains(state.selectedDayIndex) else { return .none }
                state.addSpotState = PlanDetailAddSpotFeature.State(
                    planId: state.plan.id,
                    dayIndex: state.selectedDayIndex,
                    date: state.plan.dayDates[state.selectedDayIndex],
                    detail: state.travelPlanDetail
                )
                return .none

            case .spotRowTapped:
                return .none

            case .planEditMenuButtonTapped:
                state.editPlanState = PlanDetailEditFeature.State(plan: state.plan)
                return .none

            case .travelPlanDetailResult(let detail):
                state.travelPlanDetail = detail
                if self.hasValidCoordinateSpots(dayIndex: state.selectedDayIndex, in: state) {
                    state.dayMapFitToken += 1
                }
                return .none

            case .spotDeleted(let id):
                guard let detail = state.travelPlanDetail else { return .none }
                state.travelPlanDetail = TravelPlanDetail(
                    planId: detail.planId,
                    spots: detail.spots.filter { $0.id != id }
                )
                return .none

            case .spotDeleteFailed:
                state.alert = AlertState {
                    TextState(Strings.Plan.spotDeleteFailedAlertTitle)
                } actions: {
                    ButtonState {
                        TextState(Strings.Plan.alertConfirm)
                    }
                } message: {
                    TextState(Strings.Plan.spotDeleteFailedAlertMessage)
                }
                return .none

            case .editSaveResult(let detail):
                state.isSaving = false
                if let detail {
                    state.isEditing = false
                    state.editingSpots = []
                    state.travelPlanDetail = detail
                } else {
                    state.alert = AlertState {
                        TextState(Strings.Plan.saveFailedAlertTitle)
                    } actions: {
                        ButtonState {
                            TextState(Strings.Plan.alertConfirm)
                        }
                    } message: {
                        TextState(Strings.Plan.saveFailedAlertMessage)
                    }
                }
                return .none

            case .addSpot(.presented(.spotAdded)):
                state.addSpotState = nil
                return self.fetchTravelPlanDetailEffect(id: state.plan.id)

            case .addSpot:
                return .none

            case .editPlan(.presented(.planUpdated(let plan))):
                state.plan = plan
                state.selectedDayIndex = min(state.selectedDayIndex, plan.dayCount - 1)
                state.isEditing = false
                state.editingSpots = []
                state.isSaving = false
                state.editPlanState = nil
                return .merge(
                    .cancel(id: CancelID.saveEditedSpots),
                    self.fetchTravelPlanDetailEffect(id: plan.id)
                )

            case .editPlan:
                return .none

            case .alert:
                return .none
            }
        }
        .ifLet(\.$addSpotState, action: \.addSpot) {
            PlanDetailAddSpotFeature()
        }
        .ifLet(\.$editPlanState, action: \.editPlan) {
            PlanDetailEditFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - CancelID

private enum CancelID {
    case saveEditedSpots
}

// MARK: - Method

private extension PlanDetailFeature {
    func hasValidCoordinateSpots(dayIndex: Int, in state: State) -> Bool {
        guard let spots = state.travelPlanDetail?.spots else { return false }
        return spots.contains { $0.dayIndex == dayIndex && $0.coordinate.isValid }
    }

    func fetchTravelPlanDetailEffect(id: UUID) -> Effect<Action> {
        .run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in
            do {
                let detail = try await travelPlanDetailUseCase.fetch(planId: id)
                await send(.travelPlanDetailResult(detail))
            } catch {
                AppLogger.view.log(.error, "일정 상세(TravelPlanDetail) 조회 실패: \(error.localizedDescription)")
                await send(.travelPlanDetailResult(nil))
            }
        }
    }

    func removeSpotEffect(planId: UUID, spotId: UUID) -> Effect<Action> {
        .run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in
            do {
                try await travelPlanDetailUseCase.removeSpot(planId: planId, spotId: spotId)
                await send(.spotDeleted(id: spotId))
            } catch {
                AppLogger.view.log(.error, "일정 상세 스팟 삭제 실패 (planId: \(planId), spotId: \(spotId)): \(error.localizedDescription)")
                await send(.spotDeleteFailed)
            }
        }
    }

    func saveEditedSpotsEffect(planId: UUID, dayIndex: Int, orderedSpotIds: [UUID]) -> Effect<Action> {
        .run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in
            do {
                try await travelPlanDetailUseCase.saveEditedSpots(planId: planId, dayIndex: dayIndex, orderedSpotIds: orderedSpotIds)
                let detail = try await travelPlanDetailUseCase.fetch(planId: planId)
                await send(.editSaveResult(detail))
            } catch {
                AppLogger.view.log(.error, "일정 상세 스팟 편집 저장 실패 (planId: \(planId), dayIndex: \(dayIndex)): \(error.localizedDescription)")
                await send(.editSaveResult(nil))
            }
        }
    }
}

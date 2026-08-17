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
    @Dependency(\.travelPlanShareUseCase) var travelPlanShareUseCase

    @ObservableState
    public struct State: Equatable {
        var plan: TravelPlan
        var travelPlanDetail: TravelPlanDetail?
        var selectedDayIndex: Int = 0
        var isEditing: Bool = false
        var editingSpots: [TravelPlanDetailSpot] = []
        var isSaving: Bool = false
        var dayMapFitToken: Int = 0
        var isFullOverview: Bool = false
        var visibleDayIndex: Int = 0
        var shareFileURL: URL?
        fileprivate var hasStartedLoading: Bool = false
        @Presents var addSpotState: PlanDetailAddSpotFeature.State?
        @Presents var editPlanState: PlanDetailEditFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        public init(plan: TravelPlan, initialDayIndex: Int = 0) {
            self.plan = plan
            self.selectedDayIndex = min(max(initialDayIndex, 0), plan.dayCount - 1)
            self.visibleDayIndex = self.selectedDayIndex
        }

        func spots(forDay dayIndex: Int) -> [TravelPlanDetailSpot] {
            guard let spots = self.travelPlanDetail?.spots else { return [] }
            return spots
                .filter { $0.dayIndex == dayIndex }
                .sorted { $0.order < $1.order }
        }

        var selectedDaySpots: [TravelPlanDetailSpot] {
            self.spots(forDay: self.selectedDayIndex)
        }

        var displayedSpots: [TravelPlanDetailSpot] {
            self.isEditing ? self.editingSpots : self.selectedDaySpots
        }

        var mapMarkerSpots: [TravelPlanDetailSpot] {
            self.isFullOverview ? self.spots(forDay: self.visibleDayIndex) : self.displayedSpots
        }
    }

    public enum Action: Equatable {
        case onAppear
        case dayButtonTapped(index: Int)
        case spotDeleteButtonTapped(id: UUID)
        case addSpotButtonTapped
        case spotRowTapped(TravelPlanDetailSpot)
        case travelItemsButtonTapped
        case planEditMenuButtonTapped
        case editButtonTapped
        case editCancelButtonTapped
        case editSaveButtonTapped
        case fullOverviewToggleTapped
        case visibleDayIndexChanged(Int)
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
                guard state.isFullOverview == false else { return .none }
                state.isEditing = true
                state.editingSpots = state.selectedDaySpots
                return .none

            case .editCancelButtonTapped:
                state.isEditing = false
                state.editingSpots = []
                state.isSaving = false
                return .cancel(id: CancelID.saveEditedSpots)

            case .fullOverviewToggleTapped:
                guard state.isEditing == false else { return .none }
                if state.isFullOverview {
                    state.selectedDayIndex = state.visibleDayIndex
                } else {
                    state.visibleDayIndex = state.selectedDayIndex
                }
                state.isFullOverview.toggle()
                return .none

            case .visibleDayIndexChanged(let index):
                guard state.visibleDayIndex != index else { return .none }
                state.visibleDayIndex = index
                if self.hasValidCoordinateSpots(dayIndex: index, in: state) {
                    state.dayMapFitToken += 1
                }
                return .none

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

            case .travelItemsButtonTapped:
                return .none

            case .planEditMenuButtonTapped:
                state.editPlanState = PlanDetailEditFeature.State(plan: state.plan)
                return .none

            case .travelPlanDetailResult(let detail):
                state.travelPlanDetail = detail
                if self.hasValidCoordinateSpots(dayIndex: state.selectedDayIndex, in: state) {
                    state.dayMapFitToken += 1
                }
                self.updateShareFileURL(state: &state)
                return .none

            case .spotDeleted(let id):
                guard let detail = state.travelPlanDetail else { return .none }
                state.travelPlanDetail = TravelPlanDetail(
                    planId: detail.planId,
                    spots: detail.spots.filter { $0.id != id }
                )
                self.updateShareFileURL(state: &state)
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
                    self.updateShareFileURL(state: &state)
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
                state.visibleDayIndex = min(state.visibleDayIndex, plan.dayCount - 1)
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

    /// 현재 상태의 plan/detail을 JSON으로 인코딩해 임시 디렉토리에 파일로 쓰고, 그 URL을 shareFileURL에 저장한다.
    /// 인코딩/파일쓰기 실패 시 로그만 남기고 shareFileURL은 nil로 유지한다
    func updateShareFileURL(state: inout State) {
        guard let detail = state.travelPlanDetail else {
            state.shareFileURL = nil
            return
        }
        do {
            let data = try self.travelPlanShareUseCase.exportData(plan: state.plan, detail: detail)
            let sanitizedTitle = state.plan.title.replacingOccurrences(of: "/", with: "-")
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(sanitizedTitle).json")
            try data.write(to: fileURL, options: .atomic)
            state.shareFileURL = fileURL
        } catch {
            AppLogger.view.log(.error, "일정 공유 파일 생성 실패 (planId: \(state.plan.id)): \(error.localizedDescription)")
            state.shareFileURL = nil
        }
    }
}

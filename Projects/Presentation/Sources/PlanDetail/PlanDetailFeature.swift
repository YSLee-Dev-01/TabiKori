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

    @Dependency(\.travelPlanUseCase) var travelPlanUseCase
    @Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase
    @Dependency(\.travelPlanShareUseCase) var travelPlanShareUseCase
    @Dependency(\.shoppingPlanItemUseCase) var shoppingPlanItemUseCase
    @Dependency(\.toolBarItemUseCase) var toolBarItemUseCase
    @Dependency(\.dismiss) var dismiss

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
        @Presents var timeEditState: PlanDetailTimeEditFeature.State?
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
        case spotEditRowTapped(TravelPlanDetailSpot)
        case toolBarButtonTapped
        case shoppingListButtonTapped
        case fullMapButtonTapped
        case planEditMenuButtonTapped
        case deleteMenuButtonTapped
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
        case shareFileURLResult(URL?)
        case planDeleteResult(Bool)
        case addSpot(PresentationAction<PlanDetailAddSpotFeature.Action>)
        case editPlan(PresentationAction<PlanDetailEditFeature.Action>)
        case timeEdit(PresentationAction<PlanDetailTimeEditFeature.Action>)
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {
            case deleteConfirmed
        }
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

            case .spotEditRowTapped(let spot):
                guard state.plan.dayDates.indices.contains(state.selectedDayIndex) else { return .none }
                state.timeEditState = PlanDetailTimeEditFeature.State(
                    planId: state.plan.id,
                    planTitle: state.plan.title,
                    dayTitle: Strings.Plan.dayChipTitle(state.selectedDayIndex + 1),
                    dateTitle: state.plan.dayDates[state.selectedDayIndex].planDayHeaderTitle,
                    spot: spot
                )
                return .none

            case .toolBarButtonTapped:
                return .none

            case .shoppingListButtonTapped:
                // TabBarFeature가 상위(.path)에서 가로채 쇼핑 리스트 화면으로 push한다 (toolBarButtonTapped와 동일 패턴)
                return .none

            case .fullMapButtonTapped:
                // TabBarFeature가 상위(.path)에서 가로채 지도 전체화면으로 push한다 (toolBarButtonTapped와 동일 패턴)
                return .none

            case .planEditMenuButtonTapped:
                state.editPlanState = PlanDetailEditFeature.State(plan: state.plan)
                return .none

            case .deleteMenuButtonTapped:
                state.alert = AlertState {
                    TextState(Strings.Plan.planDeleteAlertTitle)
                } actions: {
                    ButtonState(role: .destructive, action: .deleteConfirmed) {
                        TextState(Strings.Plan.alertConfirm)
                    }
                    ButtonState(role: .cancel) {
                        TextState(Strings.Plan.alertCancel)
                    }
                } message: {
                    TextState(Strings.Plan.planDeleteAlertMessage)
                }
                return .none

            case .travelPlanDetailResult(let detail):
                state.travelPlanDetail = detail
                if self.hasValidCoordinateSpots(dayIndex: state.selectedDayIndex, in: state) {
                    state.dayMapFitToken += 1
                }
                return self.updateShareFileURLEffect(planId: state.plan.id, plan: state.plan, detail: detail)

            case .spotDeleted(let id):
                guard let detail = state.travelPlanDetail else { return .none }
                let updatedDetail = TravelPlanDetail(
                    planId: detail.planId,
                    spots: detail.spots.filter { $0.id != id }
                )
                state.travelPlanDetail = updatedDetail
                return self.updateShareFileURLEffect(planId: state.plan.id, plan: state.plan, detail: updatedDetail)

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
                    return self.updateShareFileURLEffect(planId: state.plan.id, plan: state.plan, detail: detail)
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

            case .shareFileURLResult(let url):
                state.shareFileURL = url
                return .none

            case .planDeleteResult(true):
                return .run { [dismiss = self.dismiss] _ in await dismiss() }

            case .planDeleteResult(false):
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

            case .timeEdit(.presented(.timeSaved)):
                state.timeEditState = nil
                return self.fetchTravelPlanDetailEffect(id: state.plan.id)

            case .timeEdit:
                return .none

            case .alert(.presented(.deleteConfirmed)):
                return self.removePlanEffect(planId: state.plan.id)

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
        .ifLet(\.$timeEditState, action: \.timeEdit) {
            PlanDetailTimeEditFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - CancelID

private enum CancelID {
    case saveEditedSpots
    case updateShareFileURL
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

    /// 현재 상태의 plan/detail(+ 쇼핑/준비물 리스트)을 JSON으로 인코딩해 임시 디렉토리에 파일로 쓰고, 그 URL을 shareFileURLResult로 보낸다.
    /// 쇼핑/준비물 리스트는 별도 UseCase로 비동기 조회해야 하므로 effect로 구성된다.
    /// 인코딩/파일쓰기/조회 실패 시 로그만 남기고 shareFileURL은 nil로 유지한다
    func updateShareFileURLEffect(planId: UUID, plan: TravelPlan, detail: TravelPlanDetail?) -> Effect<Action> {
        guard let detail else {
            return .send(.shareFileURLResult(nil))
        }
        return .run { [
            shoppingPlanItemUseCase = self.shoppingPlanItemUseCase,
            toolBarItemUseCase = self.toolBarItemUseCase,
            travelPlanShareUseCase = self.travelPlanShareUseCase
        ] send in
            do {
                let shoppingItems = try await shoppingPlanItemUseCase.fetchSavedItems(planId: planId)
                let toolBarItems = try await toolBarItemUseCase.fetchSavedItems(planId: planId)
                let data = try travelPlanShareUseCase.exportData(
                    plan: plan,
                    detail: detail,
                    shoppingItems: shoppingItems,
                    toolBarItems: toolBarItems
                )
                let sanitizedTitle = plan.title.replacingOccurrences(of: "/", with: "-")
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(sanitizedTitle).json")
                try data.write(to: fileURL, options: .atomic)
                await send(.shareFileURLResult(fileURL))
            } catch {
                AppLogger.view.log(.error, "일정 공유 파일 생성 실패 (planId: \(planId)): \(error.localizedDescription)")
                await send(.shareFileURLResult(nil))
            }
        }
        .cancellable(id: CancelID.updateShareFileURL, cancelInFlight: true)
    }

    func removePlanEffect(planId: UUID) -> Effect<Action> {
        .run { [travelPlanUseCase = self.travelPlanUseCase] send in
            do {
                try await travelPlanUseCase.remove(planId: planId)
                await send(.planDeleteResult(true))
            } catch {
                AppLogger.view.log(.error, "일정 삭제 실패 (planId: \(planId)): \(error.localizedDescription)")
                await send(.planDeleteResult(false))
            }
        }
    }
}

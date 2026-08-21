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
    @Dependency(\.autoScrollToTodayUseCase) var autoScrollToTodayUseCase
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

        /// 일정 편집(기간 단축)으로 plan.dayCount가 selectedDayIndex보다 작아져 범위를 벗어났을 때
        /// 보정되어야 할 목표 인덱스. 좌우 전환 애니메이션 방향(isMovingForward)을 View가 먼저 계산할 수
        /// 있도록, selectedDayIndex 자체는 여기서 곧바로 클램프하지 않고 View가 이 값을 관찰해
        /// dayButtonTapped(index:)와 동일한 경로로 보정을 요청하게 한다 (PlanDetailView.swift 참고)
        var pendingSelectedDayIndexClamp: Int? {
            let clamped = min(self.selectedDayIndex, max(self.plan.dayCount - 1, 0))
            return clamped != self.selectedDayIndex ? clamped : nil
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
                // 설정에서 켠 경우에만, 진입 경로(Home/Plan 리스트 등)와 무관하게 오늘 날짜가
                // 포함된 일자로 자동 이동한다. Home 진행중 일정 진입은 이미 initialDayIndex로
                // today matching이 적용되어 있지만, 그 외 경로(Plan 리스트 등)는 여기서 보정된다
                if self.autoScrollToTodayUseCase.isEnabled(), let todayDayIndex = state.plan.todayDayIndex {
                    state.selectedDayIndex = todayDayIndex
                    state.visibleDayIndex = todayDayIndex
                }
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
                // 편집(재정렬) 모드 중 조회 결과가 도착하면(예: 시간 수정 바텀시트 저장 후 재조회),
                // editingSpots는 재정렬용 스냅샷이라 자동으로 최신화되지 않으므로 시간 값만 동기화한다.
                // 배열 순서(사용자가 드래그로 재정렬한 순서)는 그대로 유지해야 하므로 배열 자체는 교체하지 않는다
                if state.isEditing, let updatedSpots = detail?.spots {
                    state.editingSpots = self.editingSpots(current: state.editingSpots, syncingTimeFrom: updatedSpots)
                }
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
                // selectedDayIndex는 여기서 곧바로 클램프하지 않는다. 범위를 벗어난 상태로 잠시 두어도
                // 인덱스를 사용하는 모든 지점이 이미 indices.contains 가드를 거치므로 안전하며,
                // View가 pendingSelectedDayIndexClamp를 관찰해 dayButtonTapped(index:)와 동일한
                // 좌우 애니메이션 방향 계산 경로로 보정하도록 위임한다 (State.pendingSelectedDayIndexClamp 참고)
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
    /// editingSpots의 배열 순서(사용자가 드래그로 재정렬한 순서)는 그대로 유지한 채,
    /// updatedSpots에서 id가 일치하는 스팟의 시간 값(startTime/durationMinutes)만 최신화한다
    func editingSpots(current: [TravelPlanDetailSpot], syncingTimeFrom updatedSpots: [TravelPlanDetailSpot]) -> [TravelPlanDetailSpot] {
        let updatedById = Dictionary(uniqueKeysWithValues: updatedSpots.map { ($0.id, $0) })
        return current.map { spot in
            guard let updated = updatedById[spot.id] else { return spot }
            return TravelPlanDetailSpot(
                id: spot.id,
                dayIndex: spot.dayIndex,
                order: spot.order,
                category: spot.category,
                title: spot.title,
                subtitle: spot.subtitle,
                startTime: updated.startTime,
                durationMinutes: updated.durationMinutes,
                contentId: spot.contentId,
                coordinate: spot.coordinate,
                thumbnailURLString: spot.thumbnailURLString,
                isCustom: spot.isCustom,
                isStation: spot.isStation,
                address: spot.address
            )
        }
    }

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

//
//  PlanFeature.swift
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

// MARK: - PlanFeature

@Reducer
public struct PlanFeature: Sendable {

    @Dependency(\.travelPlanUseCase) var travelPlanUseCase
    @Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase
    @Dependency(\.travelPlanShareUseCase) var travelPlanShareUseCase
    @Dependency(\.shoppingPlanItemUseCase) var shoppingPlanItemUseCase
    @Dependency(\.toolBarItemUseCase) var toolBarItemUseCase
    @Dependency(\.toastCenter) var toastCenter

    @ObservableState
    public struct State: Equatable {
        var plans: [TravelPlan] = []
        var spotCounts: [UUID: Int] = [:]
        var isLoading: Bool = false
        var isImporterPresented: Bool = false
        var isImporting: Bool = false
        var isEditing: Bool = false
        @Presents var addPlanState: AddTravelPlanFeature.State?
        @Presents var editPlanState: PlanDetailEditFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        public init() {}

        var ongoingPlans: [TravelPlan] { self.plans.filter { $0.section == .ongoing } }
        var upcomingPlans: [TravelPlan] { self.plans.filter { $0.section == .upcoming } }
        var pastPlans: [TravelPlan] { self.plans.filter { $0.section == .past } }
    }

    public enum Action: Equatable {
        case onAppear
        case addButtonTapped
        case importButtonTapped
        case importerPresentationChanged(Bool)
        case editModeToggleTapped
        case planTapped(plan: TravelPlan)
        case planEditCellTapped(plan: TravelPlan)
        case planDeleteButtonTapped(id: UUID)
        case plansResult([TravelPlan])
        case spotCountsResult([UUID: Int])
        case planDeleted(id: UUID)
        case importFileSelected(URL?)
        case importResult(Bool)
        case addPlan(PresentationAction<AddTravelPlanFeature.Action>)
        case editPlan(PresentationAction<PlanDetailEditFeature.Action>)
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {
            case deleteConfirmed(id: UUID)
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return self.fetchPlansEffect()

            case .addButtonTapped:
                state.addPlanState = AddTravelPlanFeature.State()
                return .none

            case .importButtonTapped:
                state.isImporterPresented = true
                return .none

            case .importerPresentationChanged(let isPresented):
                state.isImporterPresented = isPresented
                return .none

            case .editModeToggleTapped:
                state.isEditing.toggle()
                return .none

            case .planTapped:
                return .none

            case .planEditCellTapped(let plan):
                state.editPlanState = PlanDetailEditFeature.State(plan: plan)
                return .none

            case .planDeleteButtonTapped(let id):
                state.alert = AlertState {
                    TextState(Strings.Plan.planDeleteAlertTitle)
                } actions: {
                    ButtonState(role: .destructive, action: .deleteConfirmed(id: id)) {
                        TextState(Strings.Plan.alertConfirm)
                    }
                    ButtonState(role: .cancel) {
                        TextState(Strings.Plan.alertCancel)
                    }
                } message: {
                    TextState(Strings.Plan.planDeleteAlertMessage)
                }
                return .none

            case .plansResult(let plans):
                state.plans = plans
                state.isLoading = false
                return self.fetchSpotCountsEffect(plans: plans)

            case .spotCountsResult(let counts):
                state.spotCounts = counts
                return .none

            case .planDeleted(let id):
                state.plans.removeAll { $0.id == id }
                state.spotCounts.removeValue(forKey: id)
                return .none

            case .importFileSelected(let url):
                guard let url else { return .none }
                guard state.isImporting == false else { return .none }
                state.isImporting = true
                return self.importPlanEffect(url: url)

            case .importResult(let success):
                state.isImporting = false
                if success {
                    state.alert = AlertState {
                        TextState(Strings.Plan.importSuccessAlertTitle)
                    } actions: {
                        ButtonState {
                            TextState(Strings.Plan.alertConfirm)
                        }
                    } message: {
                        TextState(Strings.Plan.importSuccessAlertMessage)
                    }
                    return self.fetchPlansEffect()
                } else {
                    state.alert = AlertState {
                        TextState(Strings.Plan.importFailedAlertTitle)
                    } actions: {
                        ButtonState {
                            TextState(Strings.Plan.alertConfirm)
                        }
                    } message: {
                        TextState(Strings.Plan.importFailedAlertMessage)
                    }
                    return .none
                }

            case .addPlan(.presented(.saveResult(true))):
                state.addPlanState = nil
                return self.fetchPlansEffect()

            case .addPlan:
                return .none

            case .editPlan(.presented(.planUpdated(let plan))):
                if let index = state.plans.firstIndex(where: { $0.id == plan.id }) {
                    state.plans[index] = plan
                }
                state.editPlanState = nil
                return .none

            case .editPlan:
                return .none

            case .alert(.presented(.deleteConfirmed(let id))):
                return self.removePlanEffect(planId: id)

            case .alert:
                return .none
            }
        }
        .ifLet(\.$addPlanState, action: \.addPlan) {
            AddTravelPlanFeature()
        }
        .ifLet(\.$editPlanState, action: \.editPlan) {
            PlanDetailEditFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - CancelID

private enum CancelID {
    case fetchPlans
    case fetchSpotCounts
}

// MARK: - Method

private extension PlanFeature {
    func fetchPlansEffect() -> Effect<Action> {
        .run { [travelPlanUseCase = self.travelPlanUseCase, toastCenter = self.toastCenter] send in
            do {
                let plans = try await travelPlanUseCase.fetch()
                await send(.plansResult(plans))
            } catch {
                AppLogger.view.log(.error, "일정 목록 조회 실패: \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.plansResult([]))
            }
        }
        .cancellable(id: CancelID.fetchPlans, cancelInFlight: true)
    }

    func fetchSpotCountsEffect(plans: [TravelPlan]) -> Effect<Action> {
        .run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase, toastCenter = self.toastCenter] send in
            var counts: [UUID: Int] = [:]
            await withTaskGroup(of: (UUID, Int).self) { group in
                for plan in plans {
                    group.addTask {
                        do {
                            let detail = try await travelPlanDetailUseCase.fetch(planId: plan.id)
                            return (plan.id, detail?.spots.count ?? 0)
                        } catch {
                            AppLogger.view.log(.error, "일정 스팟 개수 조회 실패 (planId: \(plan.id)): \(error.localizedDescription)")
                            if error.isNetworkOriginatedError {
                                toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                            }
                            return (plan.id, 0)
                        }
                    }
                }
                for await (id, count) in group {
                    counts[id] = count
                }
            }
            await send(.spotCountsResult(counts))
        }
        .cancellable(id: CancelID.fetchSpotCounts, cancelInFlight: true)
    }

    func removePlanEffect(planId: UUID) -> Effect<Action> {
        .run { [travelPlanUseCase = self.travelPlanUseCase, toastCenter = self.toastCenter] send in
            do {
                try await travelPlanUseCase.remove(planId: planId)
                await send(.planDeleted(id: planId))
            } catch {
                AppLogger.view.log(.error, "일정 삭제 실패 (planId: \(planId)): \(error.localizedDescription)")
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
            }
        }
    }

    func importPlanEffect(url: URL) -> Effect<Action> {
        .run { [
            travelPlanShareUseCase = self.travelPlanShareUseCase,
            travelPlanUseCase = self.travelPlanUseCase,
            travelPlanDetailUseCase = self.travelPlanDetailUseCase,
            shoppingPlanItemUseCase = self.shoppingPlanItemUseCase,
            toolBarItemUseCase = self.toolBarItemUseCase,
            toastCenter = self.toastCenter
        ] send in
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            var addedPlanId: UUID?
            do {
                let data = try Data(contentsOf: url)
                let (plan, detail, shoppingItems, toolBarItems) = try travelPlanShareUseCase.importPlan(from: data)
                try await travelPlanUseCase.add(plan)
                addedPlanId = plan.id
                try await travelPlanDetailUseCase.add(detail)
                try await shoppingPlanItemUseCase.replace(planId: plan.id, items: shoppingItems)
                try await toolBarItemUseCase.replace(planId: plan.id, items: toolBarItems)
                await send(.importResult(true))
            } catch {
                AppLogger.view.log(.error, "일정 가져오기 실패 (fileName: \(url.lastPathComponent)): \(error.localizedDescription)")
                if let addedPlanId {
                    try? await travelPlanUseCase.remove(planId: addedPlanId)
                }
                if error.isNetworkOriginatedError {
                    toastCenter.show(ToastItem(message: error.localizedDescription, type: .error))
                }
                await send(.importResult(false))
            }
        }
    }
}

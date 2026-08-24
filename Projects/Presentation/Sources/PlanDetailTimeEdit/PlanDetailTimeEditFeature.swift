//
//  PlanDetailTimeEditFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// PlanDetail 편집모드에서 스팟 행을 탭하면 여는 바텀시트. 시작/종료 시각을 수정해 저장한다
@Reducer
public struct PlanDetailTimeEditFeature: Sendable {

    @Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase
    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
        let planId: UUID
        let planTitle: String
        let dayTitle: String
        let dateTitle: String
        let spotId: UUID
        var startTime: Date
        var endTime: Date
        var isTimeUnset: Bool
        var isSaving: Bool = false

        public init(planId: UUID, planTitle: String, dayTitle: String, dateTitle: String, spot: TravelPlanDetailSpot) {
            self.planId = planId
            self.planTitle = planTitle
            self.dayTitle = dayTitle
            self.dateTitle = dateTitle
            self.spotId = spot.id
            if let startTime = spot.startTime {
                self.startTime = startTime
                self.endTime = startTime.addingTimeInterval(TimeInterval((spot.durationMinutes ?? 0) * 60))
                self.isTimeUnset = false
            } else {
                self.startTime = Date()
                self.endTime = Date().addingTimeInterval(60 * 60)
                self.isTimeUnset = true
            }
        }

        var durationMinutes: Int {
            let minutes = Calendar.current.dateComponents([.minute], from: self.startTime, to: self.endTime).minute ?? 0
            return max(minutes, 0)
        }

        var isSaveEnabled: Bool {
            self.isTimeUnset || self.endTime > self.startTime
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case closeButtonTapped
        case saveButtonTapped
        case saveFailed
        case timeSaved
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

            case .saveButtonTapped:
                guard state.isSaveEnabled, state.isSaving == false else { return .none }
                state.isSaving = true
                return self.saveEffect(
                    planId: state.planId,
                    spotId: state.spotId,
                    startTime: state.isTimeUnset ? nil : state.startTime,
                    durationMinutes: state.isTimeUnset ? nil : state.durationMinutes
                )

            case .saveFailed:
                state.isSaving = false
                return .none

            case .timeSaved:
                return .none
            }
        }
    }
}

// MARK: - Method

private extension PlanDetailTimeEditFeature {
    func saveEffect(planId: UUID, spotId: UUID, startTime: Date?, durationMinutes: Int?) -> Effect<Action> {
        .run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in
            do {
                try await travelPlanDetailUseCase.updateSpotTime(
                    planId: planId,
                    spotId: spotId,
                    startTime: startTime,
                    durationMinutes: durationMinutes
                )
                await send(.timeSaved)
            } catch {
                AppLogger.view.log(.error, "일정 상세 시간 수정 실패 (planId: \(planId), spotId: \(spotId)): \(error.localizedDescription)")
                await send(.saveFailed)
            }
        }
    }
}

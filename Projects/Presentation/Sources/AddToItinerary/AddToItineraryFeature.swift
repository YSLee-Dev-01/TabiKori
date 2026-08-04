//
//  AddToItineraryFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// 관광지 상세에서 "旅程に追加" 버튼을 눌렀을 때 열리는 하단 sheet.
/// Step 1(일정 → 날짜 선택)과 Step 2(시작/종료 시각 입력)를 같은 sheet 안에서 전환한다.
@Reducer
public struct AddToItineraryFeature: Sendable {

    @Dependency(\.travelPlanUseCase) var travelPlanUseCase
    @Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase
    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
        let touristSpot: TouristSpot
        let address: String
        var plans: [TravelPlan] = []
        var isLoading: Bool = false
        var isSaving: Bool = false
        var expandedPlanId: UUID? = nil
        var step: Step = .selectingPlan
        var selectedPlan: TravelPlan? = nil
        var selectedDayIndex: Int = 0
        var selectedDate: Date = Date()
        var existingDetail: TravelPlanDetail? = nil
        var startTime: Date = Date()
        var endTime: Date = Date()

        public init(touristSpot: TouristSpot, address: String) {
            self.touristSpot = touristSpot
            self.address = address
        }

        public enum Step: Equatable {
            case selectingPlan
            case configuringTime
        }

        var durationMinutes: Int {
            let minutes = Calendar.current.dateComponents([.minute], from: self.startTime, to: self.endTime).minute ?? 0
            return max(minutes, 0)
        }

        var isSaveEnabled: Bool {
            self.endTime > self.startTime
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case closeButtonTapped
        case planRowTapped(TravelPlan)
        case dayRowTapped(plan: TravelPlan, dayIndex: Int, date: Date)
        case backButtonTapped
        case saveButtonTapped
        case plansResult([TravelPlan])
        case existingDetailResult(TravelPlanDetail?)
        case saveFailed
        case spotAdded
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.isLoading = true
                return self.fetchPlansEffect()

            case .closeButtonTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }

            case .planRowTapped(let plan):
                state.expandedPlanId = state.expandedPlanId == plan.id ? nil : plan.id
                return .none

            case .dayRowTapped(let plan, let dayIndex, let date):
                state.selectedPlan = plan
                state.selectedDayIndex = dayIndex
                state.selectedDate = date
                return self.fetchExistingDetailEffect(planId: plan.id)

            case .existingDetailResult(let detail):
                state.existingDetail = detail
                let range = Self.makeDefaultTimeRange(date: state.selectedDate, dayIndex: state.selectedDayIndex, detail: detail)
                state.startTime = range.start
                state.endTime = range.end
                state.step = .configuringTime
                return .none

            case .backButtonTapped:
                state.step = .selectingPlan
                return .none

            case .saveButtonTapped:
                guard
                    state.isSaveEnabled,
                    state.isSaving == false,
                    let plan = state.selectedPlan
                else { return .none }
                state.isSaving = true
                let order = state.existingDetail?.spots.filter { $0.dayIndex == state.selectedDayIndex }.count ?? 0
                let spot = TravelPlanDetailSpot(
                    id: UUID(),
                    dayIndex: state.selectedDayIndex,
                    order: order,
                    category: state.touristSpot.contentType,
                    title: state.touristSpot.japaneseTitle,
                    subtitle: state.address,
                    startTime: state.startTime,
                    durationMinutes: state.durationMinutes
                )
                return self.saveEffect(planId: plan.id, spot: spot)

            case .plansResult(let plans):
                state.plans = plans
                state.isLoading = false
                return .none

            case .saveFailed:
                state.isSaving = false
                return .none

            case .spotAdded:
                return .none
            }
        }
    }
}

// MARK: - Method

private extension AddToItineraryFeature {
    func fetchPlansEffect() -> Effect<Action> {
        .run { [travelPlanUseCase = self.travelPlanUseCase] send in
            do {
                let plans = try await travelPlanUseCase.fetch()
                await send(.plansResult(plans))
            } catch {
                AppLogger.view.log(.error, "일정 목록 조회 실패: \(error.localizedDescription)")
                await send(.plansResult([]))
            }
        }
    }

    func fetchExistingDetailEffect(planId: UUID) -> Effect<Action> {
        .run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in
            do {
                let detail = try await travelPlanDetailUseCase.fetch(planId: planId)
                await send(.existingDetailResult(detail))
            } catch {
                AppLogger.view.log(.error, "일정 상세 조회 실패: \(error.localizedDescription)")
                await send(.existingDetailResult(nil))
            }
        }
    }

    func saveEffect(planId: UUID, spot: TravelPlanDetailSpot) -> Effect<Action> {
        .run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in
            do {
                try await travelPlanDetailUseCase.add(TravelPlanDetail(planId: planId, spots: [spot]))
                await send(.spotAdded)
            } catch {
                AppLogger.view.log(.error, "일정에 스팟 추가 실패: \(error.localizedDescription)")
                await send(.saveFailed)
            }
        }
    }

    static func makeDefaultTimeRange(date: Date, dayIndex: Int, detail: TravelPlanDetail?) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let daySpots = (detail?.spots ?? [])
            .filter { $0.dayIndex == dayIndex }
            .sorted { $0.order < $1.order }

        let start: Date
        if let lastSpot = daySpots.last {
            start = calendar.date(byAdding: .minute, value: lastSpot.durationMinutes, to: lastSpot.startTime) ?? lastSpot.startTime
        } else {
            start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        }
        let end = calendar.date(byAdding: .minute, value: 60, to: start) ?? start
        return (start, end)
    }
}

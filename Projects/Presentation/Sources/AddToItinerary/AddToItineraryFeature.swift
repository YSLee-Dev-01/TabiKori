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
        var isFetchingDetail: Bool = false
        var startTime: Date = Date()
        var endTime: Date = Date()
        fileprivate var existingDetail: TravelPlanDetail? = nil

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
                    .cancellable(id: CancelID.fetchPlans, cancelInFlight: true)

            case .closeButtonTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }

            case .planRowTapped(let plan):
                state.expandedPlanId = state.expandedPlanId == plan.id ? nil : plan.id
                return .none

            case .dayRowTapped(let plan, let dayIndex, let date):
                state.selectedPlan = plan
                state.selectedDayIndex = dayIndex
                state.selectedDate = date
                state.isFetchingDetail = true
                return self.fetchExistingDetailEffect(planId: plan.id)
                    .cancellable(id: CancelID.fetchExistingDetail, cancelInFlight: true)

            case .existingDetailResult(let detail):
                state.existingDetail = detail
                state.isFetchingDetail = false
                let range = TravelPlanDetailSpotScheduler.defaultTimeRange(
                    dayIndex: state.selectedDayIndex,
                    date: state.selectedDate,
                    existingDetail: detail
                )
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
                let order = TravelPlanDetailSpotScheduler.nextOrder(dayIndex: state.selectedDayIndex, existingDetail: state.existingDetail)
                let spot = TravelPlanDetailSpot(
                    id: UUID(),
                    dayIndex: state.selectedDayIndex,
                    order: order,
                    category: state.touristSpot.contentType,
                    title: state.touristSpot.japaneseTitle,
                    subtitle: state.address,
                    startTime: state.startTime,
                    durationMinutes: state.durationMinutes,
                    contentId: state.touristSpot.id,
                    coordinate: state.touristSpot.coordinate,
                    thumbnailURLString: state.touristSpot.thumbnailURLString,
                    isCustom: state.touristSpot.isCustom,
                    isStation: state.touristSpot.isStation,
                    address: state.touristSpot.address
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

// MARK: - CancelID

private enum CancelID {
    case fetchPlans
    case fetchExistingDetail
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
}

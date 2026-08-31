//
//  OnboardingFeature.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

@Reducer
public struct OnboardingFeature: Sendable {

    @Dependency(\.onboardingUseCase) var onboardingUseCase

    @ObservableState
    public struct State: Equatable {
        var currentCoachMark: OnboardingCoachMark = .homeCategory
        var hasViewedPolicy: Bool = false
        var isAgreed: Bool = false
        var isPolicyWebViewPresented: Bool = false
        var isPolicyLoadFailed: Bool = false
        var policyReloadTrigger: Int = 0
        var homeSelectedCategory: CategoryType?
        var planDetailSelectedDayIndex: Int = 0

        public init() {}

        var currentStep: OnboardingStep {
            self.currentCoachMark.step
        }
    }

    public enum Action: Equatable {
        case homeCategoryTapped(CategoryType)
        case mapSearchResultTapped
        case planCardTapped
        case planDetailDayTapped(Int)
        case policyViewButtonTapped
        case policyWebViewDismissed
        case policyRetryTapped
        case agreementCheckBoxTapped
        case startButtonTapped
        case policyLoadFailed
        case coachMarkAdvanced
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case completed
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .homeCategoryTapped(let category):
                guard state.currentCoachMark == .homeCategory else { return .none }
                state.homeSelectedCategory = category
                return self.advanceEffect()

            case .mapSearchResultTapped:
                guard state.currentCoachMark == .mapSearchResult else { return .none }
                return self.advanceEffect()

            case .planCardTapped:
                guard state.currentCoachMark == .planCard else { return .none }
                return self.advanceEffect()

            case .planDetailDayTapped(let dayIndex):
                guard state.currentCoachMark == .planDetailDayChip else { return .none }
                state.planDetailSelectedDayIndex = dayIndex
                return self.advanceEffect()

            case .policyViewButtonTapped:
                guard state.currentCoachMark == .agreementPolicyButton else { return .none }
                state.isPolicyWebViewPresented = true
                return .none

            case .policyWebViewDismissed:
                state.isPolicyWebViewPresented = false
                state.hasViewedPolicy = true
                state.isPolicyLoadFailed = false
                guard state.currentCoachMark == .agreementPolicyButton else { return .none }
                return .send(.coachMarkAdvanced)

            case .policyRetryTapped:
                state.policyReloadTrigger += 1
                state.isPolicyLoadFailed = false
                return .none

            case .agreementCheckBoxTapped:
                guard state.currentCoachMark == .agreementCheckBox, state.hasViewedPolicy else { return .none }
                state.isAgreed = true
                return self.advanceEffect()

            case .startButtonTapped:
                guard state.currentCoachMark == .agreementStartButton, state.isAgreed else { return .none }
                self.onboardingUseCase.markAsCompleted()
                return .send(.delegate(.completed))

            case .policyLoadFailed:
                state.isPolicyLoadFailed = true
                AppLogger.network.log(.error, "온보딩 개인정보처리방침 웹뷰 로드 실패")
                return .none

            case .coachMarkAdvanced:
                state.currentCoachMark = state.currentCoachMark.next ?? state.currentCoachMark
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case coachMarkAdvance
}

// MARK: - Constant

private extension OnboardingFeature {
    static let coachMarkAdvanceDelay: Duration = .seconds(0.3)
}

// MARK: - Method

private extension OnboardingFeature {
    func advanceEffect() -> Effect<Action> {
        .run { send in
            try await Task.sleep(for: Self.coachMarkAdvanceDelay)
            await send(.coachMarkAdvanced)
        }
        .cancellable(id: CancelID.coachMarkAdvance, cancelInFlight: true)
    }
}

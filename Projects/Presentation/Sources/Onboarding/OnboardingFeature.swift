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
        var currentStepIndex: Int = 0
        var reachedStepIndex: Int = 0
        var hasViewedPolicy: Bool = false
        var isAgreed: Bool = false
        var isPolicyWebViewPresented: Bool = false
        var isPolicyLoadFailed: Bool = false
        var policyReloadTrigger: Int = 0
        var homeSelectedCategory: CategoryType?
        var planDetailSelectedDayIndex: Int = 0

        public init() {}

        var currentStep: OnboardingStep {
            OnboardingStep(rawValue: self.currentStepIndex) ?? .home
        }

        var visibleSteps: [OnboardingStep] {
            Array(OnboardingStep.allCases.prefix(self.reachedStepIndex + 1))
        }
    }

    public enum Action: Equatable {
        case pageSelected(Int)
        case nextButtonTapped
        case policyViewButtonTapped
        case policyWebViewDismissed
        case policyRetryTapped
        case policyLoadFailed
        case agreementCheckBoxTapped
        case startButtonTapped
        case homeCategoryTapped(CategoryType)
        case planDetailDayTapped(Int)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case completed
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .pageSelected(let index):
                guard index >= 0, index <= state.reachedStepIndex else { return .none }
                state.currentStepIndex = index
                return .none

            case .nextButtonTapped:
                guard state.currentStep.isLast == false else { return .none }
                let nextIndex = state.currentStepIndex + 1
                state.reachedStepIndex = max(state.reachedStepIndex, nextIndex)
                state.currentStepIndex = nextIndex
                return .none

            case .policyViewButtonTapped:
                state.isPolicyWebViewPresented = true
                return .none

            case .policyWebViewDismissed:
                state.isPolicyWebViewPresented = false
                state.hasViewedPolicy = true
                state.isPolicyLoadFailed = false
                return .none

            case .policyRetryTapped:
                state.policyReloadTrigger += 1
                state.isPolicyLoadFailed = false
                return .none

            case .policyLoadFailed:
                state.isPolicyLoadFailed = true
                AppLogger.network.log(.error, "온보딩 개인정보처리방침 웹뷰 로드 실패")
                return .none

            case .agreementCheckBoxTapped:
                guard state.hasViewedPolicy else { return .none }
                state.isAgreed.toggle()
                return .none

            case .startButtonTapped:
                guard state.isAgreed else { return .none }
                self.onboardingUseCase.markAsCompleted()
                return .send(.delegate(.completed))

            case .homeCategoryTapped(let category):
                state.homeSelectedCategory = state.homeSelectedCategory == category ? nil : category
                return .none

            case .planDetailDayTapped(let dayIndex):
                state.planDetailSelectedDayIndex = dayIndex
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

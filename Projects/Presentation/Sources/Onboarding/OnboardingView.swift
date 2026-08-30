//
//  OnboardingView.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Resource

public struct OnboardingView: View {

    @Bindable private var store: StoreOf<OnboardingFeature>

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            TabView(selection: self.$store.currentStepIndex.sending(\.pageSelected)) {
                ForEach(self.store.visibleSteps) { step in
                    self.stepView(step)
                        .tag(step.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.tabiStandard, value: self.store.currentStepIndex)

            self.bottomBar()
        }
        .sheet(isPresented: Binding(
            get: { self.store.isPolicyWebViewPresented },
            set: { isPresented in
                guard isPresented == false else { return }
                self.store.send(.policyWebViewDismissed)
            }
        )) {
            self.policyWebViewSheet()
        }
    }
}

// MARK: - View

private extension OnboardingView {
    @ViewBuilder
    func stepView(_ step: OnboardingStep) -> some View {
        switch step {
        case .home:
            OnboardingHomeStepView(
                selectedCategory: self.store.homeSelectedCategory,
                onCategoryTapped: { self.store.send(.homeCategoryTapped($0)) }
            )

        case .map:
            OnboardingMapStepView()

        case .plan:
            OnboardingPlanStepView()

        case .planDetail:
            OnboardingPlanDetailStepView(
                selectedDayIndex: self.store.planDetailSelectedDayIndex,
                onDayTapped: { self.store.send(.planDetailDayTapped($0)) }
            )

        case .agreement:
            OnboardingAgreementStepView(
                hasViewedPolicy: self.store.hasViewedPolicy,
                isAgreed: self.store.isAgreed,
                onViewPolicyTapped: { self.store.send(.policyViewButtonTapped) },
                onCheckBoxTapped: { self.store.send(.agreementCheckBoxTapped) }
            )
        }
    }

    func bottomBar() -> some View {
        VStack(spacing: 16) {
            TabiPageIndicator(
                count: OnboardingStep.allCases.count,
                currentIndex: self.store.currentStepIndex,
                inactiveColor: Color.getTabiColor(.tabiBorder)
            )

            TabiButton(
                self.store.currentStep.isLast ? Strings.Onboarding.startButtonTitle : Strings.Onboarding.nextButtonTitle,
                style: .primary,
                isExpanded: true
            ) {
                if self.store.currentStep.isLast {
                    self.store.send(.startButtonTapped)
                } else {
                    self.store.send(.nextButtonTapped)
                }
            }
            .disabled(self.store.currentStep.isLast && self.store.isAgreed == false)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    func policyWebViewSheet() -> some View {
        VStack(spacing: 0) {
            TabiNavigationBar(title: Strings.Onboarding.privacyPolicyWebViewTitle) {
                TabiCircleIconButton(systemName: "xmark") {
                    self.store.send(.policyWebViewDismissed)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            ZStack {
                OnboardingPolicyWebView(
                    reloadTrigger: self.store.policyReloadTrigger,
                    onLoadFailed: { self.store.send(.policyLoadFailed) }
                )

                if self.store.isPolicyLoadFailed {
                    TabiRetryableEmptyState(
                        description: Strings.Onboarding.privacyPolicyLoadFailedDescription,
                        onRetry: { self.store.send(.policyRetryTapped) }
                    )
                    .background(TabiColor.tabiBackground)
                }
            }
        }
    }
}

#Preview {
    OnboardingView(store: .init(
        initialState: .init(),
        reducer: {
            OnboardingFeature()
        }))
}

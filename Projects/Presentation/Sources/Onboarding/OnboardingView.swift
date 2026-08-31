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

    private let store: StoreOf<OnboardingFeature>

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if self.store.hasSeenWelcome == false {
                OnboardingWelcomeStepView(onStartTapped: { self.store.send(.welcomeButtonTapped) })
                    .transition(.opacity)
            } else {
                self.coachMarkFlow()
                    .transition(.opacity)
            }
        }
        .animation(.tabiStandard, value: self.store.hasSeenWelcome)
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
    /// 웰컴 스텝 이후의 코치마크 기반 체험 흐름(홈~약관동의). 약관동의 스텝은 순서 강제 없이 자유롭게
    /// 누를 수 있도록 스포트라이트/툴팁 가이드를 표시하지 않는다
    func coachMarkFlow() -> some View {
        VStack(spacing: 0) {
            self.stepView(self.store.currentStep)
                .id(self.store.currentStep)
                .transition(.opacity)
        }
        .animation(.tabiStandard, value: self.store.currentStep)
        .overlayPreferenceValue(OnboardingHighlightAnchorKey.self) { anchors in
            GeometryReader { proxy in
                if self.store.currentStep != .agreement,
                   let anchor = anchors[self.store.currentCoachMark.anchorKey] {
                    OnboardingSpotlightOverlay(
                        highlightRect: proxy[anchor],
                        containerSize: proxy.size,
                        coachMark: self.store.currentCoachMark
                    )
                }
            }
            .ignoresSafeArea()
        }
        .overlay(alignment: .bottom) {
            TabiPageIndicator(
                count: OnboardingStep.allCases.count,
                currentIndex: self.store.currentStep.rawValue,
                inactiveColor: Color.getTabiColor(.tabiBorder)
            )
            .padding(.bottom, 16)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    func stepView(_ step: OnboardingStep) -> some View {
        switch step {
        case .home:
            OnboardingHomeHostView(
                onCategoryTapped: { self.store.send(.homeCategoryTapped($0)) }
            )

        case .map:
            OnboardingMapHostView(
                onSearchResultTapped: { self.store.send(.mapSearchResultTapped) }
            )

        case .plan:
            OnboardingPlanHostView(
                onPlanTapped: { self.store.send(.planCardTapped) }
            )

        case .planDetail:
            OnboardingPlanDetailHostView(
                onDayTapped: { self.store.send(.planDetailDayTapped($0)) }
            )

        case .agreement:
            OnboardingAgreementStepView(
                hasViewedPolicy: self.store.hasViewedPolicy,
                isAgreed: self.store.isAgreed,
                onViewPolicyTapped: { self.store.send(.policyViewButtonTapped) },
                onCheckBoxTapped: { self.store.send(.agreementCheckBoxTapped) },
                onStartTapped: { self.store.send(.startButtonTapped) }
            )
        }
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

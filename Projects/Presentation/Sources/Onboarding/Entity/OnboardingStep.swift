//
//  OnboardingStep.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Resource

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case home
    case map
    case plan
    case planDetail
    case agreement

    var id: Int { self.rawValue }

    var title: String {
        switch self {
        case .home: return Strings.Onboarding.homeStepTitle
        case .map: return Strings.Onboarding.mapStepTitle
        case .plan: return Strings.Onboarding.planStepTitle
        case .planDetail: return Strings.Onboarding.planDetailStepTitle
        case .agreement: return Strings.Onboarding.agreementStepTitle
        }
    }

    var description: String {
        switch self {
        case .home: return Strings.Onboarding.homeStepDescription
        case .map: return Strings.Onboarding.mapStepDescription
        case .plan: return Strings.Onboarding.planStepDescription
        case .planDetail: return Strings.Onboarding.planDetailStepDescription
        case .agreement: return Strings.Onboarding.agreementStepDescription
        }
    }

    var isLast: Bool {
        self == .agreement
    }
}

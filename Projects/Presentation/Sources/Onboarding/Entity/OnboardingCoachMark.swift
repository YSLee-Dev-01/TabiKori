//
//  OnboardingCoachMark.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import DesignSystem
import Resource

enum OnboardingCoachMark: Int, CaseIterable, Hashable {
    case homeCategory
    case mapSearchResult
    case detailSaveButton
    case detailAddButton
    case planCard
    case planDetailDayChip
    case planDetailFullMapButton
    /// 약관동의 스텝은 순서 강제 없이 자유롭게 진행하도록 스포트라이트/툴팁을 표시하지 않는다(`OnboardingView.swift`
    /// `coachMarkFlow()` 참조). `step`이 `.agreement`로 전이되기 위한 시퀀스 마커로만 쓰인다
    case agreement

    var step: OnboardingStep {
        switch self {
        case .homeCategory: return .home
        case .mapSearchResult: return .map
        case .detailSaveButton, .detailAddButton: return .detail
        case .planCard: return .plan
        case .planDetailDayChip, .planDetailFullMapButton: return .planDetail
        case .agreement: return .agreement
        }
    }

    var tooltip: String {
        switch self {
        case .homeCategory: return Strings.Onboarding.homeCategoryCoachMark
        case .mapSearchResult: return Strings.Onboarding.mapSearchResultCoachMark
        case .detailSaveButton: return Strings.Onboarding.detailSaveButtonCoachMark
        case .detailAddButton: return Strings.Onboarding.detailAddButtonCoachMark
        case .planCard: return Strings.Onboarding.planCardCoachMark
        case .planDetailDayChip: return Strings.Onboarding.planDetailDayChipCoachMark
        case .planDetailFullMapButton: return Strings.Onboarding.planDetailFullMapButtonCoachMark
        case .agreement: return ""
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .detailSaveButton, .detailAddButton, .planDetailDayChip, .planDetailFullMapButton: return .tabiRadiusFull
        case .homeCategory, .mapSearchResult, .planCard: return .tabiRadiusLg
        case .agreement: return .tabiRadiusSm
        }
    }

    var padding: CGFloat {
        4
    }

    var next: OnboardingCoachMark? {
        OnboardingCoachMark(rawValue: self.rawValue + 1)
    }

    /// 스포트라이트 노출 전 대기 시간. 뒤에 깔린 화면의 엔트런스/전환 애니메이션이 먼저 정착되도록,
    /// 해당 애니메이션 근거로 계산한다(관련 없는 스텝은 기존과 동일하게 0으로 즉시 노출)
    var revealDelay: TimeInterval {
        switch self {
        case .homeCategory, .mapSearchResult:
            return 0.55
        case .detailSaveButton, .detailAddButton, .planCard, .planDetailDayChip, .planDetailFullMapButton, .agreement:
            return 0
        }
    }

    /// `OnboardingHighlightAnchorKey`(`[AnyHashable: Anchor<CGRect>]`) 조회에 사용하는 키.
    /// 홈/지도/일정/일정상세 스텝은 실제 프로덕션 뷰(Home/Map/Plan/PlanDetailView)가 `OnboardingCoachMark`
    /// 타입을 몰라도 부착할 수 있도록 문자열 키를 쓰고, 약관동의 스텝은 온보딩 전용 뷰만 사용하므로
    /// 기존처럼 자기 자신(enum case)을 키로 사용한다
    var anchorKey: AnyHashable {
        switch self {
        case .homeCategory: return "homeCategory"
        case .mapSearchResult: return "mapSearchResult"
        case .detailSaveButton: return "detailSaveButton"
        case .detailAddButton: return "detailAddButton"
        case .planCard: return "planCard"
        case .planDetailDayChip: return "planDetailDayChip"
        case .planDetailFullMapButton: return "planDetailFullMapButton"
        case .agreement: return self
        }
    }
}

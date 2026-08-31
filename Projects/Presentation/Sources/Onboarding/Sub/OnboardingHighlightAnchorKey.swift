//
//  OnboardingHighlightAnchorKey.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

/// 하이라이트 대상의 화면 좌표를 전달하는 PreferenceKey. 키 타입을 `AnyHashable`로 일반화해,
/// Home/Map/Plan/PlanDetail 같은 실제 프로덕션 뷰가 Onboarding 모듈의 `OnboardingCoachMark` 타입을
/// 몰라도(문자열 키만으로도) 하이라이트 모디파이어를 부착할 수 있게 한다
struct OnboardingHighlightAnchorKey: PreferenceKey {
    // Anchor<CGRect>가 Sendable이 아니라 컴파일러가 static 프로퍼티의 동시성 안전성을 검증할 수 없다고
    // 판단한다. PreferenceKey의 defaultValue는 SwiftUI가 뷰 트리 순회 중(MainActor 컨텍스트)에만
    // 읽고 쓰므로 실질적으로 안전하다
    nonisolated(unsafe) static let defaultValue: [AnyHashable: Anchor<CGRect>] = [:]

    static func reduce(value: inout [AnyHashable: Anchor<CGRect>], nextValue: () -> [AnyHashable: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// MARK: - View

extension View {
    /// 코치마크 대상 요소의 화면 좌표를 측정해 스포트라이트 오버레이에 전달하고,
    /// `ScrollViewReader`가 해당 요소로 스크롤할 수 있도록 식별자를 부착한다.
    /// `key`는 온보딩 전용 뷰에서는 `OnboardingCoachMark` 값을, 실제 프로덕션 뷰(Home/Map/Plan/PlanDetail)에서는
    /// 문자열 리터럴을 그대로 전달하면 된다(둘 다 `AnyHashable`로 암시적 변환됨)
    func onboardingHighlight(_ key: AnyHashable) -> some View {
        self
            .anchorPreference(key: OnboardingHighlightAnchorKey.self, value: .bounds) { anchor in
                [key: anchor]
            }
            .id(key)
    }
}

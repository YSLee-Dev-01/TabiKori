//
//  AnalyticsEvent.swift
//  Domain
//
//  Created by Claude on 8/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// 분석용으로 수집하는 사용자 행동 이벤트
///
/// 사용자를 식별할 수 있는 값(이메일, 검색어 원문 등)은 파라미터로 담지 않는다.
/// Firebase 이벤트명/파라미터명으로의 변환은 App 레이어(`LiveAnalyticsCenter`)에서만 수행하여
/// Domain이 Firebase를 직접 참조하지 않도록 한다
public enum AnalyticsEvent: Equatable, Sendable {
    // 홈
    case homeCategorySelected(category: String)
    case currencyWidgetTapped

    // 검색
    case searchPerformed(hasResult: Bool)
    case autoTranslateSearchUsed

    // 지도
    case mapMarkerTapped(category: String)
    case mapSearchSheetOpened

    // 상세
    case touristSpotViewed(spotId: String)
    case spotBookmarked(spotId: String)
    case spotBookmarkRemoved(spotId: String)
    case spotShared(spotId: String)

    // 일정
    case travelPlanCreated
    case travelPlanDeleted
    case planSpotAdded(source: String)
    case planTimeEdited
    case itineraryShared(planId: String)

    // 북마크
    case bookmarkRemoved

    // 축제
    case festivalFilterApplied(dateRangeSpecified: Bool)
    case festivalDetailViewed(festivalId: String)

    // 환율
    case exchangeCalculated

    // 쇼핑/준비물
    case shoppingItemChecked
    case packingItemChecked
    case shoppingPlanCreated

    // 한국어 문구
    case koreanPhraseViewed(phraseId: String)

    // 설정
    case dataResetConfirmed
    case autoScrollTodayToggled(enabled: Bool)
    case autoTranslateSearchToggled(enabled: Bool)
}

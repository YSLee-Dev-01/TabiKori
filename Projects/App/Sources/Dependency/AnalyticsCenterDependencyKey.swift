//
//  AnalyticsCenterDependencyKey.swift
//  App
//
//  Created by Claude on 8/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Domain

import ComposableArchitecture
import FirebaseAnalytics

/// `AnalyticsEvent`를 Firebase 이벤트명/파라미터로 변환해 기록한다
///
/// Firebase 표준 이벤트(`AnalyticsEventXxx`)로 매핑 가능한 경우 표준 이벤트를 사용하고,
/// 그 외에는 프로젝트 전용 커스텀 이벤트명을 사용한다. 사용자를 식별할 수 있는 값(검색어 원문 등)은
/// 파라미터로 담지 않는다
private final class LiveAnalyticsCenter: AnalyticsCenterProtocol, @unchecked Sendable {
    func log(_ event: AnalyticsEvent) {
        switch event {
        case .homeCategorySelected(let category):
            Analytics.logEvent("home_category_selected", parameters: [
                "category": category
            ])

        case .currencyWidgetTapped:
            Analytics.logEvent("currency_widget_tapped", parameters: nil)

        case .searchPerformed(let hasResult):
            Analytics.logEvent(AnalyticsEventSearch, parameters: [
                "has_result": hasResult ? 1 : 0
            ])

        case .autoTranslateSearchUsed:
            Analytics.logEvent("auto_translate_search_used", parameters: nil)

        case .mapMarkerTapped(let category):
            Analytics.logEvent("map_marker_tapped", parameters: [
                "category": category
            ])

        case .mapSearchSheetOpened:
            Analytics.logEvent("map_search_sheet_opened", parameters: nil)

        case .touristSpotViewed(let spotId):
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterContentType: "tourist_spot",
                AnalyticsParameterItemID: spotId
            ])

        case .spotBookmarked(let spotId):
            Analytics.logEvent("spot_bookmarked", parameters: [
                AnalyticsParameterItemID: spotId
            ])

        case .spotBookmarkRemoved(let spotId):
            Analytics.logEvent("spot_bookmark_removed", parameters: [
                AnalyticsParameterItemID: spotId
            ])

        case .spotShared(let spotId):
            Analytics.logEvent(AnalyticsEventShare, parameters: [
                AnalyticsParameterContentType: "tourist_spot",
                AnalyticsParameterItemID: spotId
            ])

        case .travelPlanCreated:
            Analytics.logEvent("travel_plan_created", parameters: nil)

        case .travelPlanDeleted:
            Analytics.logEvent("travel_plan_deleted", parameters: nil)

        case .planSpotAdded(let source):
            Analytics.logEvent("plan_spot_added", parameters: [
                "source": source
            ])

        case .planTimeEdited:
            Analytics.logEvent("plan_time_edited", parameters: nil)

        case .itineraryShared(let planId):
            Analytics.logEvent(AnalyticsEventShare, parameters: [
                AnalyticsParameterContentType: "travel_plan",
                AnalyticsParameterItemID: planId
            ])

        case .bookmarkRemoved:
            Analytics.logEvent("bookmark_removed", parameters: nil)

        case .festivalFilterApplied(let dateRangeSpecified):
            Analytics.logEvent("festival_filter_applied", parameters: [
                "date_range_specified": dateRangeSpecified ? 1 : 0
            ])

        case .festivalDetailViewed(let festivalId):
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterContentType: "festival",
                AnalyticsParameterItemID: festivalId
            ])

        case .exchangeCalculated:
            Analytics.logEvent("exchange_calculated", parameters: nil)

        case .shoppingItemChecked:
            Analytics.logEvent("shopping_item_checked", parameters: nil)

        case .packingItemChecked:
            Analytics.logEvent("packing_item_checked", parameters: nil)

        case .shoppingPlanCreated:
            Analytics.logEvent("shopping_plan_created", parameters: nil)

        case .koreanPhraseViewed(let phraseId):
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterContentType: "korean_phrase",
                AnalyticsParameterItemID: phraseId
            ])

        case .dataResetConfirmed:
            Analytics.logEvent("data_reset_confirmed", parameters: nil)

        case .autoScrollTodayToggled(let enabled):
            Analytics.logEvent("auto_scroll_today_toggled", parameters: [
                "enabled": enabled ? 1 : 0
            ])

        case .autoTranslateSearchToggled(let enabled):
            Analytics.logEvent("auto_translate_search_toggled", parameters: [
                "enabled": enabled ? 1 : 0
            ])
        }
    }
}

extension AnalyticsCenterDependencyKey: @retroactive DependencyKey {
    public static let liveValue: AnalyticsCenterProtocol = LiveAnalyticsCenter()
}

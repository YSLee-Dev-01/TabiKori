//
//  TravelPlanDetailSpotScheduler.swift
//  Domain
//
//  Created by 이윤수 on 8/5/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// 특정 일자(dayIndex)에 스팟을 추가할 때 필요한 기본 시각/순서를 계산한다.
/// `AddToItineraryFeature`(관광지 상세 → 일정에 추가)와 `PlanDetailAddSpotFeature`(일정 상세 → 스팟 추가)가 공유한다
public enum TravelPlanDetailSpotScheduler {

    public static func defaultTimeRange(dayIndex: Int, date: Date, existingDetail: TravelPlanDetail?) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let daySpots = (existingDetail?.spots ?? [])
            .filter { $0.dayIndex == dayIndex }
            .sorted { $0.order < $1.order }

        let start: Date
        if let lastSpot = daySpots.last {
            start = calendar.date(byAdding: .minute, value: lastSpot.durationMinutes, to: lastSpot.startTime) ?? lastSpot.startTime
        } else {
            start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        }
        let end = calendar.date(byAdding: .minute, value: 60, to: start) ?? start
        return (start, end)
    }

    public static func nextOrder(dayIndex: Int, existingDetail: TravelPlanDetail?) -> Int {
        existingDetail?.spots.filter { $0.dayIndex == dayIndex }.count ?? 0
    }
}

//
//  PlanDetailMock.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

extension TravelPlan {
    static let mock = TravelPlan(
        id: UUID(),
        title: "ソウル春旅行",
        region: .seoul,
        customRegionText: nil,
        customEmoji: nil,
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    )
}

extension TravelPlanDetail {
    static let mock = TravelPlanDetail(
        planId: TravelPlan.mock.id,
        spots: [
            TravelPlanDetailSpot(
                id: UUID(),
                dayIndex: 0,
                order: 0,
                category: .sightseeing,
                title: "景福宮",
                subtitle: "朝鮮王朝の正宮",
                startTime: Date(),
                durationMinutes: 90,
                contentId: "mock-gyeongbokgung",
                coordinate: .seoulCityHall,
                thumbnailURLString: nil,
                isCustom: false,
                address: nil
            ),
            TravelPlanDetailSpot(
                id: UUID(),
                dayIndex: 0,
                order: 1,
                category: .food,
                title: "土俗村参鶏湯",
                subtitle: nil,
                startTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
                durationMinutes: 60,
                contentId: "mock-tosokchon",
                coordinate: .seoulCityHall,
                thumbnailURLString: nil,
                isCustom: false,
                address: nil
            ),
            TravelPlanDetailSpot(
                id: UUID(),
                dayIndex: 0,
                order: 2,
                category: .shopping,
                title: "明洞ショッピング通り",
                subtitle: "免税店・コスメショップ",
                startTime: Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date(),
                durationMinutes: 120,
                contentId: "mock-myeongdong",
                coordinate: .seoulCityHall,
                thumbnailURLString: nil,
                isCustom: false,
                address: nil
            ),
            TravelPlanDetailSpot(
                id: UUID(),
                dayIndex: 1,
                order: 0,
                category: .nature,
                title: "北岳山",
                subtitle: nil,
                startTime: Date(),
                durationMinutes: 150,
                contentId: "mock-bukaksan",
                coordinate: .seoulCityHall,
                thumbnailURLString: nil,
                isCustom: false,
                address: nil
            ),
        ]
    )
}

//
//  OnboardingMock.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

/// 온보딩 체험 화면 전용 정적 더미 데이터. 네트워크·DB 호출 없이 화면을 채우기 위한 값만 담는다
enum OnboardingMock {
    static let nearbySpots: [TouristSpot] = [
        TouristSpot(
            id: "onboarding-gyeongbokgung",
            title: "景福宮（경복궁）",
            thumbnailURLString: nil,
            distanceMeters: 320,
            contentType: .sightseeing,
            coordinate: .seoulCityHall
        ),
        TouristSpot(
            id: "onboarding-myeongdong",
            title: "明洞ショッピング通り（명동거리）",
            thumbnailURLString: nil,
            distanceMeters: 850,
            contentType: .shopping,
            coordinate: .seoulCityHall
        ),
        TouristSpot(
            id: "onboarding-tosokchon",
            title: "土俗村参鶏湯（토속촌삼계탕）",
            thumbnailURLString: nil,
            distanceMeters: 1200,
            contentType: .food,
            coordinate: .seoulCityHall
        ),
    ]

    static let searchResults: [TouristSpot] = [
        TouristSpot(
            id: "onboarding-bukchon",
            title: "北村韓屋村（북촌한옥마을）",
            thumbnailURLString: nil,
            distanceMeters: 540,
            contentType: .sightseeing,
            coordinate: .seoulCityHall
        ),
        TouristSpot(
            id: "onboarding-namsan",
            title: "南山タワー（남산타워）",
            thumbnailURLString: nil,
            distanceMeters: 2100,
            contentType: .nature,
            coordinate: .seoulCityHall
        ),
    ]

    static let plan = TravelPlan(
        id: UUID(),
        title: "ソウル春旅行",
        region: .seoul,
        customRegionText: nil,
        customEmoji: nil,
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    )

    static let plans: [TravelPlan] = [
        Self.plan,
        TravelPlan(
            id: UUID(),
            title: "釜山夏休み旅行",
            region: .busan,
            customRegionText: nil,
            customEmoji: nil,
            startDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 33, to: Date()) ?? Date()
        ),
    ]

    static let planDetail = TravelPlanDetail(
        planId: Self.plan.id,
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
                contentId: "onboarding-mock-gyeongbokgung",
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
                contentId: "onboarding-mock-tosokchon",
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
                contentId: "onboarding-mock-bukaksan",
                coordinate: .seoulCityHall,
                thumbnailURLString: nil,
                isCustom: false,
                address: nil
            ),
        ]
    )
}

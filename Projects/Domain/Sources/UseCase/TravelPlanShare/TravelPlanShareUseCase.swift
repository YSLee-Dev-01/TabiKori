//
//  TravelPlanShareUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// 플랜을 JSON으로 내보내기/가져오기 하는 순수 로직 UseCase. Repository 의존성이 없어 Data 모듈 조립 없이 App에서 그대로 사용 가능하다
public final class TravelPlanShareUseCase: TravelPlanShareUseCaseProtocol {

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func exportData(
        plan: TravelPlan,
        detail: TravelPlanDetail?,
        shoppingItems: [ShoppingPlanItem],
        toolBarItems: [ToolBarPlanItem]
    ) throws -> Data {
        let payload = SharePayload(
            plan: plan,
            spots: detail?.spots ?? [],
            shoppingItems: shoppingItems,
            toolBarItems: toolBarItems
        )
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(payload)
        } catch {
            throw TabiError.decodingFailed(message: error.localizedDescription)
        }
    }

    public func importPlan(
        from data: Data
    ) throws -> (plan: TravelPlan, detail: TravelPlanDetail, shoppingItems: [ShoppingPlanItem], toolBarItems: [ToolBarPlanItem]) {
        let payload: SharePayload
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            payload = try decoder.decode(SharePayload.self, from: data)
        } catch {
            throw TabiError.decodingFailed(message: error.localizedDescription)
        }

        // 받는 사람의 독립된 레코드로 취급하기 위해 새 UUID를 발급한다
        let newPlanId = UUID()
        let plan = TravelPlan(
            id: newPlanId,
            title: payload.plan.title,
            region: KoreanRegion(rawValue: payload.plan.region) ?? .etc,
            customRegionText: payload.plan.customRegionText,
            customEmoji: payload.plan.customEmoji,
            startDate: payload.plan.startDate,
            endDate: payload.plan.endDate
        )

        let spots = payload.spots.map { spotPayload in
            TravelPlanDetailSpot(
                id: UUID(),
                dayIndex: spotPayload.dayIndex,
                order: spotPayload.order,
                category: CategoryType(rawValue: spotPayload.category) ?? .sightseeing,
                title: spotPayload.title,
                subtitle: spotPayload.subtitle,
                startTime: spotPayload.startTime,
                durationMinutes: spotPayload.durationMinutes,
                contentId: spotPayload.contentId,
                coordinate: Coordinate(latitude: spotPayload.latitude, longitude: spotPayload.longitude),
                thumbnailURLString: spotPayload.thumbnailURLString,
                isCustom: spotPayload.isCustom,
                isStation: spotPayload.isStation,
                address: spotPayload.address
            )
        }

        // 쇼핑/준비물 리스트는 스팟과 마찬가지로 받는 사람의 새 플랜 기준으로 id/planId를 새로 발급한다
        let shoppingItems = payload.shoppingItems.map { itemPayload in
            ShoppingPlanItem(
                id: UUID(),
                planId: newPlanId,
                order: itemPayload.order,
                title: itemPayload.title,
                note: itemPayload.note,
                isChecked: itemPayload.isChecked
            )
        }

        let toolBarItems = payload.toolBarItems.map { itemPayload in
            ToolBarPlanItem(
                id: UUID(),
                planId: newPlanId,
                order: itemPayload.order,
                title: itemPayload.title,
                note: itemPayload.note,
                isChecked: itemPayload.isChecked
            )
        }

        return (plan, TravelPlanDetail(planId: newPlanId, spots: spots), shoppingItems, toolBarItems)
    }
}

// MARK: - SharePayload

/// Domain 엔티티를 직접 Codable로 만들지 않고, 공유 목적의 변환 전용 타입으로 인코딩/디코딩을 격리한다
private struct SharePayload: Codable {
    struct PlanPayload: Codable {
        let title: String
        let region: String
        let customRegionText: String?
        let customEmoji: String?
        let startDate: Date
        let endDate: Date
    }

    struct SpotPayload: Codable {
        let dayIndex: Int
        let order: Int
        let category: String
        let title: String
        let subtitle: String?
        let startTime: Date?
        let durationMinutes: Int?
        let contentId: String
        let latitude: Double
        let longitude: Double
        let thumbnailURLString: String?
        let isCustom: Bool
        let isStation: Bool
        let address: String?

        init(
            dayIndex: Int,
            order: Int,
            category: String,
            title: String,
            subtitle: String?,
            startTime: Date?,
            durationMinutes: Int?,
            contentId: String,
            latitude: Double,
            longitude: Double,
            thumbnailURLString: String?,
            isCustom: Bool,
            isStation: Bool,
            address: String?
        ) {
            self.dayIndex = dayIndex
            self.order = order
            self.category = category
            self.title = title
            self.subtitle = subtitle
            self.startTime = startTime
            self.durationMinutes = durationMinutes
            self.contentId = contentId
            self.latitude = latitude
            self.longitude = longitude
            self.thumbnailURLString = thumbnailURLString
            self.isCustom = isCustom
            self.isStation = isStation
            self.address = address
        }

        /// isStation 필드 도입 이전에 내보낸(export) 파일과의 하위 호환 — 키가 없으면 false로 취급
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.dayIndex = try container.decode(Int.self, forKey: .dayIndex)
            self.order = try container.decode(Int.self, forKey: .order)
            self.category = try container.decode(String.self, forKey: .category)
            self.title = try container.decode(String.self, forKey: .title)
            self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
            self.startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
            self.durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes)
            self.contentId = try container.decode(String.self, forKey: .contentId)
            self.latitude = try container.decode(Double.self, forKey: .latitude)
            self.longitude = try container.decode(Double.self, forKey: .longitude)
            self.thumbnailURLString = try container.decodeIfPresent(String.self, forKey: .thumbnailURLString)
            self.isCustom = try container.decode(Bool.self, forKey: .isCustom)
            self.isStation = try container.decodeIfPresent(Bool.self, forKey: .isStation) ?? false
            self.address = try container.decodeIfPresent(String.self, forKey: .address)
        }
    }

    /// 쇼핑 리스트 항목 페이로드. `id`/`planId`는 가져오기 시 새로 발급하므로 직렬화 대상에서 제외한다
    struct ShoppingItemPayload: Codable {
        let order: Int
        let title: String
        let note: String?
        let isChecked: Bool
    }

    /// 준비물 리스트 항목 페이로드. `id`/`planId`는 가져오기 시 새로 발급하므로 직렬화 대상에서 제외한다
    struct ToolBarItemPayload: Codable {
        let order: Int
        let title: String
        let note: String?
        let isChecked: Bool
    }

    let plan: PlanPayload
    let spots: [SpotPayload]
    let shoppingItems: [ShoppingItemPayload]
    let toolBarItems: [ToolBarItemPayload]

    init(
        plan: TravelPlan,
        spots: [TravelPlanDetailSpot],
        shoppingItems: [ShoppingPlanItem],
        toolBarItems: [ToolBarPlanItem]
    ) {
        self.plan = PlanPayload(
            title: plan.title,
            region: plan.region.rawValue,
            customRegionText: plan.customRegionText,
            customEmoji: plan.customEmoji,
            startDate: plan.startDate,
            endDate: plan.endDate
        )
        self.spots = spots.map { spot in
            SpotPayload(
                dayIndex: spot.dayIndex,
                order: spot.order,
                category: spot.category.rawValue,
                title: spot.title,
                subtitle: spot.subtitle,
                startTime: spot.startTime,
                durationMinutes: spot.durationMinutes,
                contentId: spot.contentId,
                latitude: spot.coordinate.latitude,
                longitude: spot.coordinate.longitude,
                thumbnailURLString: spot.thumbnailURLString,
                isCustom: spot.isCustom,
                isStation: spot.isStation,
                address: spot.address
            )
        }
        self.shoppingItems = shoppingItems.map { item in
            ShoppingItemPayload(order: item.order, title: item.title, note: item.note, isChecked: item.isChecked)
        }
        self.toolBarItems = toolBarItems.map { item in
            ToolBarItemPayload(order: item.order, title: item.title, note: item.note, isChecked: item.isChecked)
        }
    }

    /// shoppingItems/toolBarItems 도입 이전에 내보낸(export) 파일과의 하위 호환 — 키가 없으면 빈 배열로 취급
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.plan = try container.decode(PlanPayload.self, forKey: .plan)
        self.spots = try container.decode([SpotPayload].self, forKey: .spots)
        self.shoppingItems = try container.decodeIfPresent([ShoppingItemPayload].self, forKey: .shoppingItems) ?? []
        self.toolBarItems = try container.decodeIfPresent([ToolBarItemPayload].self, forKey: .toolBarItems) ?? []
    }
}

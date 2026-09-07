//
//  TravelPlanDetailSpot+.swift
//  Domain
//
//  Created by Claude on 8/26/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

extension TravelPlanDetailSpot {
    /// PlanDetailFullMap에서 재선택된 스팟을 DetailView로 넘기기 위한 변환.
    /// TravelPlanDetailSpot에는 거리 정보가 없어 distanceMeters는 nil로 매핑한다
    public func toTouristSpot() -> TouristSpot {
        return TouristSpot(
            id: self.contentId,
            title: self.title,
            thumbnailURLString: self.thumbnailURLString,
            distanceMeters: nil,
            contentType: self.category,
            coordinate: self.coordinate,
            isCustom: self.isCustom,
            isStation: self.isStation,
            address: self.address
        )
    }
}

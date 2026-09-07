//
//  TravelPlanDetailModel+.swift
//  Data
//
//  Created by 이윤수 on 8/1/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

extension TravelPlanDetailModel {
    func toDomain(spots: [TravelPlanDetailSpot]) -> TravelPlanDetail {
        return TravelPlanDetail(planId: self.planId, spots: spots)
    }

    convenience init(detail: TravelPlanDetail) {
        self.init(planId: detail.planId)
    }
}

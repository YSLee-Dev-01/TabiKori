//
//  TravelPlanDetail.swift
//  Domain
//
//  Created by 이윤수 on 8/1/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct TravelPlanDetail: Equatable, Sendable {
    public let planId: UUID

    public init(planId: UUID) {
        self.planId = planId
    }
}

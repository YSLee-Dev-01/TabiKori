//
//  TravelPlanDetailModel.swift
//  Data
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class TravelPlanDetailModel {
    @Attribute(.unique) var planId: UUID

    init(planId: UUID) {
        self.planId = planId
    }
}

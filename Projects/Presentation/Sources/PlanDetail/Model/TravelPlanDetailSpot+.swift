//
//  TravelPlanDetailSpot+.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain
import Resource

extension TravelPlanDetailSpot {
    var startTimeTitle: String {
        self.startTime.planSpotTimeTitle
    }

    var durationTitle: String {
        Strings.Plan.spotDurationTitle(self.durationMinutes)
    }
}

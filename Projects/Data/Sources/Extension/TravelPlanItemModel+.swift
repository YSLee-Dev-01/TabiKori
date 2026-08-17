//
//  TravelPlanItemModel+.swift
//  Data
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

extension TravelPlanItemModel {
    var toDomain: TravelPlanItem {
        TravelPlanItem(
            id: self.id,
            planId: self.planId,
            order: self.order,
            title: self.title,
            note: self.note,
            isChecked: self.isChecked
        )
    }

    convenience init(item: TravelPlanItem) {
        self.init(
            id: item.id,
            planId: item.planId,
            order: item.order,
            title: item.title,
            note: item.note,
            isChecked: item.isChecked
        )
    }
}

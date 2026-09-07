//
//  ShoppingPlanItemModel+.swift
//  Data
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

extension ShoppingPlanItemModel {
    var toDomain: ShoppingPlanItem {
        ShoppingPlanItem(
            id: self.id,
            planId: self.planId,
            order: self.order,
            title: self.title,
            note: self.note,
            isChecked: self.isChecked
        )
    }

    convenience init(item: ShoppingPlanItem) {
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

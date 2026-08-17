//
//  TravelPlanItemModel.swift
//  Data
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class TravelPlanItemModel {
    @Attribute(.unique) var id: UUID
    var planId: UUID
    var order: Int
    var title: String
    var note: String?
    var isChecked: Bool

    init(
        id: UUID,
        planId: UUID,
        order: Int,
        title: String,
        note: String?,
        isChecked: Bool
    ) {
        self.id = id
        self.planId = planId
        self.order = order
        self.title = title
        self.note = note
        self.isChecked = isChecked
    }
}

//
//  TravelPlanItem.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct TravelPlanItem: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let planId: UUID
    public let order: Int
    public let title: String
    public let note: String?
    public var isChecked: Bool

    public init(id: UUID, planId: UUID, order: Int, title: String, note: String?, isChecked: Bool) {
        self.id = id
        self.planId = planId
        self.order = order
        self.title = title
        self.note = note
        self.isChecked = isChecked
    }
}

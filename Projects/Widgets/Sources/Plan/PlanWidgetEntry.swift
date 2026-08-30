//
//  PlanWidgetEntry.swift
//  Widget
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import WidgetKit

import Domain

struct PlanWidgetEntry: TimelineEntry {
    let date: Date
    let item: PlanWidgetSnapshotItem?

    /// 진행 중인 일정일 때의 일자 인덱스(0-based), 진행 중이 아니면 nil
    var dayIndex: Int? {
        self.item?.dayIndex(on: self.date)
    }

    /// 아직 시작하지 않은 일정일 때 남은 일수, 진행 중이거나 일정이 없으면 nil
    var daysUntilStart: Int? {
        guard let item = self.item, self.dayIndex == nil else { return nil }
        return item.daysUntilStart(on: self.date)
    }
}

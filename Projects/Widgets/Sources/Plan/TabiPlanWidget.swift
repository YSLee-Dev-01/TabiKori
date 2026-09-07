//
//  TabiPlanWidget.swift
//  Widget
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import WidgetKit

import Domain
import Resource

struct TabiPlanWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.plan, provider: PlanTimelineProvider()) { entry in
            PlanWidgetView(entry: entry)
        }
        .configurationDisplayName(Strings.Widget.planDisplayName)
        .description(Strings.Widget.planDescription)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

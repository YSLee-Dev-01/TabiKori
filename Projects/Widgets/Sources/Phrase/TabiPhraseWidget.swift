//
//  TabiPhraseWidget.swift
//  Widget
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import WidgetKit

import Domain
import Resource

struct TabiPhraseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.phrase, provider: PhraseTimelineProvider()) { entry in
            PhraseWidgetView(entry: entry)
        }
        .configurationDisplayName(Strings.Widget.phraseDisplayName)
        .description(Strings.Widget.phraseDescription)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

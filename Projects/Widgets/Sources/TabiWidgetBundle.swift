//
//  TabiWidgetBundle.swift
//  Widget
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import WidgetKit

@main
struct TabiWidgetBundle: WidgetBundle {
    var body: some Widget {
        TabiPlanWidget()
        TabiPhraseWidget()
    }
}

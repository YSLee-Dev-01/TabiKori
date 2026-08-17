//
//  PlanDetailAddSpotButton.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct PlanDetailAddSpotButton: View {
    let action: () -> Void

    var body: some View {
        TabiButton(
            Strings.Plan.spotAddButtonTitle,
            style: .primary,
            isExpanded: true,
            height: 45,
            cornerRadius: .tabiRadiusFull
        ) {
            self.action()
        }
    }
}

//
//  PlanDetailDayButton.swift
//  Presentation
//
//  Created by 이윤수 on 8/1/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct PlanDetailDayButton: View {
    let dayTitle: String
    let dateTitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            self.action()
        } label: {
            VStack(spacing: 4) {
                TabiLabel(
                    title: self.dayTitle,
                    style: .captionMBold,
                    color: self.isSelected ? .tabiOnColor : .tabiTextPrimary
                )
                TabiLabel(
                    title: self.dateTitle,
                    style: .captionM,
                    color: self.isSelected ? .tabiOnColor : .tabiTextSecondary
                )
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(self.isSelected ? TabiColor.tabiPrimary : TabiColor.tabiSurface)
            .clipShape(Capsule())
            .overlay {
                if !self.isSelected {
                    Capsule().stroke(TabiColor.tabiBorder, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.tabiFast, value: self.isSelected)
    }
}

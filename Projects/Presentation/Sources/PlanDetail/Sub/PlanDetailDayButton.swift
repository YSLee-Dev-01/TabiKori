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
            VStack(spacing: 3) {
                TabiLabel(
                    title: self.dayTitle,
                    style: .bodySBold,
                    color: self.isSelected ? .tabiOnColor : .tabiTextPrimary
                )
                TabiLabel(
                    title: self.dateTitle,
                    style: .captionS,
                    color: self.isSelected ? .tabiOnColor : .tabiTextSecondary
                )
            }
            .frame(minWidth: 56)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(self.isSelected ? TabiColor.tabiPrimary : TabiColor.tabiSurface)
            .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))
            .overlay {
                RoundedRectangle(cornerRadius: .tabiRadiusMd)
                    .stroke(
                        self.isSelected ? Color.clear : Color.getTabiColor(.tabiBorder),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: self.isSelected ? Color.getTabiColor(.tabiPrimary).opacity(0.28) : .clear,
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(.tabiPress)
        .animation(.tabiFast, value: self.isSelected)
    }
}

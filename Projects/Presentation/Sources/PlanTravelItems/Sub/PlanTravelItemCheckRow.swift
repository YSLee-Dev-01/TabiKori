//
//  PlanTravelItemCheckRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct PlanTravelItemCheckRow: View {
    let item: TravelPlanItem
    let onTap: () -> Void

    var body: some View {
        Button {
            self.onTap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: self.item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(self.item.isChecked ? TabiColor.tabiPrimary : TabiColor.tabiTextTertiary)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 4) {
                    TabiLabel(
                        title: self.item.title,
                        style: .bodyMBold,
                        color: self.item.isChecked ? .tabiTextTertiary : .tabiTextPrimary
                    )
                    if let note = self.item.note, note.isEmpty == false {
                        TabiLabel(title: note, style: .captionM, color: .tabiTextTertiary)
                    }
                }

                Spacer()
            }
            .animation(.tabiFast, value: self.item.isChecked)
        }
        .buttonStyle(TabiPressStyle())
    }
}

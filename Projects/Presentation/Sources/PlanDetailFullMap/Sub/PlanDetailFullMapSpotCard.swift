//
//  PlanDetailFullMapSpotCard.swift
//  Presentation
//
//  Created by 이윤수 on 8/21/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct PlanDetailFullMapSpotCard: View {
    static let width: CGFloat = 260
    static let height: CGFloat = 100

    let spot: TravelPlanDetailSpot
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    TabiTag(self.spot.category.label, color: self.spot.category.color)
                    Spacer()
                    TabiLabel(title: self.spot.startTimeTitle, style: .captionMBold, color: .tabiTextSecondary)
                }
                TabiLabel(title: self.spot.title, style: .bodyMBold, color: .tabiTextPrimary, lineLimit: 1)
                if let subtitle = self.spot.subtitle {
                    TabiLabel(title: subtitle, style: .captionM, color: .tabiTextSecondary, lineLimit: 1)
                }
            }
            .padding(12)
            .frame(width: Self.width, height: Self.height, alignment: .topLeading)
            .background(TabiColor.tabiSurface)
            .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusLg))
            .overlay {
                RoundedRectangle(cornerRadius: .tabiRadiusLg)
                    .strokeBorder(
                        self.isSelected ? TabiColor.tabiPrimary.opacity(1) : TabiColor.tabiBorder.opacity(0.4),
                        lineWidth: self.isSelected ? 2 : 1
                    )
            }
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(TabiPressStyle())
    }
}

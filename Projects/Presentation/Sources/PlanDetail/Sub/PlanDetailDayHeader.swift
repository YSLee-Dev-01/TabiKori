//
//  PlanDetailDayHeader.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct PlanDetailDayHeader: View {
    let dateTitle: String
    let spotCountTitle: String
    var onTravelItemsTapped: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .foregroundStyle(TabiColor.tabiTextSecondary)

            VStack(alignment: .leading, spacing: 2) {
                TabiLabel(title: self.dateTitle, style: .bodyMBold, color: .tabiTextPrimary)
                TabiLabel(title: self.spotCountTitle, style: .captionM, color: .tabiTextSecondary)
            }

            if let onTravelItemsTapped {
                Spacer()

                Button(action: onTravelItemsTapped) {
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox")
                        TabiLabel(title: Strings.TravelItems.planDetailEntryTitle, style: .captionMBold, color: .tabiPrimary)
                    }
                    .foregroundStyle(TabiColor.tabiPrimary)
                }
                .buttonStyle(TabiPressStyle())
            }
        }
    }
}

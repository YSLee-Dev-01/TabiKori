//
//  PlanDetailFullMapSpotRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

/// 지도 전체화면 좌측 세로 리스트 행. 탭하거나 스크롤 스냅으로 뷰포트에 정착하면 지도 카메라가 해당 스팟으로 포커스된다
struct PlanDetailFullMapSpotRow: View {
    let spot: TravelPlanDetailSpot
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            TabiCard {
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
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay {
                RoundedRectangle(cornerRadius: .tabiRadiusLg)
                    .stroke(TabiColor.tabiPrimary.opacity(self.isSelected ? 1 : 0), lineWidth: 2)
            }
        }
        .buttonStyle(TabiPressStyle())
    }
}

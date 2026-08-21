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

/// 지도 전체화면 하단 가로 스크롤 카드 캐러셀의 카드 한 장.
/// 세로 리스트용 `PlanDetailFullMapSpotRow`와 달리 고정 너비 카드로 가로 스와이프 정착에 맞춰 레이아웃이 구성되어 별도 컴포넌트로 분리함
struct PlanDetailFullMapSpotCard: View {
    static let width: CGFloat = 260

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
                .frame(width: Self.width, alignment: .leading)
            }
            .overlay {
                RoundedRectangle(cornerRadius: .tabiRadiusLg)
                    .stroke(TabiColor.tabiPrimary.opacity(self.isSelected ? 1 : 0), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(TabiPressStyle())
    }
}

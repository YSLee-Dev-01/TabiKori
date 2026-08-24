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
/// 세로 리스트용 `PlanDetailFullMapSpotRow`와 달리 고정 너비 카드로 가로 스와이프 정착에 맞춰 레이아웃이 구성되어 별도 컴포넌트로 분리함.
/// `TabiCard`를 재사용하지 않고 배경/테두리를 직접 구성한다 — TabiCard의 자체 테두리(opacity 0.4)와
/// 선택 상태 테두리가 이중으로 겹쳐 그려지며 삐뚤빼뚤하게 보이는 문제가 있어, 단일 테두리만 그린다
struct PlanDetailFullMapSpotCard: View {
    static let width: CGFloat = 260
    /// subtitle 유무와 무관하게 카드 높이를 고정해, 캐러셀 카드들의 세로 크기가 항상 동일하게 한다
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
                    .stroke(
                        self.isSelected ? TabiColor.tabiPrimary.opacity(1) : TabiColor.tabiBorder.opacity(0.4),
                        lineWidth: self.isSelected ? 2 : 1
                    )
            }
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(TabiPressStyle())
    }
}

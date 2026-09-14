//
//  PlanDetailSpotRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct PlanDetailSpotRow: View {
    let spot: TravelPlanDetailSpot
    let index: Int
    let isFirst: Bool
    let isLast: Bool
    let isEditing: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TabiLabel(title: self.spot.startTimeTitle, style: .captionMBold, color: .tabiTextSecondary)
                .frame(width: 40, alignment: .leading)
                .padding(.top, 4)

            self.timeline

            TabiCard {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        TabiTag(self.spot.category.label, color: self.spot.category.color)
                        TabiLabel(title: self.mainTitle, style: .bodyMBold, color: .tabiTextPrimary)
                        if let subTitle = self.subTitle {
                            TabiLabel(title: subTitle, style: .captionM, color: .tabiTextSecondary)
                        }
                        TabiLabel(title: self.spot.durationTitle, style: .captionM, color: .tabiTextTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if self.isEditing == false {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(TabiColor.tabiTextTertiary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Method

private extension PlanDetailSpotRow {
    /// 지하철역 스팟(`isStation == true`)이고 로케일이 한국어이면 한국어 역명을 메인(볼드)으로 표시.
    /// 일반 스팟은 `subtitle`이 한국어 표기가 아닌 주소일 수 있어(`AddToItineraryFeature`) 스왑 대상에서 제외
    var mainTitle: String {
        if self.spot.isStation, Locale.isKoreanLanguage, let subtitle = self.spot.subtitle {
            return subtitle
        }
        return self.spot.title
    }

    var subTitle: String? {
        if self.spot.isStation, Locale.isKoreanLanguage, self.spot.subtitle != nil {
            return self.spot.title
        }
        return self.spot.subtitle
    }
}

// MARK: - View

private extension PlanDetailSpotRow {
    var timeline: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(TabiColor.tabiBorder)
                .opacity(self.isFirst ? 0 : 1)
                .frame(width: 2)

            Circle()
                .fill(self.spot.category.color)
                .overlay {
                    TabiLabel(title: "\(self.index)", style: .captionXSBold, color: .tabiOnColor)
                }
                .frame(width: 22, height: 22)

            Rectangle()
                .fill(TabiColor.tabiBorder)
                .opacity(self.isLast ? 0 : 1)
                .frame(width: 2)
        }
        .frame(width: 22)
    }
}

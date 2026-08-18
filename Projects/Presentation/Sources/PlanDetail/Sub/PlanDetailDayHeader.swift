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
    /// 전체보기(Section 헤더)에서만 노출하고, 단일 일자 뷰에서는 nil로 넘겨 생략한다
    let spotCountTitle: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .foregroundStyle(TabiColor.tabiTextSecondary)

            VStack(alignment: .leading, spacing: 2) {
                TabiLabel(title: self.dateTitle, style: .bodyMBold, color: .tabiTextPrimary, lineLimit: 1)
                if let spotCountTitle {
                    TabiLabel(title: spotCountTitle, style: .captionM, color: .tabiTextSecondary, lineLimit: 1)
                }
            }
        }
    }
}

//
//  FestivalEmptyState.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct FestivalEmptyState: View {

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 34))
                    .foregroundStyle(TabiColor.tabiTextTertiary)

                VStack(spacing: 3) {
                    TabiLabel(title: Strings.Festival.emptyTitle, style: .bodySBold, color: .tabiTextSecondary)
                    TabiLabel(
                        title: Strings.Festival.emptyDescription,
                        style: .captionM,
                        color: .tabiTextTertiary,
                        alignment: .center
                    )
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}

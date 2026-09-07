//
//  HomeAnnouncementCard.swift
//  Presentation
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// 홈 화면 시트 공지 진입 카드. 활성 공지가 있을 때만 노출되며, 탭하면 공지 시트가 열린다
struct HomeAnnouncementCard: View {
    let title: String
    let subtitle: String
    let onTap: () -> Void

    var body: some View {
        Button {
            self.onTap()
        } label: {
            TabiCard {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(TabiColor.tabiAccentMint)

                    VStack(alignment: .leading, spacing: 3) {
                        TabiLabel(title: self.title, style: .bodyLBold, color: .tabiTextPrimary, lineLimit: 1)

                        if self.subtitle.isEmpty == false {
                            TabiLabel(
                                title: self.subtitle,
                                style: .bodyS,
                                color: .tabiTextSecondary,
                                isExpanded: true,
                                lineLimit: 1
                            )
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TabiColor.tabiTextTertiary)
                }
                .padding(16)
            }
        }
        .buttonStyle(TabiPressStyle())
    }
}

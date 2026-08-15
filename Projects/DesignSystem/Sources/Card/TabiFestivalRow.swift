//
//  TabiFestivalRow.swift
//  DesignSystem
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Kingfisher
import Resource

public struct TabiFestivalRow: View {
    private let thumbnailURL: URL?
    private let japaneseTitle: String
    private let koreanTitle: String?
    private let periodTitle: String
    private let onTap: () -> Void

    public init(
        thumbnailURL: URL?,
        japaneseTitle: String,
        koreanTitle: String?,
        periodTitle: String,
        onTap: @escaping () -> Void
    ) {
        self.thumbnailURL = thumbnailURL
        self.japaneseTitle = japaneseTitle
        self.koreanTitle = koreanTitle
        self.periodTitle = periodTitle
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            self.onTap()
        } label: {
            HStack(spacing: 12) {
                KFImage(self.thumbnailURL)
                    .placeholder {
                        Color.getTabiColor(.tabiBorder).opacity(0.25)
                            .overlay {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                    .foregroundStyle(TabiColor.tabiTextTertiary)
                            }
                    }
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))

                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        TabiLabel(title: self.japaneseTitle, style: .bodyMBold, color: .tabiTextPrimary, lineLimit: 1)

                        if let koreanTitle = self.koreanTitle {
                            TabiLabel(title: koreanTitle, style: .captionM, color: .tabiTextSecondary, lineLimit: 1)
                        }
                    }

                    TabiLabel(title: self.periodTitle, style: .captionM, color: .tabiTextTertiary)
                }

                Spacer()
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabiPressStyle())
    }
}

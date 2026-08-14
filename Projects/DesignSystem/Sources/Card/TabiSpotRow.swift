//
//  TabiSpotRow.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Kingfisher
import Resource

public struct TabiSpotRow: View {
    private let thumbnailURL: URL?
    private let japaneseTitle: String
    private let koreanTitle: String?
    private let address: String?
    private let tagTitle: String
    private let tagColor: TabiColor
    private let isCustom: Bool
    private let distance: String?
    private let onTap: () -> Void

    public init(
        thumbnailURL: URL?,
        japaneseTitle: String,
        koreanTitle: String?,
        address: String? = nil,
        tagTitle: String,
        tagColor: TabiColor,
        isCustom: Bool,
        distance: String?,
        onTap: @escaping () -> Void
    ) {
        self.thumbnailURL = thumbnailURL
        self.japaneseTitle = japaneseTitle
        self.koreanTitle = koreanTitle
        self.address = address
        self.tagTitle = tagTitle
        self.tagColor = tagColor
        self.isCustom = isCustom
        self.distance = distance
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
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 16))
                                    .foregroundStyle(TabiColor.tabiTextTertiary)
                            }
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))

                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        TabiLabel(title: self.japaneseTitle, style: .bodyMBold, color: .tabiTextPrimary, lineLimit: 1)

                        if let koreanTitle = self.koreanTitle {
                            TabiLabel(title: koreanTitle, style: .captionM, color: .tabiTextSecondary, lineLimit: 1)
                        }

                        if let address = self.address {
                            TabiLabel(title: address, style: .captionM, color: .tabiTextTertiary, lineLimit: 1)
                        }
                    }

                    HStack(spacing: 6) {
                        TabiTag(self.tagTitle, color: self.tagColor)

                        if self.isCustom {
                            TabiTag(Strings.AddCustomPlace.customBadgeTitle, color: .tabiTextTertiary)
                        }
                    }
                }

                Spacer()

                if let distance = self.distance {
                    self.distanceLabel(distance)
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabiPressStyle())
    }
}

// MARK: - View

private extension TabiSpotRow {
    func distanceLabel(_ distance: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "location.fill")
                .font(.system(size: 10))
                .foregroundStyle(TabiColor.tabiTextTertiary)
            TabiLabel(title: distance, style: .captionM, color: .tabiTextTertiary)
        }
    }
}

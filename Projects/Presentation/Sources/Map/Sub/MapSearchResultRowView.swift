//
//  MapSearchResultRowView.swift
//  Presentation
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Kingfisher
import Resource

struct MapSearchResultRowView: View {

    var spot: TouristSpot
    var onTapped: () -> Void

    var body: some View {
        Button {
            self.onTapped()
        } label: {
            HStack(spacing: 12) {
                KFImage(self.spot.thumbnailURL)
                    .placeholder {
                        Color.getTabiColor(.tabiBorder).opacity(0.25)
                            .overlay {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 16))
                                    .foregroundStyle(TabiColor.tabiTextTertiary)
                            }
                    }
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))

                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        TabiLabel(title: self.spot.japaneseTitle, style: .bodyMBold, color: .tabiTextPrimary, lineLimit: 1)

                        if let korean = self.spot.koreanTitle {
                            TabiLabel(title: korean, style: .captionM, color: .tabiTextSecondary, lineLimit: 1)
                        }
                    }

                    TabiTag(self.spot.contentType.label, color: self.spot.contentType.color)
                }

                Spacer()

                if let distance = self.spot.formattedDistance {
                    self.distanceLabel(distance)
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabiPressStyle())
    }
}

// MARK: - TouristSpot View Extension

private extension TouristSpot {
    var formattedDistance: String? {
        guard let dist = self.distanceMeters else { return nil }
        if dist >= 1000 { return String(format: "%.1fkm", dist / 1000) }
        return "\(Int(dist))m"
    }
}

// MARK: - View

private extension MapSearchResultRowView {
    func distanceLabel(_ distance: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "location.fill")
                .font(.system(size: 10))
                .foregroundStyle(TabiColor.tabiTextTertiary)
            TabiLabel(title: distance, style: .captionM, color: .tabiTextTertiary)
        }
    }
}

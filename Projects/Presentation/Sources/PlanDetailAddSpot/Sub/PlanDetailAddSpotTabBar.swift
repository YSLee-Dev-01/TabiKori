//
//  PlanDetailAddSpotTabBar.swift
//  Presentation
//
//  Created by 이윤수 on 8/5/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct PlanDetailAddSpotTabBar: View {
    let selectedTab: PlanDetailAddSpotFeature.State.Tab
    let onTabSelected: (PlanDetailAddSpotFeature.State.Tab) -> Void

    var body: some View {
        HStack(spacing: 8) {
            self.tabButton(title: Strings.Plan.spotAddSearchTabTitle, tab: .search)
            self.tabButton(title: Strings.Bookmark.title, tab: .bookmark)
        }
    }
}

// MARK: - View

private extension PlanDetailAddSpotTabBar {
    func tabButton(title: String, tab: PlanDetailAddSpotFeature.State.Tab) -> some View {
        let isSelected = self.selectedTab == tab
        return Button {
            self.onTabSelected(tab)
        } label: {
            TabiLabel(
                title: title,
                style: isSelected ? .captionMBold : .captionM,
                color: isSelected ? .tabiOnColor : .tabiTextSecondary
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? TabiColor.tabiPrimary : TabiColor.tabiSurface)
            .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))
            .overlay {
                if isSelected == false {
                    RoundedRectangle(cornerRadius: .tabiRadiusMd)
                        .stroke(TabiColor.tabiBorder, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.tabiFast, value: isSelected)
    }
}

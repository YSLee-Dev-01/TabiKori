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
            TabiChip(Strings.Plan.spotAddSearchTabTitle, isSelected: self.selectedTab == .search) {
                self.onTabSelected(.search)
            }
            TabiChip(Strings.Bookmark.title, isSelected: self.selectedTab == .bookmark) {
                self.onTabSelected(.bookmark)
            }
        }
    }
}

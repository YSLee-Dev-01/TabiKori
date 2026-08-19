//
//  AddCustomPlaceTabBar.swift
//  Presentation
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// "검색" / "커스텀" 두 탭을 오가는 이 화면 전용 탭 전환 UI.
/// DesignSystem에 별도 세그먼트 컴포넌트는 없으나, PlanDetailAddSpotTabBar가 동일한 목적(탭 전환)으로
/// TabiChip을 재사용하는 기존 관례가 있어 그 패턴을 그대로 따른다
struct AddCustomPlaceTabBar: View {
    let selectedTab: AddCustomPlaceTab
    let onSelect: (AddCustomPlaceTab) -> Void

    var body: some View {
        HStack(spacing: 8) {
            TabiChip(Strings.AddCustomPlace.searchTabLabel, isSelected: self.selectedTab == .search) {
                self.onSelect(.search)
            }
            TabiChip(Strings.AddCustomPlace.customTabLabel, isSelected: self.selectedTab == .custom) {
                self.onSelect(.custom)
            }
        }
    }
}

//
//  PlanDetailView.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Resource

/// 일정 상세 화면 스켈레톤. 실제 UI는 이후 별도 기능에서 구현한다
public struct PlanDetailView: View {

    private let store: StoreOf<PlanDetailFeature>

    public init(store: StoreOf<PlanDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            TabiLabel(title: Strings.Plan.title, style: .titleM, color: .tabiTextPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

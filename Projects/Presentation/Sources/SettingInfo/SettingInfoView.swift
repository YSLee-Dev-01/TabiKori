//
//  SettingInfoView.swift
//  Presentation
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Resource

public struct SettingInfoView: View {

    @Bindable private var store: StoreOf<SettingInfoFeature>

    public init(store: StoreOf<SettingInfoFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            TabiLabel(
                title: self.store.contentType.content,
                style: .bodyM,
                color: .tabiTextPrimary,
                isExpanded: true
            )
            .padding(20)
        }
        .safeAreaBar(edge: .top) {
            TabiNavigationBar(title: self.store.contentType.title) {
                self.closeButton()
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - View

private extension SettingInfoView {
    func closeButton() -> some View {
        Button {
            self.store.send(.closeTapped)
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(TabiColor.tabiTextSecondary)
                .frame(width: 32, height: 32)
                .background(TabiColor.tabiSurface)
                .clipShape(Circle())
        }
        .buttonStyle(TabiPressStyle())
    }
}

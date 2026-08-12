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
        NavigationStack {
            ScrollView {
                TabiLabel(
                    title: self.store.contentType.content,
                    style: .bodyM,
                    color: .tabiTextPrimary,
                    isExpanded: true
                )
                .padding(20)
            }
            .navigationTitle(self.store.contentType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        self.store.send(.closeTapped)
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(Color.getTabiColor(.tabiPrimary))
                }
            }
        }
    }
}

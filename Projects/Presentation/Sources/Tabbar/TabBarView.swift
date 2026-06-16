//
//  TabBarView.swift
//  Presentation
//
//  Created by 이윤수 on 6/16/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture

public struct TabBarView: View {

    @State private var store: StoreOf<TabBarFeature>

    public init(store: StoreOf<TabBarFeature>) {
        self.store = store
    }

    public var body: some View {
        TabView(selection: self.$store.selectedTab.sending(\.tabSelected)) {
            HomeView(store: self.store.scope(state: \.homeState, action: \.home))
                .tabItem {
                    Image(systemName: AppTab.home.systemImage)
                }
                .tag(AppTab.home)

            Text("지도")
                .tabItem {
                    Image(systemName: AppTab.map.systemImage)
                }
                .tag(AppTab.map)

            Text("계획")
                .tabItem {
                    Image(systemName: AppTab.plan.systemImage)
                }
                .tag(AppTab.plan)

            Text("저장")
                .tabItem {
                    Image(systemName: AppTab.save.systemImage)
                }
                .tag(AppTab.save)

            Text("검색")
                .tabItem {
                    Image(systemName: AppTab.search.systemImage)
                }
                .tag(AppTab.search)
        }
    }
}

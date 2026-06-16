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

            Text(AppTab.map.title)
                .tabItem {
                    Image(systemName: AppTab.map.systemImage)
                }
                .tag(AppTab.map)

            Text(AppTab.plan.title)
                .tabItem {
                    Image(systemName: AppTab.plan.systemImage)
                }
                .tag(AppTab.plan)

            Text(AppTab.save.title)
                .tabItem {
                    Image(systemName: AppTab.save.systemImage)
                }
                .tag(AppTab.save)

            Text(AppTab.search.title)
                .tabItem {
                    Image(systemName: AppTab.search.systemImage)
                }
                .tag(AppTab.search)
        }
    }
}

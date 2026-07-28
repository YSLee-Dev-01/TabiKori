//
//  TabBarView.swift
//  Presentation
//
//  Created by 이윤수 on 6/16/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import Resource

public struct TabBarView: View {

    @State private var store: StoreOf<TabBarFeature>
    @Namespace private var heroNamespace

    public init(store: StoreOf<TabBarFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(
            path: self.$store.scope(state: \.path, action: \.path)
        ) {
            TabView(selection: self.$store.selectedTab.sending(\.tabSelected)) {
                HomeView(
                    store: self.store.scope(state: \.homeState, action: \.home),
                    namespace: self.heroNamespace
                )
                    .tabItem {
                        Image(systemName: AppTab.home.systemImage)
                    }
                    .tag(AppTab.home)

                MapView(store: self.store.scope(state: \.mapState, action: \.map))
                    .tabItem {
                        Image(systemName: AppTab.map.systemImage)
                    }
                    .tag(AppTab.map)

                Text(AppTab.plan.title)
                    .tabItem {
                        Image(systemName: AppTab.plan.systemImage)
                    }
                    .tag(AppTab.plan)

                BookmarkView(store: self.store.scope(state: \.bookmarkState, action: \.bookmark))
                    .tabItem {
                        Image(systemName: AppTab.bookmark.systemImage)
                    }
                    .tag(AppTab.bookmark)
            }
            .tint(Color.getTabiColor(.tabiPrimary))
        } destination: { store in
            switch store.case {
            case .detail(let store):
                DetailView(store: store, namespace: self.heroNamespace)
            case .photoViewer(let store):
                PhotoViewerView(store: store)
            }
        }
    }
}

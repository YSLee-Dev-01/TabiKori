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

                PlanView(store: self.store.scope(state: \.planState, action: \.plan))
                    .tabItem {
                        Image(systemName: AppTab.plan.systemImage)
                    }
                    .tag(AppTab.plan)

                BookmarkView(store: self.store.scope(state: \.bookmarkState, action: \.bookmark))
                    .tabItem {
                        Image(systemName: AppTab.bookmark.systemImage)
                    }
                    .tag(AppTab.bookmark)

                ToolBarView(store: self.store.scope(state: \.toolboxState, action: \.toolbox))
                    .tabItem {
                        Image(systemName: AppTab.toolbox.systemImage)
                    }
                    .tag(AppTab.toolbox)
            }
            .tint(Color.getTabiColor(.tabiPrimary))
        } destination: { store in
            switch store.case {
            case .detail(let store):
                DetailView(store: store, namespace: self.heroNamespace)
            case .photoViewer(let store):
                PhotoViewerView(store: store)
            case .planDetail(let store):
                PlanDetailView(store: store)
            case .festival(let store):
                FestivalView(store: store)
            case .region(let store):
                RegionSpotView(store: store)
            case .setting(let store):
                SettingView(store: store)
            case .planToolBar(let store):
                PlanToolBarView(store: store)
            case .packingList(let store):
                PackingListView(store: store)
            case .koreanPhraseList(let store):
                KoreanPhraseListView(store: store)
            }
        }
    }
}

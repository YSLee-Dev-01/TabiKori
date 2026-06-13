//
//  HomeView.swift
//  Presentation
//
//  Created by 이윤수 on 6/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

public struct HomeView: View {
    
    @State private var store: StoreOf<HomeFeature>
    
    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }
    
    public var body: some View {
        Text(self.store.text)
    }
}

#Preview {
    HomeView(store: .init(
        initialState: .init(),
        reducer: {
            HomeFeature()
        }))
}

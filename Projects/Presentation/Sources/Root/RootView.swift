//
//  RootView.swift
//  Presentation
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture

public struct RootView: View {
    
    @State private var store: StoreOf<RootFeature>
    
    public init(store: StoreOf<RootFeature>) {
        self.store = store
    }
    
    public var body: some View {
        Text(self.store.text)
            .onAppear {
                self.store.send(.onAppear)
            }
    }
}

#Preview {
    RootView(store: .init(
        initialState: .init(),
        reducer: {
            RootFeature()
        }))
}

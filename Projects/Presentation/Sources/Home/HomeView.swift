//
//  HomeView.swift
//  Presentation
//
//  Created by 이윤수 on 6/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import ComposableArchitecture

public struct HomeView: View {
    
    @State private var store: StoreOf<HomeFeature>
    
    private let testColor = [Color.red, Color.blue, Color.green]
    
    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                ForEach((0 ... 40).map {"\($0)"}, id: \.self) { text in
                    Text(text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(testColor.randomElement()!)
                }
            }
            .safeAreaBar(edge: .top) {
                TabiNavigationBar(subtitle: "6월 17일 (수)", title: "타비코리") {
                    TabiGlassIconButton(systemName: "bell") {
                        print("123")
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(store: .init(
        initialState: .init(),
        reducer: {
            HomeFeature()
        }))
}

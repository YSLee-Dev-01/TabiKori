//
//  TabiKoriApp.swift
//  App
//
//  Created by 이윤수 on 6/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import Presentation

@main
struct TabiKoriApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(store: Store(
                initialState: .init(),
                reducer: { RootFeature() }
            ))
        }
    }
}

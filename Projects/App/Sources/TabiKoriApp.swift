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
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct TabiKoriApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView(store: Store(
                initialState: .init(),
                reducer: { RootFeature() }
            ))
        }
    }
}

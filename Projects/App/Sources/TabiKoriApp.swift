//
//  TabiKoriApp.swift
//  App
//
//  Created by 이윤수 on 6/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import Core
import Presentation
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        return true
    }

    /// 앱 전역은 portrait로 고정하되, OrientationLock에 등록된 값이 있으면(가로모드가 필요한 화면 진입 시) 그 값을 따른다
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return OrientationLock.shared.mask
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

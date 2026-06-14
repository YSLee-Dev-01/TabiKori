//
//  TabiKoriApp.swift
//  App
//
//  Created by 이윤수 on 6/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DIContainer

@main
struct TabiKoriApp: App {
    
    private let diContainer =  AppDIContainer()
    
    var body: some Scene {
        WindowGroup {
            self.diContainer.makeHomeView()
        }
    }
}

//
//  AppConfig.swift
//  Core
//
//  Created by 이윤수 on 6/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

final class AppConfig: Sendable {
    
    // MARK: - Singleton
    
    static let shared = AppConfig()
    private init() {}
    
    // MARK: - Log
    
    /// 뷰와 관련된 로그 표출 여부를 관리해요.
    let enableViewLog = true
    
    /// Coordinator와 관련된 로그 표출 여부를 관리해요.
    let enableCoordinatorLog = true
    
    /// 네트워크와 관련된 로그 표출 여부를 관리해요.
    let enableTotalNetworkLog = true
    
    /// 코어 로직과 관련된 로그 표출 여부를 관리해요.
    let enableCoreLog = true
}

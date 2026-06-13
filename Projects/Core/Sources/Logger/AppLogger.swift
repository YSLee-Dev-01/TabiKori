//
//  AppLogger.swift
//  Core
//
//  Created by 이윤수 on 6/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import OSLog

struct AppLogger {
    private let logger: Logger
    private let categoryName: String
    private let totalLogEnabled: Bool
    
    enum LogLevel {
        case error, info, debug
    }
    
    func log(_ level: LogLevel, _ message: String, enableLog: Bool = true) {
        if !enableLog || !self.totalLogEnabled {return}
        
        switch level {
        case .info: self.logger.info("\(self.categoryName): \(message)")
        case .error: self.logger.error("\(self.categoryName): \(message)")
        case .debug: self.logger.debug("\(self.categoryName): \(message)")
        }
    }
}

extension AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.yslee.tabikori"
    
    static let network = AppLogger(
        logger: Logger(subsystem: subsystem, category: "Network"),
        categoryName: "🛜 Network",
        totalLogEnabled: AppConfig.shared.enableTotalNetworkLog
    )
    
    static let core = AppLogger(
        logger: Logger(subsystem: subsystem, category: "Core"),
        categoryName: "💪 Core",
        totalLogEnabled: AppConfig.shared.enableCoreLog
    )
    
    static let view = AppLogger(
        logger: Logger(subsystem: subsystem, category: "View"),
        categoryName: "💬 View",
        totalLogEnabled: AppConfig.shared.enableViewLog
    )
    
    static let coordinator = AppLogger(
        logger: Logger(subsystem: subsystem, category: "Coordinator"),
        categoryName: "🧑‍🧑‍🧒‍🧒 Coordinator",
        totalLogEnabled: AppConfig.shared.enableCoordinatorLog
    )
}

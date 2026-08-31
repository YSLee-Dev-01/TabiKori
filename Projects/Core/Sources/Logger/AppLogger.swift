//
//  AppLogger.swift
//  Core
//
//  Created by 이윤수 on 6/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import OSLog

import FirebaseCrashlytics

public struct AppLogger: Sendable {
    private let logger: Logger
    private let categoryName: String
    private let totalLogEnabled: Bool

    public enum LogLevel {
        case error, info, debug
    }

    /// 위젯 등 App Extension 프로세스인지 여부. Extension 번들은 항상 `.appex`로 끝난다.
    /// FirebaseApp.configure()는 호스트 앱(TabiKoriApp) 프로세스에서만 호출되므로,
    /// Extension 프로세스에서 Crashlytics를 호출하면 미구성 상태 크래시로 이어진다.
    private static let isRunningInExtension = Bundle.main.bundlePath.hasSuffix(".appex")

    public func log(_ level: LogLevel, _ message: String, enableLog: Bool = true) {
        if !enableLog || !self.totalLogEnabled {return}

        switch level {
        case .info: self.logger.info("\(self.categoryName): \(message)")
        case .error:
            self.logger.error("\(self.categoryName): \(message)")
            if !Self.isRunningInExtension {
                Crashlytics.crashlytics().record(error: NSError(
                    domain: self.categoryName,
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: message]
                ))
            }
        case .debug: self.logger.debug("\(self.categoryName): \(message)")
        }
    }
}

#if DEBUG
extension AppLogger {
    /// Crashlytics 연동 검증용 강제 크래시 트리거. 디버그 빌드의 설정 화면에서만 노출된다
    public static func triggerTestCrash() {
        fatalError("Firebase Crashlytics 테스트 크래시")
    }
}
#endif

extension AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.yslee.tabikori"
    
    public static let network = AppLogger(
        logger: Logger(subsystem: subsystem, category: "Network"),
        categoryName: "🛜 Network",
        totalLogEnabled: AppConfig.shared.enableTotalNetworkLog
    )
    
    public static let core = AppLogger(
        logger: Logger(subsystem: subsystem, category: "Core"),
        categoryName: "💪 Core",
        totalLogEnabled: AppConfig.shared.enableCoreLog
    )
    
    public static let view = AppLogger(
        logger: Logger(subsystem: subsystem, category: "View"),
        categoryName: "💬 View",
        totalLogEnabled: AppConfig.shared.enableViewLog
    )
}

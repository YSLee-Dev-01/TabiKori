//
//  AppUpdateInfo.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct AppUpdateInfo: Equatable, Sendable {
    public let minimumVersion: String

    public init(minimumVersion: String) {
        self.minimumVersion = minimumVersion
    }
}

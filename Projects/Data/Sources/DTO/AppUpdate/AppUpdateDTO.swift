//
//  AppUpdateDTO.swift
//  Data
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

struct AppUpdateDTO {
    let minimumVersion: String
}

// MARK: - Mapping

extension AppUpdateDTO {
    func toEntity() -> AppUpdateInfo {
        return AppUpdateInfo(minimumVersion: self.minimumVersion)
    }
}

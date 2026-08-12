//
//  SettingInfoContentType.swift
//  Presentation
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Resource

public enum SettingInfoContentType: Equatable, Sendable {
    case dataSource
    case license

    var title: String {
        switch self {
        case .dataSource: return Strings.Setting.etcDataSourceTitle
        case .license: return Strings.Setting.etcLicenseTitle
        }
    }

    var content: String {
        switch self {
        case .dataSource: return Strings.Setting.dataSourceContent
        case .license: return Strings.Setting.licenseContent
        }
    }
}

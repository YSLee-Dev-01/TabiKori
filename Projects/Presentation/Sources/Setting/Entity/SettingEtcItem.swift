//
//  SettingEtcItem.swift
//  Presentation
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Resource

public enum SettingEtcItem: CaseIterable, Identifiable, Equatable {
    case dataSource
    case privacyPolicy
    case license
    case etcInfo
    case contact
    case version

    public var id: Self { self }

    public enum Kind: Equatable {
        case staticText(SettingInfoContentType)
        case versionDisplay
        case mailCompose
        case disabled
    }

    public var title: String {
        switch self {
        case .dataSource: return Strings.Setting.etcDataSourceTitle
        case .privacyPolicy: return Strings.Setting.etcPrivacyPolicyTitle
        case .license: return Strings.Setting.etcLicenseTitle
        case .etcInfo: return Strings.Setting.etcInfoTitle
        case .contact: return Strings.Setting.etcContactTitle
        case .version: return Strings.Setting.etcVersionTitle
        }
    }

    public var kind: Kind {
        switch self {
        case .dataSource: return .staticText(.dataSource)
        case .license: return .staticText(.license)
        case .etcInfo: return .staticText(.etcInfo)
        case .version: return .versionDisplay
        case .contact: return .mailCompose
        case .privacyPolicy: return .disabled
        }
    }
}

// MARK: - App Version

extension SettingEtcItem {
    public static var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return Strings.Setting.versionTitle(version, build)
    }
}

// MARK: - Contact

extension SettingEtcItem {
    /// 문의하기(お問い合わせ) 메일 수신 주소. 시크릿이 아니므로 코드에 직접 사용한다
    public static let contactEmailAddress = "contact.tabikori@gmail.com"
}

//
//  TabiError.swift
//  Domain
//
//  Created by 이윤수 on 7/9/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum TabiError: Error, Equatable, Sendable {
    case apiFailed(code: String, message: String)
    case dataNotFound
    case persistenceFailed(message: String)
    case decodingFailed(message: String)
    case encodingFailed(message: String)
}

// MARK: - LocalizedError

extension TabiError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .apiFailed:
            return "サーバーリクエストに失敗しました"
        case .dataNotFound:
            return "リクエストした情報が見つかりません"
        case .persistenceFailed:
            return "データの保存に失敗しました"
        case .decodingFailed:
            return "データの処理中にエラーが発生しました"
        case .encodingFailed:
            return "データの変換中にエラーが発生しました"
        }
    }
}

// MARK: - NetworkOriginatedError

extension TabiError: NetworkOriginatedError {
    /// 네트워크(API) 통신이 원인이 되어 발생한 에러인지 여부
    public var isNetworkOriginated: Bool {
        switch self {
        case .apiFailed:
            return true
        case .dataNotFound, .persistenceFailed, .decodingFailed, .encodingFailed:
            return false
        }
    }
}

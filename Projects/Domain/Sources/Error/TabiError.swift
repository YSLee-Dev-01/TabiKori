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
            return "서버 요청에 실패했습니다"
        case .dataNotFound:
            return "요청하신 정보를 찾을 수 없습니다"
        case .persistenceFailed:
            return "데이터 저장에 실패했습니다"
        case .decodingFailed:
            return "데이터를 처리하는 중 오류가 발생했습니다"
        case .encodingFailed:
            return "데이터를 변환하는 중 오류가 발생했습니다"
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

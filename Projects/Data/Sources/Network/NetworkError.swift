//
//  NetworkError.swift
//  Data
//
//  Created by 이윤수 on 7/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

public enum NetworkError: Error, Equatable {
    case timeout
    case cancelled
    case invalidURL
    case decodingError
    case serverError
    case clientError
    case networkError
    case apiError
    case unknown
}

// MARK: - LocalizedError

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "네트워크 연결 시간이 초과되었습니다"
        case .cancelled:
            return "요청이 취소되었습니다"
        case .invalidURL:
            return "잘못된 요청 주소입니다"
        case .decodingError:
            return "데이터를 처리하는 중 오류가 발생했습니다"
        case .serverError:
            return "서버에 문제가 발생했습니다\n잠시 후 다시 시도해 주세요"
        case .clientError:
            return "요청 처리 중 오류가 발생했습니다"
        case .networkError:
            return "네트워크 연결 상태를 확인해 주세요"
        case .apiError:
            return "데이터를 불러오는 중 오류가 발생했습니다"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
}

// MARK: - NetworkOriginatedError

extension NetworkError: NetworkOriginatedError {
    /// 네트워크(API) 통신이 원인이 되어 발생한 에러인지 여부
    ///
    /// 사용자가 의도적으로 취소한 요청(`cancelled`)은 노출용 에러로 취급하지 않는다
    public var isNetworkOriginated: Bool {
        switch self {
        case .cancelled:
            return false
        case .timeout, .invalidURL, .decodingError, .serverError, .clientError, .networkError, .apiError, .unknown:
            return true
        }
    }
}

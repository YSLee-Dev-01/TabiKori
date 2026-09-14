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
        if Self.isKoreanLocale {
            switch self {
            case .timeout:
                return "네트워크 연결이 시간 초과되었어요"
            case .cancelled:
                return "요청이 취소되었어요"
            case .invalidURL:
                return "요청 주소가 올바르지 않아요"
            case .decodingError:
                return "데이터 처리 중 오류가 발생했어요"
            case .serverError:
                return "서버에 문제가 발생했어요\n잠시 후 다시 시도해주세요"
            case .clientError:
                return "요청 처리 중 오류가 발생했어요"
            case .networkError:
                return "네트워크 연결 상태를 확인해주세요"
            case .apiError:
                return "데이터를 불러오는 중 오류가 발생했어요"
            case .unknown:
                return "알 수 없는 오류가 발생했어요"
            }
        }

        switch self {
        case .timeout:
            return "ネットワーク接続がタイムアウトしました"
        case .cancelled:
            return "リクエストがキャンセルされました"
        case .invalidURL:
            return "リクエストのアドレスが正しくありません"
        case .decodingError:
            return "データの処理中にエラーが発生しました"
        case .serverError:
            return "サーバーに問題が発生しました\nしばらくしてからもう一度お試しください"
        case .clientError:
            return "リクエストの処理中にエラーが発生しました"
        case .networkError:
            return "ネットワーク接続状態をご確認ください"
        case .apiError:
            return "データの読み込み中にエラーが発生しました"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}

// MARK: - Method

private extension NetworkError {
    static var isKoreanLocale: Bool {
        return Locale.current.language.languageCode == .korean
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

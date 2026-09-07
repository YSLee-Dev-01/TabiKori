//
//  NetworkOriginatedError.swift
//  Domain
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// 네트워크(API) 통신이 원인이 되어 발생한 에러인지 판별하기 위한 마커 프로토콜
///
/// Domain은 Data를 참조하지 않으므로 Data의 `NetworkError` 타입을 직접 알 수 없다.
/// Data의 `NetworkError`가 이 프로토콜을 채택하면, Presentation은 Domain만 참조한 채로
/// `error as? NetworkOriginatedError`로 네트워크 기인 에러 여부를 판별할 수 있다.
public protocol NetworkOriginatedError: Error {
    var isNetworkOriginated: Bool { get }
}

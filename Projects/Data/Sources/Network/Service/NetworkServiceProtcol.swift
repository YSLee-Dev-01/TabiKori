//
//  NetworkServiceProtcol.swift
//  Data
//
//  Created by 이윤수 on 7/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol NetworkServiceProtocol: Sendable {
    /// 네트워크 통신과 디코딩을 동시에 진행할 때 사용해요.
    /// - Parameters:
    ///     - endPoint: 네트워크 통신을 요청하고 싶은 EndPoint
    ///     - responseType: 디코딩 하고 싶은 타입
    /// - Returns: 성공 시 디코딩된 타입, 실패 시 NetworkError
    func request<T: Decodable >(
        endPoint: Endpoint,
        responseType: T.Type
    ) async throws(NetworkError) -> T
}

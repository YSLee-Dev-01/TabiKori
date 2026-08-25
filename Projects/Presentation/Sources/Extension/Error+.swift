//
//  Error+.swift
//  Presentation
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

extension Error {
    /// 네트워크(API) 통신이 원인이 되어 발생한 에러인지 여부
    ///
    /// Presentation은 Data를 참조하지 않으므로, Data의 `NetworkError`가 채택한
    /// Domain의 `NetworkOriginatedError` 마커 프로토콜을 통해 간접적으로 판별한다
    var isNetworkOriginatedError: Bool {
        (self as? NetworkOriginatedError)?.isNetworkOriginated ?? false
    }
}

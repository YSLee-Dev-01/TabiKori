//
//  URLSession+.swift
//  Data
//
//  Created by 이윤수 on 7/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

extension URLSession: URLSessionProtocol {
    func data(request: URLRequest) async throws -> (Data, URLResponse) {
        try await self.data(for: request)
    }
}

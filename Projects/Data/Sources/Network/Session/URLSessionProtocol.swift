//
//  URLSessionProtocol.swift
//  Data
//
//  Created by 이윤수 on 7/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

protocol URLSessionProtocol: Sendable {
    func data(request: URLRequest) async throws -> (Data, URLResponse)
}

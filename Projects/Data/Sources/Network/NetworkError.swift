//
//  NetworkError.swift
//  Data
//
//  Created by 이윤수 on 7/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

enum NetworkError: Error, Equatable {
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

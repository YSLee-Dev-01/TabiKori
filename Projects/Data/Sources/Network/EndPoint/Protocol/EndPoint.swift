//
//  EndPoint.swift
//  Data
//
//  Created by 이윤수 on 7/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

protocol Endpoint {
    var baseURL: String {get}
    var path: String {get}
    var queryItems: [URLQueryItem] {get}
    var method: HTTPMethod {get}
    var timeout: TimeInterval {get}
    var enableLog: Bool {get}
}

extension Endpoint {
    var queryItems: [URLQueryItem] {
        return []
    }

    var fullURL: String {
        guard var components = URLComponents(string: self.baseURL + self.path) else {
            return self.baseURL + self.path
        }
        if !self.queryItems.isEmpty {
            components.queryItems = self.queryItems
        }
        return components.url?.absoluteString ?? self.baseURL + self.path
    }

    var timeout: TimeInterval {
        return 10.0
    }

    var enableLog: Bool {
        return true
    }
}

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
    var method: HTTPMethod {get}
    var timeout: TimeInterval {get}
    var enableLog: Bool {get}
}

extension Endpoint {
    var fullURL: String {
        self.baseURL + self.path
    }
    
    var timeout: TimeInterval {
        return 10.0
    }
    
    var enableLog: Bool {
        return true
    }
}

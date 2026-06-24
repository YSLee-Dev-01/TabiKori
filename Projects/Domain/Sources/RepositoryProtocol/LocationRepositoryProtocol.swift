//
//  LocationRepositoryProtocol.swift
//  Domain
//
//  Created by 이윤수 on 6/24/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol LocationRepositoryProtocol: Sendable {
    func checkAuthorization() -> LocationAuthorizationStatus
    func requestAuthorization() async -> LocationAuthorizationStatus
}

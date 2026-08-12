//
//  DataResetUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol DataResetUseCaseProtocol: Sendable {
    func resetAll() async throws
}

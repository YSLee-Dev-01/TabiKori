//
//  TestLocationUseCase.swift
//  Domain
//
//  Created by 이윤수 on 6/24/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestLocationUseCase: LocationUseCaseProtocol {
    
    // MARK: - Method
    
    public func checkAuthorization() -> LocationAuthorizationStatus {
        return .allowed
    }
    
    public func requestAuthorization() async -> LocationAuthorizationStatus {
        return .allowed
    }
}

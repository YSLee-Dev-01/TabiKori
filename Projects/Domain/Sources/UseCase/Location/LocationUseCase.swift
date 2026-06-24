//
//  LocationUseCase.swift
//  Domain
//
//  Created by 이윤수 on 6/24/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class LocationUseCase: LocationUseCaseProtocol {
    
    // MARK: - Properties

    private let repository: LocationRepositoryProtocol

    // MARK: - Init

    public init(repository: LocationRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method
    
    public func checkAuthorization() -> LocationAuthorizationStatus {
        return self.repository.checkAuthorization()
    }
    
    public func requestAuthorization() async -> LocationAuthorizationStatus {
        return await self.repository.requestAuthorization()
    }
}

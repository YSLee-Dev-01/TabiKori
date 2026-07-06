//
//  ExchangeRateRepository.swift
//  Data
//
//  Created by 이윤수 on 7/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

public final class ExchangeRateRepository {

    // MARK: - Properties

    private let networkService: NetworkServiceProtocol

    // MARK: - Init

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // MARK: - Method
    
    
}

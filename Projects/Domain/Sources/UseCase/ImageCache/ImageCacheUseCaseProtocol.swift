//
//  ImageCacheUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 9/15/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol ImageCacheUseCaseProtocol: Sendable {
    func clearCache() async
}

//
//  TravelRegion.swift
//  Domain
//
//  Created by 이윤수 on 7/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum TravelRegion: Equatable, Sendable {
    case korea(KoreanRegion)
    case japan
    case unsupported
    
    public var isKorea: Bool {
        guard case .korea = self else { return false }
        return true
    }
}

//
//  Alignment+.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

public extension Alignment {
    var textAlignment: TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
}

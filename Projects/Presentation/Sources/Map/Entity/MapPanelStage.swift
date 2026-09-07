//
//  MapPanelStage.swift
//  Presentation
//
//  Created by 이윤수 on 7/26/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum MapPanelStage: Equatable {
    case full
    case half
    case collapsed
}

// MARK: - Layout

extension MapPanelStage {
    var widthFraction: CGFloat {
        switch self {
        case .full: return 1.0
        case .half: return 0.95
        case .collapsed: return 0.918
        }
    }
}

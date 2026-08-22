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
        case .collapsed: return 0.9
        }
    }

    /// 탭바 높이 대비 하단 여백 비율. 0 = 여백 없이 화면 하단까지 채움, 1 = 탭바 높이만큼 여백
    var bottomInsetFraction: CGFloat {
        switch self {
        case .full: return 1.0
        case .half: return 0.5
        case .collapsed: return 0
        }
    }
}

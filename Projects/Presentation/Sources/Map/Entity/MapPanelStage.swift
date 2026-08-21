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

    /// 하단 세이프에어리어 인셋(탭바 높이) 대비 여백 비율.
    /// 0 = 여백 없이 화면 하단까지 채움, 1 = 세이프에어리어(탭바 상단)에 정확히 맞닿음
    var bottomInsetFraction: CGFloat {
        switch self {
        case .full: return 0
        case .half: return 0.5
        case .collapsed: return 1.0
        }
    }
}

//
//  TypographyStyle.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum TypographyStyle {
    case titleL
    case titleM
    case titleS

    case bodyLBold
    case bodyL
    case bodyMBold
    case bodyM
    case bodySBold
    case bodyS

    case captionMBold
    case captionM
    case captionS

    public var size: CGFloat {
        switch self {
        case .titleL: return 24
        case .titleM: return 20
        case .titleS: return 18
        case .bodyLBold, .bodyL: return 18
        case .bodyMBold, .bodyM: return 16
        case .bodySBold, .bodyS: return 14
        case .captionMBold, .captionM: return 13
        case .captionS: return 12
        }
    }

    public var weight: PretendardWeight {
        switch self {
        case .titleL: return .bold
        case .titleM, .titleS: return .semiBold
        case .bodyLBold, .bodyMBold, .bodySBold: return .bold
        case .bodyL, .bodyM, .bodyS: return .regular
        case .captionMBold: return .semiBold
        case .captionM, .captionS: return .regular
        }
    }
}

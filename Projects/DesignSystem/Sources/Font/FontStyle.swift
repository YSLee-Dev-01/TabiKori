//
//  FontStyle.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/10/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

public enum PretendardWeight {
    case thin
    case extraLight
    case light
    case regular
    case medium
    case semiBold
    case bold
    case extraBold
    case black

    var fontWeight: Font.Weight {
        switch self {
        case .thin: return .ultraLight
        case .extraLight: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semiBold: return .semibold
        case .bold: return .bold
        case .extraBold:  return .heavy
        case .black: return .black
        }
    }
}

public extension Font {
    static func pretendard(_ weight: PretendardWeight = .regular, size: CGFloat) -> Font {
        .custom("PretendardJPVariable-Regular", size: size).weight(weight.fontWeight)
    }
}

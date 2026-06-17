//
//  FontStyle.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/10/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import Resource

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

    var resourceFont: ResourceFontConvertible {
        switch self {
        case .thin: return ResourceFontFamily.PretendardJPVariable.thin
        case .extraLight: return ResourceFontFamily.PretendardJPVariable.extraLight
        case .light: return ResourceFontFamily.PretendardJPVariable.light
        case .regular: return ResourceFontFamily.PretendardJPVariable.regular
        case .medium: return ResourceFontFamily.PretendardJPVariable.medium
        case .semiBold: return ResourceFontFamily.PretendardJPVariable.semiBold
        case .bold: return ResourceFontFamily.PretendardJPVariable.bold
        case .extraBold: return ResourceFontFamily.PretendardJPVariable.extraBold
        case .black: return ResourceFontFamily.PretendardJPVariable.black
        }
    }
}

public extension Font {
    static func pretendard(_ weight: PretendardWeight = .regular, size: CGFloat) -> Font {
        weight.resourceFont.swiftUIFont(size: size)
    }
}

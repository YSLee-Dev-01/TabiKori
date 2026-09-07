//
//  WidgetStyle.swift
//  Widget
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Resource

/// 위젯 익스텐션은 NMapsMap/Kingfisher에 의존하는 DesignSystem을 링크하지 않으므로,
/// `Font.pretendard`(DesignSystem) 대신 `ResourceFontFamily`를 직접 호출한다
enum WidgetFont {
    static func pretendard(_ weight: WidgetFontWeight = .regular, size: CGFloat) -> Font {
        weight.resourceFont.swiftUIFont(size: size)
    }
}

enum WidgetFontWeight {
    case regular
    case semiBold
    case bold

    var resourceFont: ResourceFontConvertible {
        switch self {
        case .regular: return ResourceFontFamily.PretendardJPVariable.regular
        case .semiBold: return ResourceFontFamily.PretendardJPVariable.semiBold
        case .bold: return ResourceFontFamily.PretendardJPVariable.bold
        }
    }
}

enum WidgetStyle {
    static let contentSpacing: CGFloat = 6
    static let contentPadding: CGFloat = 4
}

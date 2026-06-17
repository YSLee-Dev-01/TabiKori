//
//  TabiColor.swift
//  Resource
//
//  Created by 이윤수 on 6/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

public enum TabiColor: String {

    // MARK: - Brand

    case tabiPrimary
    case tabiPrimaryLight
    case tabiPrimaryDark
    case tabiSecondary

    // MARK: - Accent

    case tabiAccentCoral
    case tabiAccentMint
    case tabiAccentLavender
    case tabiAccentAmber

    // MARK: - Background

    case tabiBackground
    case tabiSurface
    case tabiSurfaceElevated
    case tabiBorder

    // MARK: - Text

    case tabiTextPrimary
    case tabiTextSecondary
    case tabiTextTertiary

    // MARK: - Semantic

    case tabiDestructive
    case tabiOnColor

    // MARK: - Category

    case categorySightseeing
    case categoryFood
    case categoryHotel
    case categoryFestival
    case categoryShopping
    case categoryNature
}

// MARK: - ShapeStyle

extension TabiColor: ShapeStyle {
    public func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        Color(self.rawValue, bundle: .module).resolve(in: environment)
    }
}

// MARK: - Extension

extension Color {
    public static func getTabiColor(_ tabiColor: TabiColor) -> Color {
        return Color(tabiColor.rawValue, bundle: .module)
    }
}

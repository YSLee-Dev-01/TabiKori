//
//  TabiColor.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

public extension Color {
    // MARK: - Brand
    
    static let tabiPrimary = Color(red: 0.769, green: 0.392, blue: 0.353) // #C4645A
    static let tabiPrimaryLight = Color(red: 0.910, green: 0.690, blue: 0.659) // #E8B0A8
    static let tabiPrimaryDark = Color(red: 0.627, green: 0.282, blue: 0.282) // #A04848
    static let tabiSecondary = Color(red: 0.478, green: 0.686, blue: 0.753) // #7AAFC0

    // MARK: - Accent
    
    static let tabiAccentCoral = Color(red: 0.941, green: 0.784, blue: 0.753) // #F0C8C0
    static let tabiAccentMint = Color(red: 0.431, green: 0.722, blue: 0.600) // #6EB899
    static let tabiAccentLavender = Color(red: 0.608, green: 0.518, blue: 0.784) // #9B84C8
    static let tabiAccentAmber = Color(red: 0.910, green: 0.627, blue: 0.376) // #E8A060 (별점)

    // MARK: - Background
    
    static let tabiBackground = Color(red: 0.980, green: 0.965, blue: 0.941) // #FAF6F0
    static let tabiSurface = Color(red: 0.992, green: 0.988, blue: 0.980) // #FDFCFA
    static let tabiSurfaceElevated = Color(red: 0.941, green: 0.922, blue: 0.894) // #F0EBE4
    static let tabiBorder = Color(red: 0.898, green: 0.875, blue: 0.855) // #E5DFDA

    // MARK: - Text
    
    static let tabiTextPrimary = Color(red: 0.239, green: 0.173, blue: 0.125) // #3D2C20
    static let tabiTextSecondary = Color(red: 0.490, green: 0.431, blue: 0.392) // #7D6E64
    static let tabiTextTertiary = Color(red: 0.651, green: 0.600, blue: 0.565) // #A69990

    // MARK: - Semantic
    
    static let tabiDestructive = Color(red: 0.831, green: 0.094, blue: 0.239) // #D4183D
    static let tabiOnColor = Color.white
}

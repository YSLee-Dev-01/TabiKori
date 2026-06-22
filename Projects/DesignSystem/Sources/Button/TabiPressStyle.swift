//
//  TabiPressStyle.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/22/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

public struct TabiPressStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(
                configuration.isPressed ? .none : .spring(response: 0.4, dampingFraction: 0.6),
                value: configuration.isPressed
            )
    }
}

extension ButtonStyle where Self == TabiPressStyle {
    public static var tabiPress: TabiPressStyle { TabiPressStyle() }
}

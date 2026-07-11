//
//  TabiStaggeredAppear.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/5/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

private struct StaggeredAppearModifier: ViewModifier {

    let index: Int

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(self.isVisible ? 1 : 0)
            .offset(y: self.isVisible ? 0 : 16)
            .onAppear {
                withAnimation(.tabiSpring.delay(Double(self.index) * 0.06)) {
                    self.isVisible = true
                }
            }
    }
}

public extension View {
    func staggeredAppear(index: Int) -> some View {
        self.modifier(StaggeredAppearModifier(index: index))
    }
}

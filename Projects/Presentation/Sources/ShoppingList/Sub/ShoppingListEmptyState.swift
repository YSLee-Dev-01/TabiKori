//
//  ShoppingListEmptyState.swift
//  Presentation
//
//  Created by 이윤수 on 8/22/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct ShoppingListEmptyState: View {

    var body: some View {
        TabiEmptyState(
            systemImageName: "bag",
            title: Strings.Shopping.emptyTitle,
            description: Strings.Shopping.emptyDescription,
            style: .card
        )
    }
}

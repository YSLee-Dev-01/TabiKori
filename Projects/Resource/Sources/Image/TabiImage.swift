//
//  TabiImage.swift
//  Resource
//
//  Created by 이윤수 on 6/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

public enum TabiImage: String {

    // MARK: - Category

    case star = "star"
}

// MARK: - Extension

extension Image {
    public init(_ tabiImage: TabiImage) {
        self.init(tabiImage.rawValue, bundle: .module)
    }
}

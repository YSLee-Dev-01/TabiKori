//
//  WidgetSnapshotStoreDependencyKey.swift
//  App
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Domain

import ComposableArchitecture

extension WidgetSnapshotStoreDependencyKey: @retroactive DependencyKey {
    public static let liveValue: WidgetSnapshotStoreProtocol = WidgetSnapshotStore()
}

//
//  WidgetSnapshotStoreDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum WidgetSnapshotStoreDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: WidgetSnapshotStoreProtocol {
        TestWidgetSnapshotStore()
    }
}

//
//  ToastCenterDependencyKey.swift
//  Domain
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum ToastCenterDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: ToastCenterProtocol {
        TestToastCenter()
    }
}

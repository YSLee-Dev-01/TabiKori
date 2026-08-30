//
//  AppGroup.swift
//  Core
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// 이 값을 변경하면 Tuist 매니페스트의 `Environment.appGroupIdentifier`(빌드 타임, 별도 컴파일 컨텍스트라 공유 불가)도 함께 변경해야 한다
public enum AppGroup {
    public static let identifier = "group.com.yslee.tabikori"
}

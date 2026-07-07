//
//  String+.swift
//  Core
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public extension String {
    func toDouble() -> Double? {
        return Double(self.replacingOccurrences(of: ",", with: ""))
    }
}

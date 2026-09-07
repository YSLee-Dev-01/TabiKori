//
//  Festival+.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

extension Festival {
    var periodTitle: String {
        guard let endDate else {
            return "\(self.startDate.festivalPeriodDateTitle) 〜"
        }
        return "\(self.startDate.festivalPeriodDateTitle) 〜 \(endDate.festivalPeriodDateTitle)"
    }
}

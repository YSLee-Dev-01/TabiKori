//
//  CharacterSet+.swift
//  Data
//
//  Created by 이윤수 on 7/9/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

extension CharacterSet {
    /// `+`가 서버에서 공백으로 오인되지 않도록 `urlQueryAllowed`에서 `+`, `&`, `=`를 제외한 쿼리 값 인코딩용 CharacterSet
    static let urlQueryValueAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=")
        return allowed
    }()
}

import Foundation

import Resource

extension Date {
    var homeDateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: self)
    }

    var exchangeRateUpdatedAtTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 HH:mm"
        return Strings.Home.exchangeRateUpdatedAtTitle(formatter.string(from: self))
    }

    var recentSearchDateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        let isThisYear = Calendar.current.component(.year, from: self) == Calendar.current.component(.year, from: Date())
        formatter.dateFormat = isThisYear ? "MM.dd (HH:mm)" : "yyyy.MM.dd (HH:mm)"
        return formatter.string(from: self)
    }

    var planPeriodDateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: self)
    }
}

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
}

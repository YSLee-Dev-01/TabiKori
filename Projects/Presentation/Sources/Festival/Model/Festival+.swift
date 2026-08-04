import Foundation

import Domain

extension Festival {
    var periodTitle: String {
        guard let endDate else {
            return "\(self.startDate.festivalPeriodDateTitle) ~"
        }
        return "\(self.startDate.festivalPeriodDateTitle) ~ \(endDate.festivalPeriodDateTitle)"
    }
}

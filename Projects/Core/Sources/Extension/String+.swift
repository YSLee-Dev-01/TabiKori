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

    var removingHangul: String {
        let hangulPattern = "[\\uAC00-\\uD7A3\\u1100-\\u11FF\\u3130-\\u318F]"
        guard let hangulRegex = try? NSRegularExpression(pattern: hangulPattern) else { return self }
        let hangulRange = NSRange(self.startIndex..., in: self)
        let withoutHangul = hangulRegex.stringByReplacingMatches(in: self, range: hangulRange, withTemplate: "")

        let emptyParenPattern = "\\(\\s*\\)|（\\s*）"
        guard let parenRegex = try? NSRegularExpression(pattern: emptyParenPattern) else {
            return withoutHangul.trimmingCharacters(in: .whitespaces)
        }
        let parenRange = NSRange(withoutHangul.startIndex..., in: withoutHangul)
        let withoutEmptyParens = parenRegex.stringByReplacingMatches(in: withoutHangul, range: parenRange, withTemplate: "")

        return withoutEmptyParens.trimmingCharacters(in: .whitespaces)
    }

    var replacingBRWithNewline: String {
        let brPattern = "<br\\s*/?>"
        guard let brRegex = try? NSRegularExpression(pattern: brPattern, options: .caseInsensitive) else { return self }
        let brRange = NSRange(self.startIndex..., in: self)
        return brRegex.stringByReplacingMatches(in: self, range: brRange, withTemplate: "\n")
    }

    var removingBracketedTags: String {
        let bracketPattern = "\\[[^\\]]*\\]"
        guard let bracketRegex = try? NSRegularExpression(pattern: bracketPattern) else { return self }
        let bracketRange = NSRange(self.startIndex..., in: self)
        let withoutBrackets = bracketRegex.stringByReplacingMatches(in: self, range: bracketRange, withTemplate: "")
        return withoutBrackets.trimmingCharacters(in: .whitespaces)
    }

    func truncated(to length: Int, trailing: String = "…") -> String {
        guard self.count > length else { return self }
        return String(self.prefix(length)) + trailing
    }
}

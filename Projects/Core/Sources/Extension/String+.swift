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

    /// 히라가나(぀-ゟ)·가타카나(゠-ヿ)·가타카나 음성 확장(ㇰ-ㇿ)·한자(CJK 통합 한자, 一-鿿) 범위 문자를 포함하는지 판별
    var containsJapanese: Bool {
        let japanesePattern = "[\\u3040-\\u309F\\u30A0-\\u30FF\\u31F0-\\u31FF\\u4E00-\\u9FFF]"
        guard let japaneseRegex = try? NSRegularExpression(pattern: japanesePattern) else { return false }
        let range = NSRange(self.startIndex..., in: self)
        return japaneseRegex.firstMatch(in: self, range: range) != nil
    }

    /// http 스킴 URL 문자열을 https로 승격해 URL로 변환한다. ATS(App Transport Security) 정책 때문에
    /// http로는 로드되지 않는 외부 API의 이미지 URL(예: 한국관광공사 API)을 안전하게 사용하기 위함
    var secureURL: URL? {
        guard self.hasPrefix("http://") else {
            return URL(string: self)
        }
        return URL(string: "https://" + self.dropFirst("http://".count))
    }

    /// semantic 버전 문자열을 세그먼트(".") 단위 숫자로 비교해 self가 other보다 낮은 버전인지 판별
    /// (문자열 사전식 비교와 달리 "1.10.0"이 "1.9.0"보다 높은 버전으로 올바르게 비교됨)
    func isVersionLower(than other: String) -> Bool {
        let selfComponents = self.split(separator: ".").map { Int($0) ?? 0 }
        let otherComponents = other.split(separator: ".").map { Int($0) ?? 0 }
        let maxCount = max(selfComponents.count, otherComponents.count)

        for index in 0..<maxCount {
            let selfValue = index < selfComponents.count ? selfComponents[index] : 0
            let otherValue = index < otherComponents.count ? otherComponents[index] : 0
            if selfValue != otherValue {
                return selfValue < otherValue
            }
        }
        return false
    }
}

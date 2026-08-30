//
//  WidgetDeepLink.swift
//  Domain
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum WidgetKind {
    public static let plan = "TabiPlanWidget"
    public static let phrase = "TabiPhraseWidget"
}

public enum WidgetDeepLink: Equatable, Sendable {
    case planDetail(UUID)
    case koreanPhraseList

    private enum Constant {
        static let scheme = "tabikori"
        static let planHost = "plan"
        static let koreanPhraseHost = "koreanPhrase"
    }

    public var url: URL? {
        var components = URLComponents()
        components.scheme = Constant.scheme

        switch self {
        case .planDetail(let id):
            components.host = Constant.planHost
            components.path = "/\(id.uuidString)"

        case .koreanPhraseList:
            components.host = Constant.koreanPhraseHost
        }

        return components.url
    }

    public init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == Constant.scheme else { return nil }

        switch components.host {
        case Constant.planHost:
            let idString = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard let id = UUID(uuidString: idString) else { return nil }
            self = .planDetail(id)

        case Constant.koreanPhraseHost:
            self = .koreanPhraseList

        default:
            return nil
        }
    }
}

//
//  TestWidgetSnapshotStore.swift
//  Domain
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestWidgetSnapshotStore: WidgetSnapshotStoreProtocol, @unchecked Sendable {
    public var planSnapshot: PlanWidgetSnapshot?
    public var phraseSnapshot: PhraseWidgetSnapshot?

    public init() {}

    public func loadPlanSnapshot() -> PlanWidgetSnapshot? {
        return self.planSnapshot
    }

    public func loadPhraseSnapshot() -> PhraseWidgetSnapshot? {
        return self.phraseSnapshot
    }

    public func savePlanSnapshot(_ snapshot: PlanWidgetSnapshot) {
        self.planSnapshot = snapshot
    }

    public func savePhraseSnapshot(_ snapshot: PhraseWidgetSnapshot) {
        self.phraseSnapshot = snapshot
    }
}

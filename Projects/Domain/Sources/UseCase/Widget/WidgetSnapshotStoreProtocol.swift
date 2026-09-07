//
//  WidgetSnapshotStoreProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol WidgetSnapshotStoreProtocol: Sendable {
    func loadPlanSnapshot() -> PlanWidgetSnapshot?
    func loadPhraseSnapshot() -> PhraseWidgetSnapshot?
    func savePlanSnapshot(_ snapshot: PlanWidgetSnapshot)
    func savePhraseSnapshot(_ snapshot: PhraseWidgetSnapshot)
}

//
//  PlanTimelineProvider.swift
//  Widget
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import WidgetKit

import Domain

struct PlanTimelineProvider: TimelineProvider {
    private let store: WidgetSnapshotStoreProtocol

    init(store: WidgetSnapshotStoreProtocol = WidgetSnapshotStore()) {
        self.store = store
    }

    func placeholder(in context: Context) -> PlanWidgetEntry {
        return PlanWidgetEntry(date: Date(), item: Self.previewItem)
    }

    func getSnapshot(in context: Context, completion: @escaping (PlanWidgetEntry) -> Void) {
        if context.isPreview {
            completion(PlanWidgetEntry(date: Date(), item: Self.previewItem))
            return
        }
        let now = Date()
        let snapshot = self.store.loadPlanSnapshot()
        completion(PlanWidgetEntry(date: now, item: snapshot?.plan(on: now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlanWidgetEntry>) -> Void) {
        let now = Date()
        guard let snapshot = self.store.loadPlanSnapshot() else {
            let nextMidnight = Self.midnight(daysAfter: 1, from: now)
            completion(Timeline(entries: [PlanWidgetEntry(date: now, item: nil)], policy: .after(nextMidnight)))
            return
        }

        var entryDates = [now]
        for dayOffset in 1...7 {
            entryDates.append(Self.midnight(daysAfter: dayOffset, from: now))
        }

        let entries = entryDates.map { PlanWidgetEntry(date: $0, item: snapshot.plan(on: $0)) }
        let reloadDate = entryDates.last ?? now
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }
}

// MARK: - Method

private extension PlanTimelineProvider {
    static var previewItem: PlanWidgetSnapshotItem {
        let now = Date()
        return PlanWidgetSnapshotItem(
            id: UUID(),
            title: "ソウル旅行",
            emoji: "🗼",
            regionTitle: "ソウル",
            startDate: now,
            endDate: Calendar.current.date(byAdding: .day, value: 2, to: now) ?? now
        )
    }

    static func midnight(daysAfter dayOffset: Int, from date: Date) -> Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) ?? date
    }
}

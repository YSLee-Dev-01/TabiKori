//
//  PhraseTimelineProvider.swift
//  Widget
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import WidgetKit

import Domain

struct PhraseTimelineProvider: TimelineProvider {
    private static let rotationInterval: TimeInterval = 30 * 60
    private static let entryCount = 48

    private let store: WidgetSnapshotStoreProtocol

    init(store: WidgetSnapshotStoreProtocol = WidgetSnapshotStore()) {
        self.store = store
    }

    func placeholder(in context: Context) -> PhraseWidgetEntry {
        return PhraseWidgetEntry(date: Date(), phrase: Self.previewPhrase)
    }

    func getSnapshot(in context: Context, completion: @escaping (PhraseWidgetEntry) -> Void) {
        if context.isPreview {
            completion(PhraseWidgetEntry(date: Date(), phrase: Self.previewPhrase))
            return
        }
        let now = Date()
        let snapshot = self.store.loadPhraseSnapshot()
        completion(PhraseWidgetEntry(date: now, phrase: snapshot.flatMap { self.phrase(from: $0, at: now) }))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PhraseWidgetEntry>) -> Void) {
        let now = Date()
        guard let snapshot = self.store.loadPhraseSnapshot(), !snapshot.phrases.isEmpty else {
            completion(Timeline(entries: [PhraseWidgetEntry(date: now, phrase: nil)], policy: .atEnd))
            return
        }

        let entries = (0..<Self.entryCount).map { offset -> PhraseWidgetEntry in
            let entryDate = now.addingTimeInterval(Self.rotationInterval * Double(offset))
            return PhraseWidgetEntry(date: entryDate, phrase: self.phrase(from: snapshot, at: entryDate))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Method

private extension PhraseTimelineProvider {
    static var previewPhrase: PhraseWidgetSnapshotItem {
        PhraseWidgetSnapshotItem(id: "preview", korean: "안녕하세요", japanese: "こんにちは", pronunciation: "アンニョンハセヨ")
    }

    func phrase(from snapshot: PhraseWidgetSnapshot, at date: Date) -> PhraseWidgetSnapshotItem? {
        let bucketIndex = Int(date.timeIntervalSince1970 / Self.rotationInterval)
        return snapshot.phrase(at: bucketIndex)
    }
}

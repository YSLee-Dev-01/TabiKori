//
//  WidgetSnapshotStore.swift
//  Domain
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import WidgetKit

import Core

/// 위젯 익스텐션은 Firebase(RTDB)/SwiftData를 직접 링크하지 않아야 하므로(스펙 불변 조건),
/// 실제 구현체를 Data가 아닌 Domain에 둔다. UserDefaults(App Group) + JSON만 사용하는 순수 Foundation 코드다.
public final class WidgetSnapshotStore: @unchecked Sendable {

    private enum Key {
        static let plan = "widget.snapshot.plan"
        static let phrase = "widget.snapshot.phrase"
    }

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init() {
        self.userDefaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }
}

// MARK: - WidgetSnapshotStoreProtocol

extension WidgetSnapshotStore: WidgetSnapshotStoreProtocol {
    public func loadPlanSnapshot() -> PlanWidgetSnapshot? {
        return self.load(PlanWidgetSnapshot.self, forKey: Key.plan)
    }

    public func loadPhraseSnapshot() -> PhraseWidgetSnapshot? {
        return self.load(PhraseWidgetSnapshot.self, forKey: Key.phrase)
    }

    public func savePlanSnapshot(_ snapshot: PlanWidgetSnapshot) {
        guard self.save(snapshot, forKey: Key.plan) else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.plan)
    }

    public func savePhraseSnapshot(_ snapshot: PhraseWidgetSnapshot) {
        guard self.save(snapshot, forKey: Key.phrase) else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.phrase)
    }
}

// MARK: - Method

private extension WidgetSnapshotStore {
    func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = self.userDefaults.data(forKey: key) else { return nil }
        do {
            return try self.decoder.decode(type, from: data)
        } catch {
            AppLogger.core.log(.error, "위젯 스냅샷 디코딩 실패(\(key)): \(error)")
            return nil
        }
    }

    /// 저장 성공 + 값이 실제로 바뀐 경우에만 true를 반환한다 (변경 없으면 write/reload 모두 생략)
    func save<T: Encodable & Equatable & Decodable>(_ snapshot: T, forKey key: String) -> Bool {
        let newData: Data
        do {
            newData = try self.encoder.encode(snapshot)
        } catch {
            AppLogger.core.log(.error, "위젯 스냅샷 인코딩 실패(\(key)): \(error)")
            return false
        }

        if let existingData = self.userDefaults.data(forKey: key), existingData == newData {
            return false
        }

        self.userDefaults.set(newData, forKey: key)
        return true
    }
}

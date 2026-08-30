//
//  WidgetSnapshotSync.swift
//  Presentation
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// `displayEmoji`/`displayRegionTitle`(`TravelPlan+.swift`)가 Presentation 전용 확장이라
/// 표시 문자열을 이 시점(Presentation)에서 확정해 스냅샷에 담는다
enum WidgetSnapshotSync {
    private static let maxPlanCount = 20
    private static let maxPhraseCount = 30

    static func planSnapshot(from plans: [TravelPlan], now: Date = Date()) -> PlanWidgetSnapshot {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        let items = plans
            .filter { calendar.startOfDay(for: $0.endDate) >= today }
            .sorted { $0.startDate < $1.startDate }
            .prefix(self.maxPlanCount)
            .map {
                PlanWidgetSnapshotItem(
                    id: $0.id,
                    title: $0.title,
                    emoji: $0.displayEmoji,
                    regionTitle: $0.displayRegionTitle,
                    startDate: $0.startDate,
                    endDate: $0.endDate
                )
            }

        return PlanWidgetSnapshot(updatedAt: now, plans: Array(items))
    }

    static func phraseSnapshot(from phrases: [KoreanPhrase], now: Date = Date()) -> PhraseWidgetSnapshot {
        let items = phrases
            .sorted { $0.order < $1.order }
            .prefix(self.maxPhraseCount)
            .map {
                PhraseWidgetSnapshotItem(id: $0.id, korean: $0.korean, japanese: $0.japanese, pronunciation: $0.pronunciation)
            }

        return PhraseWidgetSnapshot(updatedAt: now, phrases: Array(items))
    }

    /// 이미 메모리에 있는 `plans`로 위젯 스냅샷만 갱신한다 (PlanFeature 등 데이터를 이미 들고 있는 화면용)
    static func syncPlanSnapshotEffect<Action>(
        plans: [TravelPlan],
        widgetSnapshotStore: WidgetSnapshotStoreProtocol
    ) -> Effect<Action> {
        return .run { _ in
            widgetSnapshotStore.savePlanSnapshot(self.planSnapshot(from: plans))
        }
    }

    /// 앱 실행 시점처럼 플랜/문구를 직접 조회해서 위젯 스냅샷을 갱신한다. 실패는 로깅 후 무시(기존 스냅샷 유지)
    static func syncAllSnapshotsEffect<Action>(
        travelPlanUseCase: TravelPlanUseCaseProtocol,
        koreanPhraseUseCase: KoreanPhraseUseCaseProtocol,
        widgetSnapshotStore: WidgetSnapshotStoreProtocol
    ) -> Effect<Action> {
        return .run { _ in
            do {
                let plans = try await travelPlanUseCase.fetch()
                widgetSnapshotStore.savePlanSnapshot(self.planSnapshot(from: plans))
            } catch {
                AppLogger.view.log(.error, "위젯 플랜 스냅샷 동기화 실패: \(error)")
            }

            do {
                let phrases = try await koreanPhraseUseCase.fetchPhrases()
                widgetSnapshotStore.savePhraseSnapshot(self.phraseSnapshot(from: phrases))
            } catch {
                AppLogger.view.log(.error, "위젯 문구 스냅샷 동기화 실패: \(error)")
            }
        }
    }
}

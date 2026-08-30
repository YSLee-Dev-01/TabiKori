# Tasks: widget

## 참조
- spec: `.claude/specs/features/widget/spec.md`
- plan: `.claude/specs/features/widget/plan.md`

> Tuist 타겟/파일이 늘어나므로 각 Phase 끝에 `tuist install && tuist generate`를 실행한다 (새 `.swift` 파일 추가 후 generate 없이 빌드하면 stale 프로젝트로 오탐 에러 발생).
> 빌드 destination: `platform=iOS Simulator,name=iPhone 17` (iPhone 16 Pro 미설치).

## Task 목록

### Phase 0. App Group 선행 검증 (차단 요소)

#### [x] Task 1 — App Group / App ID 활성화 가능 여부 확인 (코드 없음)
**대상**: Apple Developer 계정 설정 (파일 변경 없음)
- Apple Developer 계정에서 App Group `group.com.yslee.tabikori`가 존재하는지, 없다면 신규 생성 가능한지 확인
- `com.yslee.tabikori`(App), `com.yslee.tabikori.Widget`(Widget) App ID에 해당 App Group capability를 활성화할 수 있는지 확인
- 자동 서명(Automatic Signing) 사용 시 Xcode가 프로비저닝 프로파일을 갱신할 수 있는지 확인
- **차단 게이트**: 여기서 막히면 이후 Phase 전부 무의미하므로, 확인 결과(가능/불가/보류)를 진행 전 사용자에게 보고하고 승인받은 뒤 Phase 1로 진행한다

---

### Phase 1. Tuist 인프라 (코드 0줄, 구조만)

#### [x] Task 2 — `Templates/Target.swift` (수정)
**파일**: `Tuist/ProjectDescriptionHelpers/Templates/Target.swift`
- `makeTarget`에 `entitlements: Entitlements? = nil` 파라미터 추가
- 추가한 파라미터를 `Target.target(...)` 호출부의 `entitlements:` 인자로 전달
- 구현 직전 Tuist 4.196.1의 `ProjectDescription` 소스에서 `Entitlements` / `Target.target` 시그니처를 재확인 (API 추측 금지)

---

#### [x] Task 3 — `Templates/Project.swift` (수정)
**파일**: `Tuist/ProjectDescriptionHelpers/Templates/Project.swift`
- `makeProject`에 `entitlements` 파라미터 추가
- 추가한 파라미터를 내부 `makeTarget` 호출로 전달 (단일 타겟 구조는 그대로 유지)

---

#### [x] Task 4 — `DependencyInformation.swift` (수정)
**파일**: `Tuist/ProjectDescriptionHelpers/Dependency/DependencyInformation.swift`
- `case widget = "Widget"` 케이스 추가
- `internalDependencyInfo`에 `.widget: [.domain, .core, .resource]` 추가
- `internalDependencyInfo[.app]`(App의 의존 목록)에 `.widget` 추가
- `externalDependencyInfo`에는 위젯 관련 항목을 추가하지 않음 (외부 라이브러리 없음)

---

#### [x] Task 5 — `Workspace.swift` (수정)
**파일**: `Workspace.swift`
- 프로젝트 목록에 `"Projects/Widget"` 추가

---

#### [x] Task 6 — `Projects/Widget/Info.plist` (신규)
**파일**: `Projects/Widget/Info.plist`
- `NSExtension` 딕셔너리 추가, `NSExtensionPointIdentifier = com.apple.widgetkit-extension` 설정
- `CFBundleDisplayName` 설정 (일본어 표시명)

---

#### [x] Task 7 — `Projects/Widget/Project.swift` (신규)
**파일**: `Projects/Widget/Project.swift`
- `makeProject(name: "Widget", product: .appExtension, hasResource: false, infoPlist: .file(...), entitlements: ...)` 형태로 구성
- entitlement 값은 가능하면 딕셔너리(`com.apple.security.application-groups` = `[group.com.yslee.tabikori]`)로 선언해 App/Widget이 동일 정의를 공유
- 딕셔너리 형태가 Tuist에서 지원되지 않으면 `Projects/App/Support/App.entitlements` + `Projects/Widget/Support/Widget.entitlements` 2개 파일 방식으로 대체 (Task 2에서 확인한 실제 API 기준으로 결정)

---

#### [x] Task 8 — `Projects/App/Project.swift` (수정)
**파일**: `Projects/App/Project.swift`
- Task 3에서 추가한 `entitlements` 파라미터를 App Group 딕셔너리(또는 `.entitlements` 파일 경로)로 전달
- 기존 인자(Crashlytics 관련 스크립트 등)는 그대로 유지, 무관한 코드 수정 금지

---

#### [x] Task 9 — `Projects/Widget/Sources/TabiWidgetBundle.swift` (신규, 임시 껍데기) + 검증
**파일**: `Projects/Widget/Sources/TabiWidgetBundle.swift`
- 최소한의 `@main WidgetBundle` 껍데기 위젯 1개만 작성 (실제 Plan/Phrase 위젯은 Phase 5에서 구현)
- `tuist install && tuist generate` 실행 후 빌드
- **검증 포인트(필수)**: 빌드 산출물에 `TabiKori.app/PlugIns/Widget.appex`가 존재하는지, 시뮬레이터 위젯 갤러리에 위젯이 노출되는지 눈으로 확인
- 실패 시 결정사항 1의 대안(App 프로젝트 내 다중 타겟 방식)으로 선회할지 사용자에게 보고 후 결정

---

### Phase 2. Core / Domain (공유 계약)

#### [x] Task 10 — `Core/Sources/Config/AppGroup.swift` (신규)
**파일**: `Projects/Core/Sources/Config/AppGroup.swift`
- `public enum AppGroup { public static let identifier = "group.com.yslee.tabikori" }` 정의
- 이 파일이 `group.com.yslee.tabikori` 문자열의 유일한 정의 위치가 되도록 함

---

#### [x] Task 11 — `Data/Sources/UserDefault/TabiUserDefault.swift` (수정)
**파일**: `Projects/Data/Sources/UserDefault/TabiUserDefault.swift`
- 하드코딩된 `"group.com.yslee.tabikori"` 문자열을 `AppGroup.identifier` 참조로 교체
- 그 외 기존 동작/로직은 변경하지 않음

---

#### [x] Task 12 — `Domain/Sources/Entity/PlanWidgetSnapshot.swift` (신규)
**파일**: `Projects/Domain/Sources/Entity/PlanWidgetSnapshot.swift`
- `PlanWidgetSnapshot { updatedAt: Date; plans: [PlanWidgetSnapshotItem] }` 정의, `Codable, Equatable, Sendable` 채택
- `PlanWidgetSnapshotItem { id: UUID; title: String; emoji: String; regionTitle: String; startDate: Date; endDate: Date }` 정의 (표시 문자열은 기록 시점에 이미 확정된 상태로 들어옴 — Presentation에서 채움)
- `func plan(on date: Date) -> PlanWidgetSnapshotItem?` 구현: `startDate...endDate`에 date가 포함된 일정 중 `startDate` 오름차순 첫 번째 → 없으면 `startDate > date`인 미래 일정 중 `startDate` 오름차순 첫 번째 → 없으면 `nil`
- `PlanWidgetSnapshotItem`에 `dayCount`, `dayIndex(on:)`, `daysUntilStart(on:)` 계산 프로퍼티/메서드 추가 (모두 `Calendar.startOfDay` 기준)

---

#### [x] Task 13 — `Domain/Sources/Entity/PhraseWidgetSnapshot.swift` (신규)
**파일**: `Projects/Domain/Sources/Entity/PhraseWidgetSnapshot.swift`
- `PhraseWidgetSnapshot { updatedAt: Date; phrases: [PhraseWidgetSnapshotItem] }` 정의, `Codable, Equatable, Sendable` 채택
- `PhraseWidgetSnapshotItem { id, korean, japanese, pronunciation }` 정의
- `func phrase(at index: Int) -> PhraseWidgetSnapshotItem?` 구현: 모듈러 인덱싱, `phrases`가 빈 배열이면 `nil`

---

#### [x] Task 14 — `Domain/Sources/Entity/WidgetDeepLink.swift` (신규)
**파일**: `Projects/Domain/Sources/Entity/WidgetDeepLink.swift`
- `public enum WidgetDeepLink: Equatable, Sendable { case planDetail(UUID); case koreanPhraseList }` 정의
- `var url: URL?` 계산 프로퍼티 구현 — 스킴 `tabikori`, `tabikori://plan/{uuid}`, `tabikori://koreanPhrase` 생성
- `public init?(url: URL)` 구현 — 위 두 형식을 파싱, 그 외는 `nil`
- 스킴/호스트 상수는 같은 파일 내 `private enum`으로 정의
- 위젯 `kind` 상수(`WidgetKind.plan`, `WidgetKind.phrase`)도 이 파일 또는 인접 파일에 정의

---

#### [x] Task 15 — `Domain/Sources/UseCase/Widget/WidgetSnapshotStoreProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/Widget/WidgetSnapshotStoreProtocol.swift`
- `Sendable` 채택 프로토콜 정의
- `func loadPlanSnapshot() -> PlanWidgetSnapshot?`
- `func loadPhraseSnapshot() -> PhraseWidgetSnapshot?`
- `func savePlanSnapshot(_ snapshot: PlanWidgetSnapshot)`
- `func savePhraseSnapshot(_ snapshot: PhraseWidgetSnapshot)`
- read는 `throws` 없이 옵셔널 반환으로 설계 (실패는 전부 빈 상태로 흡수)

---

#### [x] Task 16 — `Domain/Sources/UseCase/Widget/WidgetSnapshotStore.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/Widget/WidgetSnapshotStore.swift`
- `public final class WidgetSnapshotStore: @unchecked Sendable` 정의, `UserDefaults(suiteName: AppGroup.identifier)` 사용
- `JSONEncoder`/`JSONDecoder`에 `dateEncodingStrategy = .iso8601` / `dateDecodingStrategy = .iso8601` 고정 (앱/익스텐션 간 포맷 통일)
- `// MARK: - WidgetSnapshotStoreProtocol` extension으로 프로토콜 채택부 분리
- 디코딩 실패 시 `AppLogger.core.log(.error, ...)` 후 `nil` 반환, `try!`/강제 언래핑 금지 (`guard let` + `??`)
- 저장 시 인코딩 결과가 이전 저장값과 동일하면 write/reload 모두 하지 않음 (no-op)
- 저장 성공 + 값이 실제로 변경된 경우에만 `WidgetCenter.shared.reloadTimelines(ofKind:)`를 해당 kind(plan 또는 phrase)에 한해 호출
- 파일 상단 주석에 "Data가 아닌 Domain에 두는 이유"(위젯이 Firebase/SwiftData를 직접 링크하지 않기 위한 의도적 예외) 명시

---

#### [x] Task 17 — `Domain/Sources/UseCase/Widget/TestWidgetSnapshotStore.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/Widget/TestWidgetSnapshotStore.swift`
- `Test` 접두사 + `WidgetSnapshotStoreProtocol` 채택 인메모리 더블
- 주입용 `var` 프로퍼티(예: `planSnapshot`, `phraseSnapshot`) 공개, `@unchecked Sendable`

---

#### [x] Task 18 — `Domain/Sources/Dependency/Keys/WidgetSnapshotStoreDependencyKey.swift` (신규)
**파일**: `Projects/Domain/Sources/Dependency/Keys/WidgetSnapshotStoreDependencyKey.swift`
- `TestDependencyKey` 채택, `testValue`에 `TestWidgetSnapshotStore()` 반환

---

#### [x] Task 19 — `Domain/Sources/Dependency/DependencyValues.swift` (수정)
**파일**: `Projects/Domain/Sources/Dependency/DependencyValues.swift`
- `widgetSnapshotStore` 프로퍼티 확장 추가 (기존 항목과 동일한 패턴)

---

#### [x] Task 20 — Phase 2 마무리 검증
**대상**: 빌드/생성 검증 (파일 변경 없음)
- `tuist generate` 실행 후 Domain/Core 모듈이 정상 빌드되는지 확인

---

### Phase 3. App (DI 조립 + URL 스킴)

#### [x] Task 21 — `App/Sources/Dependency/WidgetSnapshotStoreDependencyKey.swift` (신규)
**파일**: `Projects/App/Sources/Dependency/WidgetSnapshotStoreDependencyKey.swift`
- 같은 타입에 `@retroactive DependencyKey` extension으로 `liveValue = WidgetSnapshotStore()` 정의

---

#### [x] Task 22 — `App/Info.plist` (수정)
**파일**: `Projects/App/Info.plist`
- `CFBundleURLTypes` 배열 추가 — `CFBundleURLName` = App 번들 ID, `CFBundleURLSchemes` = `["tabikori"]`

---

### Phase 4. Resource (문자열)

#### [x] Task 23 — `Resource/Sources/Strings/Strings.swift` (수정)
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- `public enum Widget {}` 선언 + `public extension Strings.Widget` 추가
- 플랜 위젯: 갤러리 표시명, 갤러리 설명, 진행중 배지(가능하면 기존 `Strings.Plan.dayChipTitle` 재사용), 디데이 표기(`あと N日`), 오늘 시작 표기, 빈 상태 문구("予定された日程がありません")
- 문구 위젯: 갤러리 표시명, 갤러리 설명, 빈 상태 문구
- 기존 재사용 가능 항목 확인: `Strings.KoreanPhrase.listTitle`(문구 위젯 헤더), `Strings.Plan.dayChipTitle` / `.durationBadge` — 재사용 가능하면 신규 정의하지 않음
- 각 상수 위에 한국어 주석, 실제 값은 일본어로 작성 (기존 파일 컨벤션 준수)

---

### Phase 5. 위젯 타겟 구현

#### [x] Task 24 — `Widget/Sources/Style/WidgetStyle.swift` (신규)
**파일**: `Projects/Widget/Sources/Style/WidgetStyle.swift`
- `ResourceFontFamily...swiftUIFont(size:)`를 감싸는 폰트 헬퍼 정의 (DesignSystem `Font.pretendard` 사용 불가하므로 직접 호출)
- 위젯 전용 여백/스타일 상수 정의 (DesignSystem 컴포넌트 재현 금지 — 텍스트 + 배경만)

---

#### [x] Task 25 — `Widget/Sources/Plan/PlanWidgetEntry.swift` (신규)
**파일**: `Projects/Widget/Sources/Plan/PlanWidgetEntry.swift`
- `TimelineEntry` 채택, `date: Date`, `item: PlanWidgetSnapshotItem?` 보유
- 디데이/N일차 등 파생 표시값 계산 프로퍼티 추가

---

#### [x] Task 26 — `Widget/Sources/Plan/PlanTimelineProvider.swift` (신규)
**파일**: `Projects/Widget/Sources/Plan/PlanTimelineProvider.swift`
- `TimelineProvider` 채택: `placeholder`, `getSnapshot`(갤러리 프리뷰용 더미 데이터), `getTimeline` 구현
- `getTimeline`: `WidgetSnapshotStore`에서 스냅샷 로드 → "지금" + 이후 자정 경계 7개(총 8 엔트리)에 대해 `snapshot.plan(on:)` 계산 → `policy: .after(마지막 엔트리 이후 자정)`
- 스냅샷이 `nil`인 경우 빈 엔트리 1개 + `.after(다음 자정)`으로 폴백 (크래시 없이 빈 상태)

---

#### [x] Task 27 — `Widget/Sources/Plan/PlanWidgetView.swift` (신규)
**파일**: `Projects/Widget/Sources/Plan/PlanWidgetView.swift`
- Small 패밀리: 이모지 + 제목(2줄) + 디데이/N일차
- Medium 패밀리: 이모지 + 제목 + 지역명 + 기간 + 디데이/N일차
- 빈 상태: 안내 문구만 표시 (Task 23에서 정의한 Strings 사용)
- `.containerBackground(for: .widget) { ... }` 적용
- `.widgetURL(WidgetDeepLink.planDetail(id).url)` 적용, 빈 상태에서는 `widgetURL` 미지정

---

#### [x] Task 28 — `Widget/Sources/Plan/TabiPlanWidget.swift` (신규)
**파일**: `Projects/Widget/Sources/Plan/TabiPlanWidget.swift`
- `StaticConfiguration(kind: WidgetKind.plan, provider: PlanTimelineProvider())` 구성
- `configurationDisplayName`, `description`, `supportedFamilies([.systemSmall, .systemMedium])` 설정

---

#### [x] Task 29 — `Widget/Sources/Phrase/PhraseWidgetEntry.swift` (신규)
**파일**: `Projects/Widget/Sources/Phrase/PhraseWidgetEntry.swift`
- `TimelineEntry` 채택, `date: Date`, 문구 1건(`PhraseWidgetSnapshotItem?`) 보유

---

#### [x] Task 30 — `Widget/Sources/Phrase/PhraseTimelineProvider.swift` (신규)
**파일**: `Projects/Widget/Sources/Phrase/PhraseTimelineProvider.swift`
- `TimelineProvider` 채택: `placeholder`, `getSnapshot`, `getTimeline` 구현
- `getTimeline`: 스냅샷 로드 → 30분 간격 엔트리 48개(24시간분) 생성, `index = (경과분 / 30) % count`로 문구 선택, `policy: .atEnd`
- 스냅샷이 `nil`이거나 문구가 없는 경우 빈 엔트리로 폴백

---

#### [x] Task 31 — `Widget/Sources/Phrase/PhraseWidgetView.swift` (신규)
**파일**: `Projects/Widget/Sources/Phrase/PhraseWidgetView.swift`
- Small/Medium 분기: 한국어 원문 + 일본어 번역, Medium에서는 발음도 추가 표시
- 빈 상태: 안내 문구만 표시
- `.containerBackground(for: .widget) { ... }`, `.widgetURL(WidgetDeepLink.koreanPhraseList.url)` 고정 적용

---

#### [x] Task 32 — `Widget/Sources/Phrase/TabiPhraseWidget.swift` (신규)
**파일**: `Projects/Widget/Sources/Phrase/TabiPhraseWidget.swift`
- `StaticConfiguration(kind: WidgetKind.phrase, provider: PhraseTimelineProvider())` 구성
- `configurationDisplayName`, `description`, `supportedFamilies([.systemSmall, .systemMedium])` 설정

---

#### [x] Task 33 — `Widget/Sources/TabiWidgetBundle.swift` (수정 — Phase 1의 임시 껍데기 교체)
**파일**: `Projects/Widget/Sources/TabiWidgetBundle.swift`
- `@main struct TabiWidgetBundle: WidgetBundle { var body: some Widget { TabiPlanWidget(); TabiPhraseWidget() } }`로 교체

---

#### [x] Task 34 — Phase 5 마무리 검증
**대상**: 빌드/생성 검증 (파일 변경 없음)
- `tuist generate` 실행 후 위젯 타겟 빌드 확인, 시뮬레이터 위젯 갤러리에서 두 위젯의 Small/Medium 프리뷰(`getSnapshot` 더미 데이터) 정상 노출 확인

---

### Phase 6. Presentation (스냅샷 기록 + 딥링크 수신)

#### [x] Task 35 — `Presentation/Sources/Widget/WidgetSnapshotSync.swift` (신규)
**파일**: `Projects/Presentation/Sources/Widget/WidgetSnapshotSync.swift`
- `[TravelPlan]` → `PlanWidgetSnapshot` 변환 함수: 과거 종료 일정(`endDate < 오늘`) 제외, `startDate` 오름차순 정렬, 최대 20건, `displayEmoji`/`displayRegionTitle`(`TravelPlan+.swift`)로 표시 문자열 확정
- `[KoreanPhrase]` → `PhraseWidgetSnapshot` 변환 함수: `order` 오름차순 정렬, 최대 30건
- Action 제네릭 기록 Effect 헬퍼 제공 — 호출부가 `.merge`로 끼워 넣기만 하면 되는 형태로 설계

---

#### [x] Task 36 — `Presentation/Sources/Root/RootFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/Root/RootFeature.swift`
- `@Dependency(\.travelPlanUseCase)`, `@Dependency(\.koreanPhraseUseCase)`, `@Dependency(\.widgetSnapshotStore)` 추가
- Action 추가 (선언 순서 규칙 준수: 생명주기 뒤, 하위 액션 앞) — `openURLReceived(URL)`
- `.onAppear`: 기존 `.merge(onboardingEffect, subscribeToastEffect())`에 `syncWidgetSnapshotEffect()`(Task 35 헬퍼) 추가. 실패는 `AppLogger.view` 로깅 후 무시(기존 스냅샷 유지)
- `.openURLReceived(url)`: `WidgetDeepLink(url:)` 파싱 실패 또는 `tabBarState == nil`이면 `AppLogger.view` 로깅 후 `.none`, 성공 시 `.send(.tabBar(.deepLinkReceived(link)))`

---

#### [x] Task 37 — `Presentation/Sources/Root/RootView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Root/RootView.swift`
- 기존 `.onAppear` 아래에 `.onOpenURL { self.store.send(.openURLReceived($0)) }` 추가

---

#### [x] Task 38 — `Presentation/Sources/Tabbar/TabBarFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
- `case deepLinkReceived(WidgetDeepLink)` 액션 추가
- `@Dependency(\.travelPlanUseCase)` 추가, 딥링크 조회용 `CancelID` case 추가
- `.koreanPhraseList` 처리: `selectedTab = .toolbox`로 전환, 스택 최상단이 이미 `koreanPhraseList`가 아니면 append (중복 push 방지)
- `.planDetail(id)` 처리: `selectedTab = .plan` 전환 + `travelPlanUseCase.fetch()` Effect 실행 → 결과 액션 `deepLinkPlanResolved(TravelPlan?)`에서 해당 id를 찾아 `PlanDetailFeature.State(plan:initialDayIndex: plan.todayDayIndex ?? 0)` push, 찾지 못하면(삭제된 일정) 탭 전환만 유지하고 `AppLogger.view` 로깅

---

#### [x] Task 39 — `Presentation/Sources/Plan/PlanFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/Plan/PlanFeature.swift`
- `plansResult` / `planDeleted` / `editPlan(.presented(.planUpdated))` / `importResult(true)` 4개 지점에서 `state.plans` 확정 직후 스냅샷 기록 Effect(Task 35 헬퍼)를 `.merge`로 병합

---

#### [x] Task 40 — Phase 6 마무리 검증
**대상**: 빌드/생성 검증 (파일 변경 없음)
- `tuist generate` 실행 후 App/Presentation/Widget 전체 빌드 확인

---

### Phase 7. 검증

#### [x] Task 41 — 전체 빌드 검증
**대상**: 빌드 확인 (파일 변경 없음)
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` 실행, 에러 없이 성공 확인

---

#### [ ] Task 42 — 수동 시나리오 검증
**대상**: 시뮬레이터/실기기 수동 테스트 (파일 변경 없음)
- 앱 1회 실행 → 홈 화면에 플랜 위젯 추가 → 진행중 일정 표시 확인
- 진행중 일정 삭제 → 앱 재실행 → 가장 가까운 미래 일정으로 바뀌는지 확인
- 모든 일정 삭제 → 빈 상태 문구 확인
- 플랜 위젯 탭 → 해당 일정 상세로 이동, 진행중이면 오늘 일자가 선택되는지 확인
- 문구 위젯 추가 → 시간 경과(또는 시뮬레이터 시간 변경)에 따라 다른 문구가 노출되는지 확인
- 문구 위젯 탭 → ToolBar 탭 + 한국어 문구 목록 진입 확인
- 앱 완전 종료 + 기기 재부팅 후에도 두 위젯이 마지막 스냅샷 기준으로 렌더되는지 확인
- App Group 값 손상 시뮬레이션(공유 UserDefaults 키에 쓰레기 문자열 주입) → 크래시 없이 빈 상태 표시 + `AppLogger.core` 에러 로그 확인
- 위젯이 가리키는 일정을 앱에서 삭제한 뒤 위젯 탭 → 크래시/빈 화면 없이 Plan 탭까지만 이동하는지 확인
- **실기기**: 기존 버전 위에 덮어 설치 → 온보딩/설정값(`onboardingCompleted`, `recentSearchHistory`, `autoScrollToTodayEnabled`, `autoTranslateSearchEnabled`) 유지 여부 확인 (결정사항 10 리스크 검증)

---

## 체크리스트

### 품질 (DoD)
- [ ] 빌드 성공 (`xcodebuild build`, Phase 1/2/5/6 각 종료 시 `tuist generate` 포함)
- [ ] App 타겟 산출물에 `PlugIns/Widget.appex`가 포함되고, App/Widget 양쪽에 App Group entitlement가 적용됨
- [ ] 위젯 타겟이 `Data` / `DesignSystem` / Firebase / SwiftData / NMapsMap을 링크하지 않음 (`DependencyInformation`의 `.widget` 의존이 `[.domain, .core, .resource]`뿐)
- [ ] `Domain`이 `Data`를 import하지 않고, `liveValue` 등록은 `App/Sources/Dependency/`에서만 수행
- [ ] `group.com.yslee.tabikori` 문자열이 `Core/Sources/Config/AppGroup.swift` 한 곳에만 존재
- [ ] 스냅샷 부재/손상 시 크래시 없이 빈 상태 렌더 + `AppLogger.core` 에러 로그 (`try!` / 강제 언래핑 없음)
- [ ] 위젯에 표시되는 모든 문자열이 `Resource/Sources/Strings/Strings.swift`에 정의됨 (하드코딩 0건)
- [ ] 지역명/이모지 매핑이 위젯 타겟에 중복 정의되지 않음 (표시 문자열은 스냅샷 기록 시점에 확정)
- [ ] 프로토콜 채택은 `extension` 분리, `private` 멤버는 하단 `extension`에 모음, State/Action 선언 순서 규칙 준수
- [ ] `TravelPlanUseCase` / `KoreanPhraseUseCase` / `KoreanPhraseRepository` / `TravelPlanModel*` 무변경
- [ ] 테스트 통과 (테스트 타겟 미구성 상태이므로 해당 없음 — 추가 시 `.claude/rules/test-style.md` 준수)

### 기능 (AC)
- [ ] 홈 화면에 플랜 위젯을 추가하면 진행 중인 일정이 있을 때 해당 일정이 표시된다
- [ ] 진행 중인 일정이 없으면 가장 가까운 미래 일정이 표시된다
- [ ] 일정이 전혀 없으면 빈 상태 문구가 표시된다
- [ ] 플랜 위젯을 탭하면 앱의 해당 일정 상세 화면으로 이동한다
- [ ] 홈 화면에 한국어 사전 위젯을 추가하면 문구가 주기적으로 로테이션되어 표시된다
- [ ] 한국어 사전 위젯을 탭하면 앱의 한국어 문구 목록 화면으로 이동한다
- [ ] 앱을 실행하지 않은 상태에서도(기기 재부팅 등) 마지막으로 저장된 스냅샷 기준으로 위젯이 정상 표시된다
- [ ] App Group 스냅샷이 없거나 손상된 경우에도 위젯이 크래시하지 않고 빈 상태를 표시한다

### 후속 과제 (완료 조건 외, 별도 트래킹)
- [ ] 위젯 기동 비용 실측 후 스냅샷 계약을 `Core`로 내릴지 재검토 (결정사항 2)
- [ ] App Group 전환 시 기존 `UserDefaults` 마이그레이션 필요 여부 확인 (결정사항 10)
- [ ] `.claude/rules/folder-structure.md` / `git-style.md`에 `Widget` 모듈/스코프 항목 추가

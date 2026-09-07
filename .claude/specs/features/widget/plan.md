# Plan: widget

## 참조 Spec
- `@.claude/specs/features/widget/spec.md`

## 참조 Skill
- `@.claude/skills/feature/SKILL.md` (spec → plan → tasks → 구현 흐름)
- 신규 화면 생성은 없음(위젯 뷰는 `Presentation` Feature가 아니라 위젯 타겟 전용 SwiftUI 뷰) — 대신 아래를 레퍼런스로 삼는다
  - Tuist 타겟 추가: `Tuist/ProjectDescriptionHelpers/Templates/{Project,Target}.swift` + `Projects/*/Project.swift`
  - App Group 접근: `Projects/Data/Sources/UserDefault/TabiUserDefault.swift`
  - 진행중/예정 일정 판정: `Projects/Presentation/Sources/Plan/Model/TravelPlan+.swift` (`section`, `todayDayIndex`, `displayEmoji`, `displayRegionTitle`)

---

## 현재 상태 파악

### 신규

| 경로 | 내용 |
|------|------|
| `Projects/Widget/Project.swift` | 위젯 익스텐션 Tuist 프로젝트 (`product: .appExtension`) |
| `Projects/Widget/Info.plist` | `NSExtension` / `NSExtensionPointIdentifier = com.apple.widgetkit-extension`, `CFBundleDisplayName` |
| `Projects/Widget/Sources/TabiWidgetBundle.swift` | `@main WidgetBundle` — `TabiPlanWidget` + `TabiPhraseWidget` |
| `Projects/Widget/Sources/Plan/TabiPlanWidget.swift` | `StaticConfiguration`, `supportedFamilies([.systemSmall, .systemMedium])` |
| `Projects/Widget/Sources/Plan/PlanTimelineProvider.swift` | `TimelineProvider` — 스냅샷 로드 + 자정 경계 엔트리 생성 |
| `Projects/Widget/Sources/Plan/PlanWidgetEntry.swift` | `TimelineEntry` (date + 선택된 일정 + 디데이) |
| `Projects/Widget/Sources/Plan/PlanWidgetView.swift` | Small/Medium 분기 뷰 + 빈 상태 |
| `Projects/Widget/Sources/Phrase/TabiPhraseWidget.swift` | 문구 위젯 configuration |
| `Projects/Widget/Sources/Phrase/PhraseTimelineProvider.swift` | 로테이션 엔트리 생성 |
| `Projects/Widget/Sources/Phrase/PhraseWidgetEntry.swift` | `TimelineEntry` (date + 문구 1건) |
| `Projects/Widget/Sources/Phrase/PhraseWidgetView.swift` | Small/Medium 분기 뷰 + 빈 상태 |
| `Projects/Widget/Sources/Style/WidgetStyle.swift` | 위젯 전용 폰트/여백 상수 (DesignSystem 미의존, 결정사항 3) |
| `Projects/Core/Sources/Config/AppGroup.swift` | `public enum AppGroup { static let identifier = "group.com.yslee.tabikori" }` |
| `Projects/Domain/Sources/Entity/PlanWidgetSnapshot.swift` | `Codable` 경량 모델 + 날짜 기준 표시 대상 선택 로직 |
| `Projects/Domain/Sources/Entity/PhraseWidgetSnapshot.swift` | `Codable` 경량 모델 + 인덱스 기준 문구 선택 로직 |
| `Projects/Domain/Sources/Entity/WidgetDeepLink.swift` | 딥링크 URL 생성/파싱 (앱·위젯 공용) |
| `Projects/Domain/Sources/UseCase/Widget/WidgetSnapshotStoreProtocol.swift` | read/write/reload 프로토콜 |
| `Projects/Domain/Sources/UseCase/Widget/WidgetSnapshotStore.swift` | App Group `UserDefaults` + JSON 구현체 (결정사항 2) |
| `Projects/Domain/Sources/UseCase/Widget/TestWidgetSnapshotStore.swift` | `testValue`용 인메모리 더블 |
| `Projects/Domain/Sources/Dependency/Keys/WidgetSnapshotStoreDependencyKey.swift` | `TestDependencyKey` + `testValue` |
| `Projects/App/Sources/Dependency/WidgetSnapshotStoreDependencyKey.swift` | `@retroactive DependencyKey` + `liveValue` |
| `Projects/Presentation/Sources/Widget/WidgetSnapshotSync.swift` | `TravelPlan`/`KoreanPhrase` → 스냅샷 변환 + 기록 Effect 헬퍼 (결정사항 4) |

### 재사용
- `TabiColor`(`Color.getTabiColor`) — 위젯 배경/텍스트 컬러. `Resource`는 외부 의존이 없어 위젯이 안전하게 링크 가능
- `ResourceFontFamily.PretendardJPVariable.*.swiftUIFont(size:)` — Tuist 합성 접근자가 `register()`를 내부에서 수행하므로 위젯 프로세스에서도 커스텀 폰트 사용 가능(`Projects/Resource/Derived/Sources/TuistFonts+Resource.swift` 확인 완료)
- `Strings` — 위젯 문구도 동일하게 Resource에 정의 (일본어)
- `AppLogger.core` — 스냅샷 디코딩 실패 로깅(spec 명시)
- `TravelPlan+.swift`의 `section` / `todayDayIndex` / `dayCount` / `displayEmoji` / `displayRegionTitle` — 스냅샷 생성 시점(Presentation)에서 그대로 사용, 파일 자체는 무변경
- `StackPath.planDetail` / `StackPath.koreanPhraseList` — 딥링크 목적지로 기존 경로 재사용 (신규 route 없음)
- `TravelPlanUseCaseProtocol.fetch()` / `KoreanPhraseUseCaseProtocol.fetchPhrases()` — 스냅샷 소스, 시그니처 무변경

### 수정

| 경로 | 내용 |
|------|------|
| `Tuist/ProjectDescriptionHelpers/Templates/Target.swift` | `makeTarget`에 `entitlements: Entitlements? = nil` 파라미터 추가 후 `Target.target(entitlements:)`에 전달 |
| `Tuist/ProjectDescriptionHelpers/Templates/Project.swift` | `makeProject`에 `entitlements` 파라미터 추가(단일 타겟 구조 유지) |
| `Tuist/ProjectDescriptionHelpers/Dependency/DependencyInformation.swift` | `case widget = "Widget"` 추가, `.widget: [.domain, .core, .resource]`, `.app`의 의존 대상에 `.widget` 추가 |
| `Workspace.swift` | `"Projects/Widget"` 추가 |
| `Projects/App/Project.swift` | `entitlements`(App Group) 전달 |
| `Projects/App/Info.plist` | `CFBundleURLTypes`에 커스텀 스킴 `tabikori` 등록 |
| `Projects/Data/Sources/UserDefault/TabiUserDefault.swift` | 하드코딩된 `"group.com.yslee.tabikori"` → `AppGroup.identifier` 참조 (단일 진실 원천화) |
| `Projects/Domain/Sources/Dependency/DependencyValues.swift` | `widgetSnapshotStore` 프로퍼티 확장 추가 |
| `Projects/Resource/Sources/Strings/Strings.swift` | `Strings.Widget` enum + extension 추가 |
| `Projects/Presentation/Sources/Root/RootFeature.swift` | 앱 실행 시 스냅샷 동기화, 딥링크 URL 수신/파싱 액션 추가 |
| `Projects/Presentation/Sources/Root/RootView.swift` | `.onOpenURL { store.send(.openURLReceived($0)) }` |
| `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift` | `deepLinkReceived(WidgetDeepLink)` 처리 — 탭 전환 + `path` 이동 |
| `Projects/Presentation/Sources/Plan/PlanFeature.swift` | 일정 목록이 확정되는 4개 지점에서 스냅샷 동기화 Effect 병합 |

### 삭제
- 없음

### 변경 불필요 (확인 완료)
- `Projects/Domain/Sources/UseCase/TravelPlan/*`, `Projects/Domain/Sources/UseCase/KoreanPhrase/*` — 스냅샷 기록을 UseCase에 넣지 않음(결정사항 4)
- `Projects/Data/**` — 위젯은 SwiftData/Firebase에 직접 접근하지 않으므로 Repository 계층 무변경
- `Projects/DesignSystem/**` — 위젯은 DesignSystem에 의존하지 않음(결정사항 3)
- `Projects/Presentation/Sources/Navigation/StackPath.swift` — 기존 case 재사용
- `Projects/Presentation/Sources/PlanDetail/PlanDetailFeature.swift` — `State(plan:initialDayIndex:)` 기존 이니셜라이저로 딥링크 진입 가능
- deployment target iOS 26.0 → WidgetKit / `containerBackground` 제약 없음

### 사전 확인된 사실 (중요)
- **App Group entitlement 파일이 레포에 존재하지 않는다.** `find . -name "*.entitlements"` 결과 0건이고 Tuist 타겟 설정에도 `entitlements`가 없다. 즉 `TabiUserDefault`가 쓰는 `group.com.yslee.tabikori` suite는 **현재 공유 컨테이너로 동작하지 않는다**. 이 기능의 최우선 선행 작업(Phase 0/1).
- `Target.makeTarget`은 `sources: ["Sources/**"]`로 고정이고 `makeProject`는 **프로젝트당 타겟 1개**만 만든다 → 위젯은 별도 Tuist 프로젝트(`Projects/Widget`)로 만드는 것이 기존 헬퍼 구조와 충돌이 가장 적다(결정사항 1).
- `KoreanPhrase`에는 **카테고리 필드가 없다**(`id/order/korean/japanese/pronunciation`). spec의 "카테고리별 문구"는 현재 데이터 모델로는 표현 불가(결정사항 7).
- `KoreanRegion.jaTitle` / `.emoji`는 `Presentation/Sources/Home/Model/KoreanRegion+.swift`의 **internal extension**이며 `Resource`에 의존한다 → Domain/위젯에서 사용 불가. 표시 문자열은 스냅샷 기록 시점(Presentation)에 확정해야 한다(결정사항 4의 핵심 근거).

---

## 기술적 결정사항

### 1. 위젯은 `Projects/Widget` 별도 Tuist 프로젝트로 만들고, App이 `.widget`을 의존하게 한다
- **이유**: `Project.makeProject`는 타겟 1개 고정, `Target.makeTarget`은 `sources: ["Sources/**"]` 고정이다. App 프로젝트 안에 위젯 타겟을 끼워 넣으려면 두 헬퍼의 시그니처를 크게 바꾸거나 `Projects/App/Project.swift`에서 `Target.target(...)`을 원시 호출해야 해서, 이 레포가 지키고 있는 "모든 타겟은 헬퍼로 생성" 규칙이 깨진다.
- 별도 프로젝트로 만들면 `makeProject(name: "Widget", product: .appExtension, hasResource: false, infoPlist:, entitlements:)` 한 줄로 끝나고, `bundleId`도 헬퍼 규칙에 따라 `com.yslee.tabikori.Widget`으로 자동 생성된다(앱 번들 ID 접두 조건 충족).
- 임베딩은 `DependencyInformation.internalDependencyInfo[.app]`에 `.widget`을 추가해 `.project(target: "Widget", path: "Projects/Widget")` 의존을 만들면 Tuist가 Embed App Extensions 빌드 페이즈를 생성한다.
- **검증 필수**: `tuist generate` 후 App 타겟에 위젯이 Embed 되는지(생성된 `.xcodeproj`의 Embed 페이즈 / 빌드 산출물 `TabiKori.app/PlugIns/Widget.appex`) **Phase 1에서 반드시 눈으로 확인**한다. 만약 크로스 프로젝트 임베딩이 동작하지 않으면 그때 App 프로젝트 내 다중 타겟 방식으로 선회한다(그 경우에만 헬퍼 시그니처를 확장).
- **대안(기각)**: `Projects/App/Widget/Sources/**` 서브폴더 + App 프로젝트 다중 타겟 — 임베딩은 가장 확실하지만 헬퍼 2개를 동시에 수술해야 하고, 앱/위젯 소스가 한 프로젝트에 섞여 `folder-structure.md`의 "모듈 = 폴더" 규칙과 어긋난다.

### 2. 스냅샷 모델과 저장소는 `Domain`에 둔다 (`Data` 아님)
- spec은 "Data: `TabiUserDefault`를 통한 스냅샷 read/write 유틸 추가"라고 했지만, 그러면 **위젯 타겟이 `Data`를 링크해야 하고 `Data`는 `FirebaseDatabase`에 의존**한다. spec의 불변 조건("위젯은 Firebase/SwiftData에 직접 접근하지 않음")과 정면으로 충돌하고, 익스텐션 바이너리에 Firebase가 통째로 들어간다.
- 따라서 스냅샷 저장소는 `UserDefaults(suiteName:)` + `JSONEncoder`만 쓰는 순수 Foundation 코드로 `Domain/Sources/UseCase/Widget/`에 둔다. `Domain`은 `Core`에만 의존하므로 위젯이 링크해도 부담이 적다.
- **예외 사유 명시**: 이 레포는 영속화 구현체를 `Data`에 두는 것이 원칙이지만, 이 저장소는 앱과 익스텐션이 **공유해야 하는 최소 계약**이라 `Data`(Firebase/SwiftData 포함)를 익스텐션에 끌고 들어가지 않기 위한 의도적 예외다. 구현 시 파일 상단 주석으로 이 사유를 남긴다.
- App Group 식별자만 `Core/Sources/Config/AppGroup.swift`로 올려 `TabiUserDefault`(Data)와 `WidgetSnapshotStore`(Domain)가 같은 상수를 보게 한다 — 문자열 중복 제거가 목적이며 그 외 `TabiUserDefault` 동작은 손대지 않는다.
- **대안(기각)**: 스냅샷 모델·저장소를 `Core`에 두기 — 위젯이 `Domain`(TCA 링크)조차 안 봐도 되지만, 여행 일정/문구라는 도메인 데이터를 "로거·설정 유틸" 레이어에 넣게 되어 레이어 의미가 무너진다. 위젯 프로세스 기동 비용이 실측으로 문제가 될 때만 재검토한다(후속 과제로 기록).

### 3. 위젯은 `DesignSystem`에 의존하지 않는다
- `DesignSystem`은 `NMapsMap`(네이버 지도)과 `Kingfisher`에 의존한다. 위젯 익스텐션에 지도 SDK를 링크하는 것은 메모리/기동 비용 측면에서 부적절하다.
- 위젯은 `Resource`(외부 의존 0)만 UI 리소스로 쓰고, 폰트는 `ResourceFontFamily...swiftUIFont(size:)`를 직접 호출한다(`Font.pretendard`는 DesignSystem 소속이라 사용 불가).
- 위젯 전용 폰트/여백 상수는 `Widget/Sources/Style/WidgetStyle.swift`에 모은다. **소량의 스타일 중복은 감수**하되, 컬러/문자열/폰트 파일은 절대 중복 정의하지 않고 `Resource`를 통한다.
- 카드/버튼 등 DesignSystem 컴포넌트는 위젯에서 재현하지 않는다 — 위젯 레이아웃은 텍스트 + 배경 뿐이라 컴포넌트가 필요 없다.

### 4. 스냅샷 기록 지점은 `Presentation`이고, `Domain` UseCase는 건드리지 않는다
- **결정적 이유**: 위젯에 표시할 이모지/지역명은 `displayEmoji`·`displayRegionTitle`(→ `KoreanRegion.emoji`/`.jaTitle`)로 결정되는데, 이 확장들은 `Presentation`의 internal extension이고 `Resource`에 의존한다. `Domain`의 `TravelPlanUseCase`에서는 이 값을 만들 수 없다.
- 대안으로 스냅샷에 `regionRaw`만 저장하고 위젯이 재해석하게 하면, 위젯 타겟에 지역→이모지/일본어명 매핑을 **한 벌 더** 만들게 되어 화면과 위젯의 표기가 갈라진다. 표시 문자열은 **기록 시점에 확정**한다.
- 기록 지점(총 3곳, 모두 `WidgetSnapshotSync` 헬퍼 호출):
  1. `RootFeature.onAppear` — 앱 실행 시 1회. `travelPlanUseCase.fetch()` + `koreanPhraseUseCase.fetchPhrases()`를 각각 `.run`으로 수행해 두 스냅샷을 갱신. 실패는 `AppLogger.view` 로깅 후 무시(기존 스냅샷 유지). 이 경로 하나로 "탭을 한 번도 방문하지 않아도 최신화"가 보장된다.
  2. `PlanFeature`의 `plansResult` / `planDeleted` / `editPlan(.presented(.planUpdated))` / `importResult(true)` — 모두 `state.plans`가 최신으로 확정된 직후. 세션 중 추가/수정/삭제/가져오기를 전부 커버한다.
  3. 문구는 세션 중 변경되지 않으므로(Firebase 정적 목록 + `FirebaseListCache`) 1번 외 추가 지점 없음.
- **대안(기각)**: `TravelPlanUseCase.add/update/remove`에 기록을 넣는 방식 — 호출 누락은 없지만 표시 문자열 문제가 해결되지 않고, 뮤테이션마다 전체 재조회가 강제된다.

### 5. "표시할 일정 선택"과 "문구 로테이션"은 **읽는 쪽(위젯 TimelineProvider)** 에서 계산한다
- 앱이 실행되지 않아도 날짜는 흐른다. 기록 시점에 "오늘 기준 진행중 일정 1건"을 확정해 저장하면 디데이가 하루만 지나도 틀린 값이 박제된다(Acceptance Criteria "앱을 실행하지 않은 상태에서도 정상 표시" 위반).
- 따라서 스냅샷에는 **목록**을 저장하고, 선택 로직은 `PlanWidgetSnapshot.plan(on: Date)`로 `Domain`에 두어 위젯이 엔트리 생성 시각 기준으로 매번 계산한다.
  - 선택 규칙: `startDate...endDate`에 해당 날짜가 포함된 일정 중 `startDate` 오름차순 첫 번째 → 없으면 `startDate > 오늘`인 미래 일정 중 `startDate` 오름차순 첫 번째 → 없으면 `nil`(빈 상태)
  - 디데이/N일차도 엔트리 날짜 기준 계산
- 저장 용량 방어: 과거 종료 일정(`endDate < 오늘`)은 기록하지 않고, 최대 20건으로 제한한다. 문구는 최대 30건.
- 문구 로테이션도 동일하게 스냅샷은 목록만 저장하고, 위젯이 `index = (경과분 / 주기) % count`로 선택한다.

### 6. 타임라인 갱신 정책
- **플랜 위젯**: 엔트리는 "지금" + 이후 자정 경계 7개(총 8개), `policy: .after(마지막 엔트리 이후 자정)`. 자정마다 디데이/진행중 판정이 자동으로 바뀌고, 앱 미실행 상태로 일주일까지는 정확하다.
- **문구 위젯**: 30분 간격 엔트리 48개(24시간분), `policy: .atEnd`. WidgetKit 일일 리프레시 예산을 쓰지 않고 하루치를 한 번에 만든다.
- **강제 리로드**: `WidgetSnapshotStore.write` 성공 시 `WidgetCenter.shared.reloadTimelines(ofKind:)`를 **해당 종류만** 호출한다. 단, **인코딩 결과가 이전 저장값과 동일하면 write도 reload도 하지 않는다** — `RootFeature.onAppear`가 매 실행마다 도는데 무조건 reload하면 WidgetKit 리로드 예산을 낭비한다.
- 위젯 `kind` 문자열은 `Domain`의 `WidgetKind`(또는 `WidgetDeepLink`와 같은 파일)에 상수로 두고 위젯/앱이 공유한다.

### 7. 문구 위젯은 "카테고리별"이 아니라 "전체 문구 순환"으로 구현한다
- `KoreanPhrase`에 카테고리 필드가 없고, Firebase `TabiKori/koreanPhrases/phrases`의 스키마(`order/korean/japanese/pronunciation`)에도 없다. 카테고리를 넣으려면 Firebase 스키마 + Entity + Repository + 목록 화면까지 함께 바뀌어야 하며 이는 이 spec의 범위를 넘는다.
- 따라서 이번 범위는 `order` 오름차순 전체 목록을 30분 주기로 순환 노출한다. spec 본문의 "카테고리별"과 차이가 있으므로 **구현 전 사용자 확인 항목**으로 남긴다(아래 "확인 필요" 참조).

### 8. 딥링크는 커스텀 스킴 `tabikori://`, 파싱 규칙은 `Domain`이 소유한다
- `Projects/App/Info.plist`에 `CFBundleURLTypes` 추가(스킴 `tabikori`). Universal Link는 도메인/AASA 파일 운영이 필요해 범위 외.
- `WidgetDeepLink`(Domain)가 URL 생성과 파싱을 모두 갖는다 → 위젯(생성)과 앱(파싱)이 같은 규칙을 공유하고 문자열 오타로 깨질 여지를 없앤다.
  - `tabikori://plan/{uuid}` → `.planDetail(UUID)`
  - `tabikori://koreanPhrase` → `.koreanPhraseList`
- 라우팅 흐름: `RootView.onOpenURL` → `RootFeature.openURLReceived(URL)` → 파싱 → `TabBarFeature.deepLinkReceived(WidgetDeepLink)`
  - 온보딩 미완료(`tabBarState == nil`)면 무시하고 `AppLogger.view` 로깅. (실제로 위젯을 놓으려면 앱을 이미 쓴 상태라 발생 확률이 낮고, 보류 후 재생 로직은 상태 추가 대비 이득이 작다.)
  - `.koreanPhraseList`: `selectedTab = .toolbox`, 이미 스택 최상단이 `koreanPhraseList`면 중복 push하지 않음
  - `.planDetail(id)`: `selectedTab = .plan` 후 `travelPlanUseCase.fetch()`로 해당 id를 찾아 `PlanDetailFeature.State(plan:initialDayIndex: plan.todayDayIndex ?? 0)` push. **찾지 못하면**(삭제된 일정) 탭만 전환하고 `AppLogger.view` 로깅 — 위젯 스냅샷이 오래되어 이미 없는 일정을 가리킬 수 있으므로 반드시 처리한다.

### 9. 실패는 전부 "빈 상태"로 흡수한다
- `WidgetSnapshotStore.read`는 `throws`가 아니라 **옵셔널 반환**으로 설계한다. 값 없음 / `Data` 아님 / 디코딩 실패를 모두 `nil`로 접고, 디코딩 실패에 한해 `AppLogger.core.log(.error, ...)`를 남긴다(spec 명시). 위젯 프로세스에서 throw가 전파돼 `TimelineProvider`가 엔트리를 못 만드는 상황을 원천 차단한다.
- 강제 언래핑 금지 규칙에 따라 `try!`/`!` 없이 `guard let` + `??` 로만 처리한다.

### 10. App Group 활성화가 기존 사용자 설정에 주는 영향 (리스크)
- 현재 entitlement가 없는 상태의 `UserDefaults(suiteName: "group.com.yslee.tabikori")`와, entitlement 부여 후의 실제 공유 컨테이너는 **저장 위치가 다를 수 있다**. 즉 App Group을 켜는 순간 기존 사용자의 `onboardingCompleted` / `recentSearchHistory` / `autoScrollToTodayEnabled` / `autoTranslateSearchEnabled`가 초기화된 것처럼 보일 수 있다.
- 이 기능의 부작용 중 유일하게 사용자 데이터에 영향을 주는 부분이므로, **실기기에서 "기존 앱 위에 덮어 설치" 시나리오를 반드시 확인**한다(Phase 7). 초기화가 실제로 발생하면 마이그레이션(standard → suite 복사) 필요 여부를 별도 논의한다.

### 11. 범위 밖으로 명시하는 것
- 잠금화면(`accessoryRectangular` 등) / Large 패밀리 — spec에서 Small·Medium으로 한정
- `AppIntent` 기반 설정형 위젯(표시할 일정 직접 선택 등) — spec 요구 없음
- 위젯에서의 데이터 변경(체크박스 등 인터랙티브 위젯) — 읽기 전용
- Analytics 이벤트(`widgetTapped` 등) — spec 요구 없음. 필요 시 후속
- `Live Activity` / `Control Widget`

---

## 구현 순서

> Tuist 타겟/파일이 늘어나므로 각 Phase 끝에 `tuist install && tuist generate`를 실행한다(신규 `.swift` 추가 후 generate 없이 빌드하면 stale 프로젝트로 오탐 에러 발생).
> 빌드 destination은 `platform=iOS Simulator,name=iPhone 17` (iPhone 16 Pro 미설치).

### Phase 0. App Group 선행 검증 (차단 요소)
1. Apple Developer 계정에서 App Group `group.com.yslee.tabikori`가 존재하는지, `com.yslee.tabikori`(App)와 `com.yslee.tabikori.Widget`(Widget) App ID에 활성화 가능한지 확인
2. 자동 서명으로 진행할 경우 Xcode가 프로파일을 갱신할 수 있는지 확인
3. **여기서 막히면 이후 Phase 전부 무의미**하므로 진행 전 사용자에게 상태를 보고한다

### Phase 1. Tuist 인프라 (코드 0줄, 구조만)
1. `Templates/Target.swift` — `makeTarget`에 `entitlements: Entitlements? = nil` 추가 → `Target.target(entitlements:)`로 전달
   - Tuist 4.196.1의 `Entitlements`/`Target.target` 시그니처는 구현 직전 `ProjectDescription` 소스로 **재확인**한다(API 추측 금지)
   - entitlement 값은 파일 대신 딕셔너리(`com.apple.security.application-groups` = `[group.com.yslee.tabikori]`)로 선언해 App/Widget이 같은 정의를 공유하고 신규 파일을 만들지 않는다. 딕셔너리 형태가 지원되지 않으면 `Projects/App/Support/App.entitlements` + `Projects/Widget/Support/Widget.entitlements` 2파일로 대체
2. `Templates/Project.swift` — `makeProject`에 `entitlements` 파라미터 추가 후 `makeTarget`에 전달 (단일 타겟 구조는 유지)
3. `DependencyInformation.swift`
   - `case widget = "Widget"` 추가
   - `internalDependencyInfo`: `.widget: [.domain, .core, .resource]`, `.app`에 `.widget` 추가
   - `externalDependencyInfo`: 위젯은 외부 라이브러리 없음(등록하지 않음)
4. `Workspace.swift`에 `"Projects/Widget"` 추가
5. `Projects/Widget/Info.plist` 신규 — `NSExtension` / `NSExtensionPointIdentifier = com.apple.widgetkit-extension`, `CFBundleDisplayName`(일본어 표시명)
6. `Projects/Widget/Project.swift` 신규 — `makeProject(name: "Widget", product: .appExtension, hasResource: false, infoPlist: .file(...), entitlements: ...)`
7. `Projects/App/Project.swift` — 동일 `entitlements` 전달 (Crashlytics 스크립트 등 기존 인자는 그대로)
8. `Projects/Widget/Sources/TabiWidgetBundle.swift`에 **빈 껍데기 위젯 1개**만 넣고 `tuist install && tuist generate` → 빌드
9. **검증 포인트**: 빌드 산출물 `TabiKori.app/PlugIns/Widget.appex` 존재 확인, 시뮬레이터 위젯 갤러리에 노출 확인. 실패 시 결정사항 1의 대안으로 선회

### Phase 2. Core / Domain (공유 계약)
1. `Core/Sources/Config/AppGroup.swift` 신규 — `public enum AppGroup { public static let identifier = "group.com.yslee.tabikori" }`
2. `Data/Sources/UserDefault/TabiUserDefault.swift` — 하드코딩 문자열을 `AppGroup.identifier`로 교체 (그 외 무변경)
3. `Domain/Sources/Entity/PlanWidgetSnapshot.swift` 신규
   - `PlanWidgetSnapshot`: `updatedAt: Date`, `plans: [PlanWidgetSnapshotItem]`
   - `PlanWidgetSnapshotItem`: `id: UUID`, `title: String`, `emoji: String`, `regionTitle: String`, `startDate: Date`, `endDate: Date` (표시 문자열은 이미 확정된 상태로 들어옴 — 결정사항 4)
   - `Codable, Equatable, Sendable`
   - `func plan(on date: Date) -> PlanWidgetSnapshotItem?` (결정사항 5의 선택 규칙), `PlanWidgetSnapshotItem.dayCount` / `.dayIndex(on:)` / `.daysUntilStart(on:)` — 모두 `Calendar.startOfDay` 기준
4. `Domain/Sources/Entity/PhraseWidgetSnapshot.swift` 신규
   - `updatedAt`, `phrases: [PhraseWidgetSnapshotItem(id/korean/japanese/pronunciation)]`
   - `func phrase(at index: Int) -> PhraseWidgetSnapshotItem?` (모듈러 인덱싱, 빈 배열이면 `nil`)
5. `Domain/Sources/Entity/WidgetDeepLink.swift` 신규
   - `public enum WidgetDeepLink: Equatable, Sendable { case planDetail(UUID); case koreanPhraseList }`
   - `var url: URL?` / `public init?(url: URL)` — 스킴/호스트 상수는 같은 파일의 `private enum`에
   - 위젯 `kind` 상수(`WidgetKind.plan`, `.phrase`)도 이 파일 또는 인접 파일에 정의
6. `Domain/Sources/UseCase/Widget/WidgetSnapshotStoreProtocol.swift` 신규
   - `Sendable`. `func loadPlanSnapshot() -> PlanWidgetSnapshot?` / `loadPhraseSnapshot() -> PhraseWidgetSnapshot?` / `savePlanSnapshot(_:)` / `savePhraseSnapshot(_:)`
   - read는 `throws` 없이 옵셔널 반환(결정사항 9), save는 내부에서 변경 없으면 no-op(결정사항 6)
7. `Domain/Sources/UseCase/Widget/WidgetSnapshotStore.swift` 신규
   - `public final class WidgetSnapshotStore: @unchecked Sendable`, `UserDefaults(suiteName: AppGroup.identifier)`
   - `JSONEncoder`/`JSONDecoder`에 `dateEncodingStrategy = .iso8601`(앱/익스텐션 간 포맷 고정)
   - 프로토콜 채택은 `// MARK: - WidgetSnapshotStoreProtocol` extension으로 분리
   - 디코딩 실패 시 `AppLogger.core.log(.error, ...)` 후 `nil`
   - 저장 성공 + 값 변경된 경우에만 `WidgetCenter.shared.reloadTimelines(ofKind:)`
   - 파일 상단 주석에 "Data가 아닌 Domain에 두는 이유"(결정사항 2) 명시
8. `Domain/Sources/UseCase/Widget/TestWidgetSnapshotStore.swift` 신규 — 인메모리 더블, 주입용 `var` 프로퍼티 공개
9. `Domain/Sources/Dependency/Keys/WidgetSnapshotStoreDependencyKey.swift` 신규 — `TestDependencyKey` + `testValue`
10. `Domain/Sources/Dependency/DependencyValues.swift` — `widgetSnapshotStore` 프로퍼티 추가
11. `tuist generate`

### Phase 3. App (DI 조립 + URL 스킴)
1. `App/Sources/Dependency/WidgetSnapshotStoreDependencyKey.swift` 신규 — `@retroactive DependencyKey`, `liveValue = WidgetSnapshotStore()`
2. `App/Info.plist` — `CFBundleURLTypes` 배열 추가(`CFBundleURLName` = 번들 ID, `CFBundleURLSchemes` = `["tabikori"]`)

### Phase 4. Resource (문자열)
`Strings.swift`에 `public enum Widget {}` 선언 + `public extension Strings.Widget` 추가. 기존 항목처럼 각 상수 위에 한국어 주석, 값은 **일본어**:
- 플랜 위젯: 갤러리 표시명, 갤러리 설명, 진행중 배지(`N日目` — 기존 `Strings.Plan.dayChipTitle` 재사용 가능하면 재사용), 디데이 표기(`あと N日`), 오늘 시작 표기, 빈 상태 문구("予定された日程がありません")
- 문구 위젯: 갤러리 표시명, 갤러리 설명, 빈 상태 문구
- 기존 재사용 확인: `Strings.KoreanPhrase.listTitle`(문구 위젯 헤더), `Strings.Plan.dayChipTitle` / `.durationBadge`

### Phase 5. 위젯 타겟 구현
1. `Style/WidgetStyle.swift` — 폰트 헬퍼(`ResourceFontFamily` 래핑) + 여백 상수
2. `Plan/PlanWidgetEntry.swift` — `date`, `item: PlanWidgetSnapshotItem?`, 파생 표시값(디데이/일차)
3. `Plan/PlanTimelineProvider.swift`
   - `placeholder` / `getSnapshot`(갤러리 프리뷰용 더미) / `getTimeline`
   - `getTimeline`: 스냅샷 로드 → 지금 + 이후 자정 7개에 대해 `snapshot.plan(on:)` 계산 → `.after(마지막 자정)` (결정사항 6)
   - 스냅샷 `nil`이면 빈 엔트리 1개 + `.after(다음 자정)`
4. `Plan/PlanWidgetView.swift`
   - Small: 이모지 + 제목(2줄) + 디데이/N일차
   - Medium: 이모지 + 제목 + 지역명 + 기간 + 디데이/N일차
   - 빈 상태: 문구만
   - `.containerBackground(for: .widget) { ... }`, `.widgetURL(WidgetDeepLink.planDetail(id).url)` (빈 상태에서는 `widgetURL` 미지정)
5. `Plan/TabiPlanWidget.swift` — `StaticConfiguration(kind: WidgetKind.plan, provider:)`, `configurationDisplayName` / `description` / `supportedFamilies([.systemSmall, .systemMedium])`
6. `Phrase/*` — 동일 구조. 엔트리 30분 간격 48개, `.atEnd`. 뷰는 한국어 원문 + 일본어 번역(+ Medium에서 발음). `widgetURL`은 `WidgetDeepLink.koreanPhraseList.url` 고정
7. `TabiWidgetBundle.swift` — `@main struct TabiWidgetBundle: WidgetBundle { var body: some Widget { TabiPlanWidget(); TabiPhraseWidget() } }`
8. `tuist generate` → 빌드

### Phase 6. Presentation (스냅샷 기록 + 딥링크 수신)
1. `Presentation/Sources/Widget/WidgetSnapshotSync.swift` 신규
   - `[TravelPlan]` → `PlanWidgetSnapshot` 변환(과거 종료 일정 제외, `startDate` 오름차순, 최대 20건, `displayEmoji`/`displayRegionTitle`로 표시 문자열 확정)
   - `[KoreanPhrase]` → `PhraseWidgetSnapshot` 변환(`order` 오름차순, 최대 30건)
   - 기록 Effect 헬퍼(Action 제네릭 `Effect`) 제공 — 호출부는 `.merge`로 끼워 넣기만 하면 되도록
2. `RootFeature.swift`
   - `@Dependency(\.travelPlanUseCase)`, `@Dependency(\.koreanPhraseUseCase)`, `@Dependency(\.widgetSnapshotStore)` 추가
   - Action 추가(선언 순서 규칙 준수): 생명주기 뒤에 `openURLReceived(URL)`, 하위 액션 앞
   - `.onAppear`: 기존 `.merge(onboardingEffect, subscribeToastEffect())`에 `syncWidgetSnapshotEffect()` 추가. 실패는 `AppLogger.view` 로깅 후 무시
   - `.openURLReceived(url)`: `WidgetDeepLink(url:)` 파싱 실패 또는 `tabBarState == nil` → 로깅 후 `.none`, 아니면 `.send(.tabBar(.deepLinkReceived(link)))`
3. `RootView.swift` — `.onAppear` 아래에 `.onOpenURL { self.store.send(.openURLReceived($0)) }`
4. `TabBarFeature.swift`
   - `case deepLinkReceived(WidgetDeepLink)` 추가
   - `.koreanPhraseList`: `selectedTab = .toolbox`, 스택 최상단이 이미 `koreanPhraseList`가 아니면 append
   - `.planDetail(id)`: `selectedTab = .plan` + `travelPlanUseCase.fetch()` 이펙트 → 결과 액션 `deepLinkPlanResolved(TravelPlan?)`에서 append 또는 로깅
   - `@Dependency(\.travelPlanUseCase)` 추가, `CancelID`에 딥링크 조회용 case 추가
5. `PlanFeature.swift` — `plansResult` / `planDeleted` / `editPlan(.presented(.planUpdated))` / `importResult(true)` 4개 지점에서 `state.plans` 기준 스냅샷 기록 Effect를 `.merge`
6. `tuist generate` → 빌드

### Phase 7. 검증
1. `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'`
2. 수동 시나리오
   - 앱 1회 실행 → 홈 화면에 플랜 위젯 추가 → 진행중 일정 표시 확인
   - 진행중 일정 삭제 → 앱 재실행 → 가장 가까운 미래 일정으로 바뀌는지
   - 모든 일정 삭제 → 빈 상태 문구
   - 플랜 위젯 탭 → 해당 일정 상세로 이동, 진행중이면 오늘 일자가 선택되는지
   - 문구 위젯 추가 → 시간 경과(또는 시뮬레이터 시간 변경)에 따라 다른 문구 노출
   - 문구 위젯 탭 → ToolBar 탭 + 한국어 문구 목록 진입
   - 앱 완전 종료 + 기기 재부팅 후에도 두 위젯이 마지막 스냅샷으로 렌더되는지
   - App Group 값 손상 시뮬레이션(공유 UserDefaults 키에 쓰레기 문자열 주입) → 크래시 없이 빈 상태 + `AppLogger.core` 에러 로그
   - 위젯이 가리키는 일정을 앱에서 삭제한 뒤 위젯 탭 → 크래시/빈 화면 없이 Plan 탭까지만 이동
   - **실기기: 기존 버전 위에 덮어 설치 → 온보딩/설정값 유지 여부 확인**(결정사항 10)

---

## 확인 필요 (구현 착수 전 사용자 결정)
1. **문구 위젯의 "카테고리"** — 현재 `KoreanPhrase`에 카테고리 필드가 없다. 이번 범위는 전체 문구 순환으로 진행하는 것이 맞는지(결정사항 7)
2. **App Group 활성화 가능 여부** — Apple Developer 계정에서 App Group 등록·서명이 가능한지(Phase 0). 불가하면 이 기능 자체가 성립하지 않는다
3. **딥링크 스킴 이름** `tabikori`로 확정해도 되는지

---

## 완료 조건
- [ ] Spec Acceptance Criteria 8개 전부 충족
- [ ] App 타겟 산출물에 `PlugIns/Widget.appex`가 포함되고, App/Widget 양쪽에 App Group entitlement가 적용됨
- [ ] 위젯 타겟이 `Data` / `DesignSystem` / Firebase / SwiftData / NMapsMap을 **링크하지 않음** (`DependencyInformation`의 `.widget` 의존이 `[.domain, .core, .resource]`뿐)
- [ ] `Domain`이 `Data`를 import하지 않고, `liveValue` 등록은 `App/Sources/Dependency/`에서만 수행
- [ ] `group.com.yslee.tabikori` 문자열이 `Core/Sources/Config/AppGroup.swift` 한 곳에만 존재
- [ ] 스냅샷 부재/손상 시 크래시 없이 빈 상태 렌더 + `AppLogger.core` 에러 로그 (`try!` / 강제 언래핑 없음)
- [ ] 위젯에 표시되는 모든 문자열이 `Resource/Sources/Strings/Strings.swift`에 정의됨 (하드코딩 0건)
- [ ] 지역명/이모지 매핑이 위젯 타겟에 중복 정의되지 않음 (표시 문자열은 스냅샷 기록 시점에 확정)
- [ ] 프로토콜 채택은 `extension` 분리, `private` 멤버는 하단 `extension`에 모음, State/Action 선언 순서 규칙 준수
- [ ] `TravelPlanUseCase` / `KoreanPhraseUseCase` / `KoreanPhraseRepository` / `TravelPlanModel*` 무변경
- [ ] 후속 과제 기록: (1) 위젯 기동 비용 실측 후 스냅샷 계약을 `Core`로 내릴지 재검토(결정사항 2), (2) App Group 전환 시 기존 `UserDefaults` 마이그레이션 필요 여부(결정사항 10), (3) `.claude/rules/folder-structure.md`·`git-style.md`에 `Widget` 모듈/스코프 항목 추가

---

### Critical Files for Implementation
- `/Users/yslee/Desktop/Project/TabiKori/Tuist/ProjectDescriptionHelpers/Templates/Target.swift`
- `/Users/yslee/Desktop/Project/TabiKori/Tuist/ProjectDescriptionHelpers/Templates/Project.swift`
- `/Users/yslee/Desktop/Project/TabiKori/Tuist/ProjectDescriptionHelpers/Dependency/DependencyInformation.swift`
- `/Users/yslee/Desktop/Project/TabiKori/Workspace.swift`
- `/Users/yslee/Desktop/Project/TabiKori/Projects/App/Project.swift`
- `/Users/yslee/Desktop/Project/TabiKori/Projects/App/Info.plist`
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Data/Sources/UserDefault/TabiUserDefault.swift`
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Plan/Model/TravelPlan+.swift` (스냅샷 변환의 표시값 원천, 수정 금지)
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Home/Model/KoreanRegion+.swift` (지역 이모지/일본어명 원천, 수정 금지)
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Root/RootFeature.swift`
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Plan/PlanFeature.swift`

# Plan: plan_detail (일정 상세 화면 - NavigationBar + 일자 탭)

## 참조 Spec
- @.claude/specs/features/plan_detail/spec.md

## 참조 Skill
- 해당 프로젝트에 `create-feature` 스킬 없음 — 기존 `Detail`(뒤로가기 toolbar 패턴), `Plan`(fetch Effect / TravelPlan 확장 패턴) 두 기능의 파일 구성을 레퍼런스로 삼는다.

---

## 현재 상태 파악

### 신규
**Presentation**
- `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailDayButton.swift`
  - "N日目"(상단) + "M月d日"(하단) 2줄 pill 버튼. 선택/비선택 스타일 전환 포함
  - `Sub/` 폴더 자체가 신규 생성됨

**Domain — TravelPlanDetail 스캐폴딩** (이번 화면 UI에서는 사용하지 않지만, 추후 "일정을 보여주는 View" 기능이 그대로 이어받을 수 있도록 `TravelPlan`과 동일한 패턴으로 미리 구성 — 사용자 명시 요청)
- `Projects/Domain/Sources/Entity/TravelPlanDetail.swift` — `planId: UUID`만 가진 Equatable/Sendable struct (현재 `TravelPlanDetailModel`과 1:1 매핑)
- `Projects/Domain/Sources/RepositoryProtocol/TravelPlanDetailRepositoryProtocol.swift` — `fetch(planId: UUID) async throws -> TravelPlanDetail?`, `add(_ detail: TravelPlanDetail) async throws`
- `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCaseProtocol.swift` — Repository와 동일한 시그니처
- `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCase.swift` — Repository 위임 구현체
- `Projects/Domain/Sources/UseCase/TravelPlanDetail/TestTravelPlanDetailUseCase.swift` — `details: [TravelPlanDetail]` 프로퍼티 노출하는 테스트 더블
- `Projects/Domain/Sources/Dependency/Keys/TravelPlanDetailUseCaseDependencyKey.swift` — `TestDependencyKey`, `testValue`만 정의

**Data — TravelPlanDetail 스캐폴딩**
- `Projects/Data/Sources/Repository/TravelPlanDetail/TravelPlanDetailRepository.swift` — `TravelPlanModelContainer.shared.modelContainer` 재사용 (Schema에 `TravelPlanDetailModel`이 이미 등록되어 있어 컨테이너 변경 불필요), `planId` `#Predicate` 조회
- `Projects/Data/Sources/Extension/TravelPlanDetailModel+.swift` — `toDomain` / `convenience init(detail:)` 변환 확장

**App — TravelPlanDetail 스캐폴딩**
- `Projects/App/Sources/Dependency/TravelPlanDetailUseCaseDependencyKey.swift` — `@retroactive DependencyKey` extension으로 `liveValue` 정의

### 재사용
- **Domain**: `TravelPlanUseCaseProtocol.fetch()` — 신규 메서드 추가 없음. `@Dependency(\.travelPlanUseCase)`로 주입 (`PlanFeature`와 동일)
- **Domain**: `TestTravelPlanUseCase` — Preview용 목 주입
- **DesignSystem**: `TabiNavigationBar`(title/subtitle), `TabiLabel`, `TabiColor`(tabiPrimary / tabiSurface / tabiBorder / tabiOnColor / tabiTextSecondary / tabiTextPrimary), `TabiPressStyle`, `.tabiFast` / `.tabiStandard` 애니메이션
- **Resource**: `Strings.Plan.dayChipTitle(_:)`("N日目"), `Strings.Plan.durationBadge(_:)`("N日間") — **둘 다 이미 존재하므로 문자열 신규 추가 없음**
- **Core**: `AppLogger.view.log(.error, ...)`
- **Presentation**: `Plan/Model/TravelPlan+.swift`의 `dayCount`, `displayRegionTitle`
- **Navigation**: `StackPath.planDetail`, `TabBarFeature.plan(.planTapped)` → `path.append` 흐름, `TabBarView`의 `destination:` 분기 — **전부 이미 연결 완료, 변경 없음**

### 수정
- `Projects/Presentation/Sources/PlanDetail/PlanDetailFeature.swift`
  - State에 `plan: TravelPlan?`, `travelPlanDetail: TravelPlanDetail?`, `selectedDayIndex: Int`, `isLoading: Bool` 추가
  - **`Action`이 현재 빈 enum(`public enum Action: Equatable {}`)이고 body가 `Reduce { _, _ in .none }`** 이므로 사실상 전면 재작성
  - `onAppear`에서 `travelPlanUseCase.fetch()`와 `travelPlanDetailUseCase.fetch(planId:)`를 함께 호출 (후자는 결과를 State에 저장만 하고 View에서 사용하지 않음)
- `Projects/Domain/Sources/Dependency/DependencyValues.swift`
  - `travelPlanDetailUseCase: TravelPlanDetailUseCaseProtocol` 프로퍼티 확장 추가 (기존 `travelPlanUseCase` 바로 아래)
- `Projects/Presentation/Sources/PlanDetail/PlanDetailView.swift`
  - 현재 `TabiLabel(title: Strings.Plan.title)` 한 줄짜리 스켈레톤 → NavigationBar + 일자 탭 스크롤 + 뒤로가기 toolbar 구성으로 전면 교체
- `Projects/Presentation/Sources/Plan/Model/TravelPlan+.swift`
  - `dayDates: [Date]` 계산 프로퍼티 추가 (`dayCount`와 동일한 `Calendar` 기준 사용)
- `Projects/Presentation/Sources/Extension/Date+.swift`
  - 요일 없는 `M月d日` 포맷 프로퍼티 추가 (`planDayDateTitle` 등, 기존 `ja_JP` DateFormatter 패턴 준수)

### 삭제
- 없음. `PlanDetailFeature` / `PlanDetailView`의 "스켈레톤" 주석은 실제 구현이 들어가는 시점에 의미를 잃으므로 파일 헤더 주석만 실제 역할 설명으로 갱신

---

## 기술적 결정사항

- **`fetch()` + client-side 필터로 단건 조회**: `TravelPlanUseCaseProtocol` / `TravelPlanRepositoryProtocol`에 `fetchByID`를 추가하면 Domain·Data·App(DI)·Test 더블까지 4개 레이어가 연쇄 변경된다. 로컬 SwiftData 저장소이고 일정 개수가 수십 건 수준이라 전량 조회 후 `first(where: { $0.id == state.id })`로 처리하는 비용이 무시할 만하다. (대안: 프로토콜 확장 → 이번 화면 범위 대비 변경 폭 과다, spec 제약에서도 금지)
- **뒤로가기는 네이티브 `.toolbar` + `navigationBarBackButtonHidden(true)`**: `TabiNavigationBar`에 leading 슬롯을 추가하면 이미 이 컴포넌트를 쓰는 Home/Bookmark/Plan/AddTravelPlan/Map 5개 화면의 API가 함께 흔들린다. `DetailView`가 이미 `ToolbarItem(.topBarLeading)` + `chevron.left` + `.tint(tabiPrimary)` 선례를 갖고 있으므로 동일 패턴을 따른다. `@Environment(\.dismiss)`로 pop.
- **일자 pill을 `TabiChip`으로 재사용하지 않고 신규 제작**: `TabiChip`은 `title: String` 1개만 받는 단일 라벨 구조라 "N日目 / M月d日" 2줄을 표현할 수 없다. 억지로 개행 문자열을 넣으면 폰트 스타일을 줄별로 다르게 줄 수 없다. 이번 화면 전용이므로 `folder-structure.md` 규칙에 따라 `DesignSystem`이 아닌 `PlanDetail/Sub/`에 둔다. 다른 화면에서 동일 요구가 생기면 그때 DesignSystem으로 승격.
- **선택 스타일은 `TabiChip` 토큰과 동일하게 맞춤**: 선택 시 `tabiPrimary` 배경 + `tabiOnColor` 텍스트, 비선택 시 `tabiSurface` 배경 + `tabiBorder` 스트로크 + `tabiTextSecondary` 텍스트. 프로젝트 내 pill 계열 시각 언어를 통일하기 위함.
- **`dayDates`를 Presentation 확장에 배치**: 날짜 배열은 화면 표시용 파생값이므로 Domain 엔티티가 아닌 기존 `Plan/Model/TravelPlan+.swift`에 추가한다. `Plan`과 `PlanDetail`이 같은 Presentation 모듈이라 internal 접근으로 그대로 공유된다 (파일 중복 생성 금지).
- **`dayCount`와 `dayDates`는 같은 `Calendar.startOfDay` 기준 사용**: 서로 다른 기준을 쓰면 `dayCount`와 `dayDates.count`가 어긋나 `ForEach` 인덱스 범위 밖 접근이 발생한다. `dayDates`는 `dayCount`를 기반으로 생성해 두 값의 정합성을 구조적으로 보장한다.
- **`isLoading`은 `plan == nil`일 때만 true로 세팅**: `onAppear`는 화면 복귀 시에도 다시 호출된다. 매번 로딩 표시를 켜면 이미 그려진 NavigationBar가 깜빡인다. 이미 로딩된 상태의 재조회는 조용히 갱신만 한다.
- **조회 결과 반영 시 `selectedDayIndex` 클램프**: 일정이 수정되어 `dayCount`가 줄어든 상태로 재조회되면 기존 인덱스가 범위를 벗어난다. 결과 수신 시 `0..<dayCount` 범위로 보정한다.
- **조회 실패 / id 미존재를 같은 경로로 처리**: 둘 다 `planResult(nil)`로 수렴시키고 `isLoading = false`만 해제. 별도 에러 UI를 만들지 않는다(spec 명시). 실패 케이스만 `AppLogger.view`로 로깅해 구분한다.
- **일자 탭 아래는 `Spacer()`만**: 날짜 헤더/지도/빈 스팟 카드는 spec에서 명시적으로 제외됐다. 임시 플레이스홀더 UI를 넣으면 다음 기능 작업 시 제거 대상이 되는 죽은 코드가 된다.
- **`plan == nil` 구간은 `ProgressView`만 노출**: `PlanView.planList()`가 이미 쓰는 `ProgressView().frame(maxWidth: .infinity)` 패턴을 따른다.
- **`TravelPlanDetail`을 이번 화면 UI 요구사항과 무관하게 미리 스캐폴딩**: 사용자가 명시적으로 "필요 없어도 미리 만들어둬"라고 지시함. 기존 `TravelPlanDetailModel`(SwiftData, `planId`만 보유)이 이미 `TravelPlanModelContainer`의 Schema에 등록되어 있으나 Domain/Data/App 어디에도 연결되지 않은 상태였다. `TravelPlan`과 동일한 계층 패턴(Entity → RepositoryProtocol → UseCase → testValue/liveValue)으로 맞춰 구성해 다음 기능("일정을 보여주는 View")이 별도 배선 작업 없이 바로 이어받을 수 있게 한다.
- **Repository 메서드는 `fetch(planId:)` + `add(_:)`로 한정, `fetchOrCreate` 도입하지 않음**: `TravelPlanUseCaseProtocol`이 이미 fetch/add를 분리해서 제공하는 것과 대칭을 맞춘다. 레코드가 없을 때 자동 생성하는 upsert 시맨틱을 넣으면 "언제 생성되는가"에 대한 암묵적 책임이 Repository로 넘어가 버린다. 생성 시점 결정(예: 최초 진입 시 vs 일정 생성 시)은 실제로 데이터를 사용하는 다음 기능에서 판단하는 게 맞다.
- **`PlanDetailFeature.onAppear`에서 `fetch(planId:)`까지 실제로 호출**: 스캐폴딩을 코드만 만들어두고 아무 데서도 호출하지 않으면 "미완성 채 방치된 코드"가 되어 프로젝트 원칙(반쪽 구현 금지)과 충돌한다. `PlanDetailFeature`는 이미 `id`(=`planId`)를 갖고 있어 자연스러운 호출 지점이므로, 결과를 `State.travelPlanDetail`에 저장까지만 하고 View에는 렌더링하지 않는 선에서 실제 연동을 완료한다.
- **`AddTravelPlanFeature`(일정 생성 플로우)는 이번 범위에서 건드리지 않음**: `TravelPlanDetailModel` 레코드를 생성(`add`)하는 시점/주체는 이번 작업의 관심사가 아니다. 현재는 어떤 플로우도 `TravelPlanDetail`을 생성하지 않으므로 `fetch(planId:)`는 항상 `nil`을 반환하지만, 그 자체가 정상 동작이다 (spec의 "무엇이 잘못될 수 있는가" 참조).

---

## 구현 순서

### Phase 1. Presentation - Model / Extension

1. `Projects/Presentation/Sources/Extension/Date+.swift` 수정
   - 요일 없는 `M月d日` 포맷 프로퍼티 추가 (이름 예: `planDayDateTitle`)
   - 기존 프로퍼티와 동일하게 `DateFormatter` + `Locale(identifier: "ja_JP")` 사용
   - 기존 `homeDateTitle`("M月d日(E)")과 포맷이 유사하지만 요일 유무가 달라 재사용 불가 — 별도 프로퍼티로 추가
2. `Projects/Presentation/Sources/Plan/Model/TravelPlan+.swift` 수정
   - `var dayDates: [Date]` 추가
   - 구현 방향: `Calendar.current.startOfDay(for: startDate)`를 기준점으로 `0..<dayCount` 만큼 `date(byAdding: .day, value:)` 수행, 실패 값은 제외(`compactMap`)
   - `dayCount`를 기반으로 생성해 `dayDates.count == dayCount`를 보장
   - 강제 언래핑 금지(`swift-style.md` 4번)

### Phase 2. Presentation - Sub 컴포넌트

1. `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailDayButton.swift` 신규
   - 입력: 일차 타이틀(String), 날짜 타이틀(String), `isSelected: Bool`, `action: () -> Void`
   - 레이아웃: `VStack(spacing:)` 2줄 — 상단 일차(`captionMBold` 계열), 하단 날짜(`captionM` 계열)
   - 선택 스타일: 배경 `tabiPrimary` / 텍스트 `tabiOnColor`, 비선택: 배경 `tabiSurface` + `Capsule().stroke(tabiBorder)` / 텍스트 `tabiTextSecondary`
   - `Capsule()` 클리핑, `Button` + `.buttonStyle(.plain)` (`TabiChip`과 동일한 감각 — pill 단독 탭)
   - `.animation(.tabiFast, value: isSelected)`로 색상 전환
   - 접근 제어는 internal (모듈 외부 노출 불필요, `swift-style.md` 7번)
   - `TabiLabel` 사용, 폰트/색/애니메이션은 전부 DesignSystem 토큰 재사용 (직접 `Font`/`Color` 생성 금지)

### Phase 3. Domain / Data / App - TravelPlanDetail 스캐폴딩

1. `Projects/Domain/Sources/Entity/TravelPlanDetail.swift` 신규
   - `public struct TravelPlanDetail: Equatable, Sendable { public let planId: UUID; public init(planId: UUID) { self.planId = planId } }`
2. `Projects/Domain/Sources/RepositoryProtocol/TravelPlanDetailRepositoryProtocol.swift` 신규
   - `func fetch(planId: UUID) async throws -> TravelPlanDetail?`
   - `func add(_ detail: TravelPlanDetail) async throws`
3. `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCaseProtocol.swift` 신규
   - Repository와 동일한 시그니처 2개
4. `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCase.swift` 신규
   - `TravelPlanUseCase`와 동일하게 Repository 위임만 수행하는 `final class`
5. `Projects/Domain/Sources/UseCase/TravelPlanDetail/TestTravelPlanDetailUseCase.swift` 신규
   - `public var details: [TravelPlanDetail] = []` 노출, `fetch(planId:)`는 `details.first(where: { $0.planId == planId })` 반환, `add(_:)`는 `details.append`
6. `Projects/Domain/Sources/Dependency/Keys/TravelPlanDetailUseCaseDependencyKey.swift` 신규
   - `public enum TravelPlanDetailUseCaseDependencyKey: TestDependencyKey, Sendable { public static var testValue: TravelPlanDetailUseCaseProtocol { TestTravelPlanDetailUseCase() } }`
7. `Projects/Domain/Sources/Dependency/DependencyValues.swift` 수정
   - 기존 `travelPlanUseCase` 프로퍼티 바로 아래에 `travelPlanDetailUseCase` get/set 추가
8. `Projects/Data/Sources/Extension/TravelPlanDetailModel+.swift` 신규
   - `toDomain: TravelPlanDetail` (region 파싱 같은 실패 가능성이 없어 `TravelPlanModel.toDomain`과 달리 non-optional)
   - `convenience init(detail: TravelPlanDetail)`
9. `Projects/Data/Sources/Repository/TravelPlanDetail/TravelPlanDetailRepository.swift` 신규
   - `TravelPlanRepository`와 동일하게 `modelContainer: ModelContainer = TravelPlanModelContainer.shared.modelContainer` 기본값 사용 (Schema에 `TravelPlanDetailModel`이 이미 등록되어 있어 컨테이너 자체는 변경 불필요)
   - `fetch(planId:)`: `FetchDescriptor<TravelPlanDetailModel>(predicate: #Predicate { $0.planId == planId })` → `.first?.toDomain`
   - `add(_:)`: `TravelPlanDetailModel(detail:)` 생성 → `context.insert` → `context.save()`
   - 에러 발생 시 `AppLogger.core.log(.error, ...)` 후 `TabiError.persistenceFailed`로 매핑 (`TravelPlanRepository`와 동일)
10. `Projects/App/Sources/Dependency/TravelPlanDetailUseCaseDependencyKey.swift` 신규
    - `extension TravelPlanDetailUseCaseDependencyKey: @retroactive DependencyKey { public static var liveValue: TravelPlanDetailUseCaseProtocol { TravelPlanDetailUseCase(repository: TravelPlanDetailRepository()) } }`

### Phase 4. Presentation - Feature

1. `Projects/Presentation/Sources/PlanDetail/PlanDetailFeature.swift` 수정
   - `@Dependency(\.travelPlanUseCase) var travelPlanUseCase`, `@Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase` 추가 (`import Core`, `import Domain`, `import ComposableArchitecture`)
   - **State** (선언 순서: 공개 프로퍼티 → fileprivate → @Presents)
     - 기존 `let id: UUID` 유지 (`init(id:)` 시그니처 변경 금지 — `TabBarFeature`가 이미 호출 중)
     - `var plan: TravelPlan?` (초기 nil)
     - `var travelPlanDetail: TravelPlanDetail?` (초기 nil, View에서는 사용하지 않음)
     - `var selectedDayIndex: Int = 0`
     - `var isLoading: Bool = false`
   - **Action** (선언 순서: 바인딩 → 생명주기 → 인터랙션 → 비동기 결과 → 하위)
     - `case onAppear`
     - `case dayButtonTapped(index: Int)`
     - `case planResult(TravelPlan?)`
     - `case travelPlanDetailResult(TravelPlanDetail?)`
     - `Equatable` 유지 (`TravelPlan`/`TravelPlanDetail` 모두 `Equatable`이므로 문제 없음, `StackPath.Action: Equatable` 확장 충족)
   - **body**
     - `onAppear`: `plan == nil`일 때만 `isLoading = true` 세팅 후 두 조회 Effect를 `.merge`로 함께 반환 (`travelPlanUseCase.fetch()` 계열과 `travelPlanDetailUseCase.fetch(planId:)` 계열은 서로 독립적이므로 순차 대기 불필요)
     - `dayButtonTapped(index:)`: `selectedDayIndex` 갱신 후 `.none`
     - `planResult(plan)`: `state.plan = plan`, `isLoading = false`, `selectedDayIndex`를 `0..<dayCount` 범위로 클램프
     - `travelPlanDetailResult(detail)`: `state.travelPlanDetail = detail` (성공이든 nil이든 그대로 저장, 화면 상태에는 영향 없음)
   - **조회 Effect는 `// MARK: - Method` + `private extension`으로 분리** (`PlanFeature.fetchPlansEffect()`와 동일 구조), 두 개로 나눠 작성
     - `fetchPlanEffect()`: `.run { [travelPlanUseCase = self.travelPlanUseCase, id = state.id] send in ... }` → `try await travelPlanUseCase.fetch()` → `first(where: { $0.id == id })` → `send(.planResult(...))`, `catch`에서 `AppLogger.view.log(.error, "...")` 후 `send(.planResult(nil))`
     - `fetchTravelPlanDetailEffect()`: `.run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase, id = state.id] send in ... }` → `try await travelPlanDetailUseCase.fetch(planId: id)` → `send(.travelPlanDetailResult(...))`, `catch`에서 `AppLogger.view.log(.error, "...")` 후 `send(.travelPlanDetailResult(nil))`
   - 파일 상단 헤더 주석을 "스켈레톤" → 실제 역할 설명으로 갱신

### Phase 5. Presentation - View

1. `Projects/Presentation/Sources/PlanDetail/PlanDetailView.swift` 수정
   - `@Bindable private var store: StoreOf<PlanDetailFeature>` + `@Environment(\.dismiss) private var dismiss`
   - **body 구성**
     - `plan`이 있으면 `VStack(alignment: .leading, spacing: 0)`으로 NavigationBar → 일자 탭 스크롤 → `Spacer()`
     - `plan`이 nil이면 `ProgressView()`만 (`isLoading` 여부와 무관하게 nil이면 콘텐츠 미렌더링 — spec의 불변 조건)
     - `.toolbar { ToolbarItem(placement: .topBarLeading) { 뒤로가기 Button } }` — `chevron.left` + `.tint(Color.getTabiColor(.tabiPrimary))`, 액션은 `self.dismiss()`
     - `.navigationBarBackButtonHidden(true)`
     - `.onAppear { self.store.send(.onAppear) }`
     - `body` 50줄 초과 시 `// MARK: - View` + `private extension`의 View 메서드로 분리 (`DetailView` / `PlanView` 패턴)
   - **NavigationBar 영역**
     - `TabiNavigationBar(subtitle: "\(plan.displayRegionTitle) · \(Strings.Plan.durationBadge(plan.dayCount))", title: plan.title)`
     - trailing 미사용(기본 `EmptyView`)
     - 배치 방식: 네이티브 toolbar가 이미 상단을 차지하므로 `.safeAreaBar(edge: .top)`가 아닌 **콘텐츠 최상단 배치**로 처리 (Home/Plan 등 탭 루트 화면과 달리 push된 화면이라는 점이 차이)
   - **일자 탭 영역**
     - `ScrollView(.horizontal)` + `.scrollIndicators(.hidden)` + `HStack(spacing: 8)` (`PlanCardView`의 칩 스크롤 패턴 동일)
     - `ForEach(Array(plan.dayDates.enumerated()), id: \.offset)`으로 순회
     - 각 항목에 `PlanDetailDayButton(일차: Strings.Plan.dayChipTitle(offset + 1), 날짜: date.planDayDateTitle, isSelected: store.selectedDayIndex == offset) { store.send(.dayButtonTapped(index: offset)) }`
     - 좌우 여백은 `TabiNavigationBar`의 `.padding(.horizontal, 20)`과 시각적으로 맞춤 (스크롤 클리핑을 피하려면 `HStack`에 padding, `ScrollView`에는 미적용)
   - **`#Preview` 추가 (선택)**
     - `TestTravelPlanUseCase`에 `plans`를 주입하고, `PlanDetailFeature.State(id:)`에 **동일한 id**를 넘겨야 화면이 그려진다는 점 주의
     - `withDependencies: { $0.travelPlanUseCase = mockUseCase }` (`DetailView` Preview 패턴)

### Phase 6. 프로젝트 생성 및 빌드 검증

1. `tuist generate` — `PlanDetailDayButton.swift` 및 TravelPlanDetail 스캐폴딩 신규 파일들 추가로 **필수** (미실행 시 stale 프로젝트로 오탐 에러)
2. `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
   - iPhone 16 Pro 시뮬레이터 설치 확인됨 (CLAUDE.md 기본 명령 그대로 사용 가능)
3. 시뮬레이터 수동 확인: Plan 탭 → 일정 셀 탭 → 상세 진입 → 일자 pill 탭 전환 → 뒤로가기 복귀

---

## 리스크 / 확인 필요

- **`TabiNavigationBar`는 subtitle을 title 위에 렌더링한다** (`VStack(alignment: .leading, spacing: 5)` → subtitle `bodyMBold` → title `titleL`). 따라서 "지역 · N日間"이 일정 제목 **위**에 표시된다. `HomeView`(날짜 위 / 앱명 아래)와 동일한 기존 시각 언어이므로 그대로 수용하되, 디자인 의도가 "제목 아래 서브텍스트"라면 `TabiNavigationBar` 수정이 필요해 spec 제약(확장 금지)과 충돌한다 — **구현 착수 전 확인 필요**
- **일정 제목이 길 경우** `titleL`(26pt)로 2~3줄까지 늘어나 일자 탭이 아래로 밀릴 수 있다. `TabiLabel`의 줄 수 제한 동작 확인 후 필요 시 View 단에서 `lineLimit` 처리 여부 판단
- `onAppear`는 화면 복귀 시 재호출된다. 재조회 자체는 의도된 동작이지만, 로딩 플리커 방지 로직(`plan == nil`일 때만 `isLoading = true`)이 빠지면 깜빡임이 발생한다
- 장기 일정(예: 30일)이면 pill이 매우 많아진다. 선택 항목 자동 스크롤(`ScrollViewReader`)은 이번 범위에 없으므로, 우측 끝 날짜 선택 후 복귀 시 스크롤 위치가 초기화될 수 있다 — 문제가 되면 후속 작업으로 분리
- `TabBarFeature`는 `case .path: return .none` fallthrough를 갖고 있어 `PlanDetailFeature`의 새 Action이 상위로 새어나가도 무해하다. 다만 새 Action 추가로 `StackPath.Action: Equatable` 합성이 깨지지 않는지 빌드로 확인
- `tuist generate`를 건너뛰면 신규 파일들(`PlanDetailDayButton`, `TravelPlanDetail`, `TravelPlanDetailUseCase` 등)이 "Cannot find ... in scope" 오탐을 낸다 — 신규 파일 수가 많아 특히 주의
- **`TravelPlanDetail` 스캐폴딩은 이번 화면에서 시각적으로 검증 불가**: UI에 렌더링하지 않으므로 `fetch(planId:)`가 정상 호출됐는지는 로그/브레이크포인트 또는 후속 `TravelPlanDetailUseCase` 유닛 테스트로만 확인 가능하다. 현재 어떤 플로우도 `add(_:)`를 호출하지 않아 실제 조회 결과는 항상 `nil`이며, 이는 의도된 정상 동작이다
- Domain에 `Entity`/`RepositoryProtocol`/`UseCase` 3개, `Dependency/Keys` 1개, Data에 `Repository`/`Extension` 2개, App에 `Dependency` 1개 — 총 7개 신규 파일이 `PlanDetailDayButton.swift`와 별개로 추가된다. Tuist 타겟 여러 개(Domain/Data/App)에 걸쳐 파일이 추가되므로 `tuist generate` 후 각 모듈 빌드를 개별적으로도 확인

---

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
- [ ] PlanView에서 일정 Cell 탭 → PlanDetail 진입 시 title / "지역 · N日間"이 NavigationBar에 표시된다
- [ ] 뒤로가기(`chevron.left`) 탭 시 PlanView로 복귀한다
- [ ] `dayCount`만큼 pill이 가로 스크롤로 표시되고 각 항목에 "N日目" + "M月d日"가 2줄로 표시된다
- [ ] pill 탭 시 `selectedDayIndex`가 갱신되고 선택 스타일이 전환된다
- [ ] 존재하지 않는 id로 진입해도 크래시 없이 로딩이 해제되고 `AppLogger.view`에 에러가 남는다
- [ ] 일자 탭 아래에는 어떤 일정 표시 View도 추가되지 않았다 (Spacer 여백만)
- [ ] 기존 `TravelPlanUseCaseProtocol` / `TravelPlanRepositoryProtocol` 시그니처에는 변경이 없다 (fetch/add 그대로)
- [ ] `TravelPlanDetail` Domain(Entity/RepositoryProtocol/UseCase/testValue) + Data(Repository/Model 확장) + App(liveValue) 계층이 `TravelPlan`과 동일한 패턴으로 구성되어 있다
- [ ] `PlanDetailFeature.onAppear`에서 `travelPlanDetailUseCase.fetch(planId:)`가 호출되고 결과가 `State.travelPlanDetail`에 저장된다 (UI 미노출)
- [ ] `tuist generate` 후 AppDebug 스킴 빌드 성공

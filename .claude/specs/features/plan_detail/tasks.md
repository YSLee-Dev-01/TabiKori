# Tasks: plan_detail

## 참조
- spec: `.claude/specs/features/plan_detail/spec.md`
- plan: `.claude/specs/features/plan_detail/plan.md`

## Task 목록

### Phase 1. Presentation - Model / Extension

#### [x] Task 1 — `Date+.swift` (수정)
**파일**: `Projects/Presentation/Sources/Extension/Date+.swift`
- 요일 없는 `M月d日` 포맷 계산 프로퍼티 추가 (이름 예: `planDayDateTitle`)
- 기존 프로퍼티(`homeDateTitle` 등)와 동일하게 `DateFormatter` + `Locale(identifier: "ja_JP")` 사용
- 기존 `homeDateTitle`("M月d日(E)")과 포맷이 유사하지만 요일 유무가 달라 재사용 불가 — 별도 프로퍼티로 신규 추가 (기존 프로퍼티 삭제/변경 금지)
- 강제 언래핑(`!`) 금지, DateFormatter는 static 상수 또는 계산 시 생성 등 기존 파일의 관용구 준수

---

#### [x] Task 2 — `TravelPlan+.swift` (수정)
**파일**: `Projects/Presentation/Sources/Plan/Model/TravelPlan+.swift`
- `var dayDates: [Date]` 계산 프로퍼티 추가
- 구현 방향: `Calendar.current.startOfDay(for: startDate)`를 기준점으로 `0..<dayCount`만큼 `date(byAdding: .day, value:)` 수행, 실패 값은 `compactMap`으로 제외
- 반드시 기존 `dayCount`를 기반으로 생성해 `dayDates.count == dayCount`가 구조적으로 보장되도록 구현 (별도 로직으로 독립 계산 금지)
- 강제 언래핑(`!`) 금지 (`swift-style.md` 4번)

---

### Phase 2. Presentation - Sub 컴포넌트

#### [x] Task 3 — `PlanDetailDayButton.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailDayButton.swift`
- `Sub/` 폴더 신규 생성 필요
- 입력 파라미터: 일차 타이틀(String), 날짜 타이틀(String), `isSelected: Bool`, `action: () -> Void`
- 레이아웃: `VStack(spacing:)` 2줄 구성 — 상단 일차("N日目", `captionMBold` 계열), 하단 날짜("M月d日", `captionM` 계열), `TabiLabel` 사용
- 선택 스타일: 배경 `tabiPrimary` / 텍스트 `tabiOnColor`
- 비선택 스타일: 배경 `tabiSurface` + `Capsule().stroke(tabiBorder)` / 텍스트 `tabiTextSecondary`
- `Capsule()`로 클리핑, `Button` + `.buttonStyle(.plain)` (`TabiChip`과 동일한 pill 단독 탭 감각)
- `.animation(.tabiFast, value: isSelected)`로 색상 전환 애니메이션 적용
- 접근 제어: internal (모듈 외부 노출 불필요, `swift-style.md` 7번)
- 폰트/색/애니메이션은 전부 DesignSystem 토큰 재사용, 직접 `Font`/`Color` 리터럴 생성 금지

---

### Phase 3. Domain / Data / App - TravelPlanDetail 스캐폴딩

> `TravelPlan`과 동일한 계층 패턴(Entity → RepositoryProtocol → UseCase → testValue/liveValue)으로 구성. 이번 화면 UI에서는 사용하지 않지만 추후 "일정을 보여주는 View" 기능이 이어받을 수 있도록 미리 배선한다.

#### [x] Task 4 — `TravelPlanDetail.swift` (신규, Domain Entity)
**파일**: `Projects/Domain/Sources/Entity/TravelPlanDetail.swift`
- `public struct TravelPlanDetail: Equatable, Sendable`
- `public let planId: UUID` 프로퍼티 1개만 보유 (현재 `TravelPlanDetailModel`과 1:1 매핑)
- `public init(planId: UUID)` 명시적 정의

---

#### [x] Task 5 — `TravelPlanDetailRepositoryProtocol.swift` (신규, Domain)
**파일**: `Projects/Domain/Sources/RepositoryProtocol/TravelPlanDetailRepositoryProtocol.swift`
- 선행 Task: Task 4 (`TravelPlanDetail` Entity)
- `func fetch(planId: UUID) async throws -> TravelPlanDetail?`
- `func add(_ detail: TravelPlanDetail) async throws`
- `fetchOrCreate`/upsert류 메서드 추가 금지 (spec 제약)

---

#### [x] Task 6 — `TravelPlanDetailUseCaseProtocol.swift` (신규, Domain)
**파일**: `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCaseProtocol.swift`
- 선행 Task: Task 4, Task 5
- `UseCase/TravelPlanDetail/` 폴더 신규 생성
- Repository와 동일한 시그니처 2개: `fetch(planId: UUID) async throws -> TravelPlanDetail?`, `add(_ detail: TravelPlanDetail) async throws`

---

#### [x] Task 7 — `TravelPlanDetailUseCase.swift` (신규, Domain)
**파일**: `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCase.swift`
- 선행 Task: Task 5, Task 6
- `TravelPlanUseCase`와 동일하게 `TravelPlanDetailRepositoryProtocol`을 위임 호출만 하는 `final class`
- Domain은 Data를 참조하지 않으므로 생성자에는 프로토콜 타입만 주입

---

#### [x] Task 8 — `TestTravelPlanDetailUseCase.swift` (신규, Domain)
**파일**: `Projects/Domain/Sources/UseCase/TravelPlanDetail/TestTravelPlanDetailUseCase.swift`
- 선행 Task: Task 6
- `test-style.md` 3번 규칙 준수: `Test` 접두사, 프로토콜 채택, `@unchecked Sendable`
- `public var details: [TravelPlanDetail] = []` 공개 프로퍼티로 데이터 주입 지원
- `fetch(planId:)`는 `details.first(where: { $0.planId == planId })` 반환
- `add(_:)`는 `details.append(detail)`

---

#### [x] Task 9 — `TravelPlanDetailUseCaseDependencyKey.swift` (신규, Domain)
**파일**: `Projects/Domain/Sources/Dependency/Keys/TravelPlanDetailUseCaseDependencyKey.swift`
- 선행 Task: Task 8
- `TestDependencyKey` 채택, `Sendable`
- `public static var testValue: TravelPlanDetailUseCaseProtocol { TestTravelPlanDetailUseCase() }`만 정의 (`liveValue`는 App 레이어에서 별도 정의)

---

#### [x] Task 10 — `DependencyValues.swift` (수정, Domain)
**파일**: `Projects/Domain/Sources/Dependency/DependencyValues.swift`
- 선행 Task: Task 6, Task 9
- 기존 `travelPlanUseCase` 프로퍼티 확장 바로 아래에 `travelPlanDetailUseCase: TravelPlanDetailUseCaseProtocol` get/set 프로퍼티 확장 추가
- 기존 다른 프로퍼티 확장은 변경하지 않음

---

#### [x] Task 11 — `TravelPlanDetailModel+.swift` (신규, Data)
**파일**: `Projects/Data/Sources/Extension/TravelPlanDetailModel+.swift`
- 선행 Task: Task 4
- 기존 `TravelPlanDetailModel`(SwiftData, `planId: UUID`만 보유)을 대상으로 확장 작성
- `toDomain: TravelPlanDetail` — region 파싱 등 실패 가능성이 없으므로 `TravelPlanModel.toDomain`과 달리 non-optional로 구현
- `convenience init(detail: TravelPlanDetail)` 추가

---

#### [x] Task 12 — `TravelPlanDetailRepository.swift` (신규, Data)
**파일**: `Projects/Data/Sources/Repository/TravelPlanDetail/TravelPlanDetailRepository.swift`
- 선행 Task: Task 5, Task 11
- `TravelPlanDetailRepositoryProtocol` 채택 (프로토콜 채택은 별도 extension으로 분리, `swift-style.md` 3번)
- `TravelPlanRepository`와 동일하게 `modelContainer: ModelContainer = TravelPlanModelContainer.shared.modelContainer` 기본값 사용 (Schema에 `TravelPlanDetailModel`이 이미 등록되어 있어 컨테이너 자체 변경 불필요)
- `fetch(planId:)`: `FetchDescriptor<TravelPlanDetailModel>(predicate: #Predicate { $0.planId == planId })` → `.first?.toDomain` 반환
- `add(_:)`: `TravelPlanDetailModel(detail:)` 생성 → `context.insert` → `context.save()`
- 에러 발생 시 `AppLogger.core.log(.error, ...)` 로깅 후 `TabiError.persistenceFailed`로 매핑 (`TravelPlanRepository`와 동일 패턴)

---

#### [x] Task 13 — `TravelPlanDetailUseCaseDependencyKey.swift` (신규, App)
**파일**: `Projects/App/Sources/Dependency/TravelPlanDetailUseCaseDependencyKey.swift`
- 선행 Task: Task 9, Task 12
- `extension TravelPlanDetailUseCaseDependencyKey: @retroactive DependencyKey`
- `public static var liveValue: TravelPlanDetailUseCaseProtocol { TravelPlanDetailUseCase(repository: TravelPlanDetailRepository()) }`
- 실제 구현체 조립(Repository 주입)은 App 레이어에서만 수행 — Domain은 Data를 참조하지 않음

---

### Phase 4. Presentation - Feature

#### [x] Task 14 — `PlanDetailFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/PlanDetail/PlanDetailFeature.swift`
- 선행 Task: Task 2, Task 10 (DependencyValues에 `travelPlanDetailUseCase` 등록 완료 후 진행)
- 현재 `Action`이 빈 enum(`public enum Action: Equatable {}`)이고 body가 `Reduce { _, _ in .none }`인 스켈레톤 상태이므로 전면 재작성
- `import Core`, `import Domain`, `import ComposableArchitecture` 추가
- `@Dependency(\.travelPlanUseCase) var travelPlanUseCase`, `@Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase` 추가

**State** (선언 순서: 공개 프로퍼티 → fileprivate → @Presents, `swift-style.md` 5번)
- 기존 `let id: UUID` 유지 — `init(id:)` 시그니처 변경 금지 (`TabBarFeature`가 이미 이 시그니처로 호출 중)
- `var plan: TravelPlan?` (초기 nil)
- `var travelPlanDetail: TravelPlanDetail?` (초기 nil, View에서는 사용하지 않음)
- `var selectedDayIndex: Int = 0`
- `var isLoading: Bool = false`

**Action** (선언 순서: 바인딩 → 생명주기 → 인터랙션 → 비동기 결과 → 하위, `swift-style.md` 5번)
- `case onAppear`
- `case dayButtonTapped(index: Int)`
- `case planResult(TravelPlan?)`
- `case travelPlanDetailResult(TravelPlanDetail?)`
- `Equatable` 채택 유지 (`TravelPlan`/`TravelPlanDetail` 모두 `Equatable`이므로 문제 없음, `StackPath.Action: Equatable` 합성 충족 확인)

**body**
- `onAppear`: `state.plan == nil`일 때만 `isLoading = true` 세팅 후 `fetchPlanEffect()`와 `fetchTravelPlanDetailEffect()`를 `.merge`로 함께 반환 (두 조회는 서로 독립적이므로 순차 대기 불필요)
- `dayButtonTapped(index:)`: `state.selectedDayIndex = index` 갱신 후 `.none`
- `planResult(plan)`: `state.plan = plan`, `state.isLoading = false`, `selectedDayIndex`를 `0..<dayCount` 범위로 클램프
- `travelPlanDetailResult(detail)`: `state.travelPlanDetail = detail` (성공/nil 무관하게 그대로 저장, 화면 동작에는 영향 없음)

**조회 Effect** (`// MARK: - Method` + `private extension`으로 분리, `PlanFeature.fetchPlansEffect()`와 동일 구조)
- `fetchPlanEffect()`: `.run { [travelPlanUseCase = self.travelPlanUseCase, id = state.id] send in ... }` → `try await travelPlanUseCase.fetch()` → `.first(where: { $0.id == id })` → `send(.planResult(...))`; `catch`에서 `AppLogger.view.log(.error, ...)` 후 `send(.planResult(nil))`
- `fetchTravelPlanDetailEffect()`: `.run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase, id = state.id] send in ... }` → `try await travelPlanDetailUseCase.fetch(planId: id)` → `send(.travelPlanDetailResult(...))`; `catch`에서 `AppLogger.view.log(.error, ...)` 후 `send(.travelPlanDetailResult(nil))`

- 파일 상단 헤더 주석을 "스켈레톤" 설명에서 실제 역할 설명으로 갱신

---

### Phase 5. Presentation - View

#### [x] Task 15 — `PlanDetailView.swift` (수정)
**파일**: `Projects/Presentation/Sources/PlanDetail/PlanDetailView.swift`
- 선행 Task: Task 3 (`PlanDetailDayButton`), Task 14 (`PlanDetailFeature`)
- 현재 `TabiLabel(title: Strings.Plan.title)` 한 줄짜리 스켈레톤 → NavigationBar + 일자 탭 스크롤 + 뒤로가기 toolbar 구성으로 전면 교체
- `@Bindable private var store: StoreOf<PlanDetailFeature>`, `@Environment(\.dismiss) private var dismiss` 추가

**body 구성**
- `plan`이 있으면: `VStack(alignment: .leading, spacing: 0)`으로 NavigationBar 영역 → 일자 탭 스크롤 영역 → `Spacer()` (일정 표시 View는 이번 범위에서 완전히 제외)
- `plan`이 nil이면: `ProgressView()`만 노출 (`isLoading` 값과 무관하게 `plan == nil`이면 콘텐츠 미렌더링 — spec의 불변 조건). `PlanView.planList()`의 `ProgressView().frame(maxWidth: .infinity)` 패턴 재사용
- `.toolbar { ToolbarItem(placement: .topBarLeading) { ... } }` — `chevron.left` 아이콘 + `.tint(Color.getTabiColor(.tabiPrimary))`, 액션은 `self.dismiss()` (`DetailView`의 기존 뒤로가기 패턴 그대로 재사용)
- `.navigationBarBackButtonHidden(true)` 적용
- `.onAppear { self.store.send(.onAppear) }`
- `body`가 50줄을 초과하면 `// MARK: - View` + `private extension`의 서브 View 메서드로 분리 (`DetailView`/`PlanView` 패턴, `swift-style.md` 6번)

**NavigationBar 영역**
- `TabiNavigationBar(subtitle: "\(plan.displayRegionTitle) · \(Strings.Plan.durationBadge(plan.dayCount))", title: plan.title)`
- trailing 미사용(기본 `EmptyView()`)
- 네이티브 toolbar가 이미 상단을 차지하므로 `.safeAreaBar(edge: .top)`가 아닌 콘텐츠 최상단 배치로 처리 (Home/Plan 등 탭 루트 화면과 달리 push된 화면이라는 차이)

**일자 탭 영역**
- `ScrollView(.horizontal)` + `.scrollIndicators(.hidden)` + `HStack(spacing: 8)` (`PlanCardView`의 칩 스크롤 패턴과 동일)
- `ForEach(Array(plan.dayDates.enumerated()), id: \.offset)`으로 순회
- 각 항목에 `PlanDetailDayButton(일차: Strings.Plan.dayChipTitle(offset + 1), 날짜: date.planDayDateTitle, isSelected: store.selectedDayIndex == offset) { store.send(.dayButtonTapped(index: offset)) }`
- 좌우 여백은 `TabiNavigationBar`의 `.padding(.horizontal, 20)`과 시각적으로 맞춤 (스크롤 클리핑을 피하기 위해 `HStack`에 padding 적용, `ScrollView` 자체에는 미적용)

**`#Preview` 추가 (선택)**
- `TestTravelPlanUseCase`에 `plans`를 주입하고, `PlanDetailFeature.State(id:)`에 동일한 id를 넘겨야 화면이 그려짐에 주의
- `withDependencies: { $0.travelPlanUseCase = mockUseCase }` (`DetailView` Preview 패턴 재사용)

---

### Phase 6. 프로젝트 생성 및 빌드 검증

#### [x] Task 16 — Tuist 프로젝트 재생성
**대상**: 전체 프로젝트 (`Tabikori.xcworkspace`)
- 선행 Task: Task 1 ~ Task 15 전체 완료 후 진행
- `tuist install` 실행 (필요 시)
- `tuist generate` 실행 — `PlanDetailDayButton.swift` 및 TravelPlanDetail 스캐폴딩 신규 파일들(Domain 3개, Data 2개, App 1개) 추가로 필수. 미실행 시 stale 프로젝트로 "Cannot find ... in scope" 오탐 에러 발생

---

#### [x] Task 17 — 빌드 및 수동 동작 확인
**대상**: `AppDebug` 스킴
- 선행 Task: Task 16
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` 실행, 빌드 성공 확인
- Domain/Data/App 등 여러 타겟에 걸쳐 신규 파일이 추가되었으므로 빌드 에러 발생 시 어느 모듈인지 구분해 확인
- 시뮬레이터 수동 확인: Plan 탭 → 일정 셀 탭 → PlanDetail 진입 → title/지역/기간이 NavigationBar에 표시되는지 확인 → 일자 pill 탭하여 선택 스타일 전환 확인 → 뒤로가기(`chevron.left`) 탭하여 PlanView로 정상 복귀하는지 확인
- 존재하지 않는 id 시나리오는 코드 경로로 로깅 확인(`AppLogger.view`)만 가능하며, 별도 에러 UI가 없다는 점 재확인

---

## 체크리스트

### 품질 (DoD)
- [ ] `tuist generate` 후 `AppDebug` 스킴 빌드 성공
- [ ] 기존 `TravelPlanUseCaseProtocol` / `TravelPlanRepositoryProtocol` 시그니처 변경 없음 (fetch/add 그대로)
- [ ] `PlanDetailFeature.State(id:)` 이니셜라이저 시그니처 변경 없음 (`TabBarFeature` 호출부 영향 없음)
- [ ] 강제 언래핑(`!`) 미사용, DesignSystem 토큰(Color/Font/Animation) 재사용 (직접 리터럴 생성 없음)
- [ ] `swift-style.md`의 MARK 섹션 순서, 접근 제어 원칙 준수

### 기능 (AC)
- [ ] PlanView에서 일정 Cell 탭 → PlanDetail 진입 시 해당 일정의 title/region/기간이 NavigationBar에 정상 표시된다
- [ ] 뒤로가기 버튼 탭 시 PlanView로 정상 복귀한다
- [ ] `dayCount`만큼 일자 탭 버튼이 가로 스크롤로 표시되고 각 버튼에 "N日目"+날짜가 2줄로 표시된다
- [ ] 일자 탭 버튼 탭 시 `selectedDayIndex`가 갱신되고 선택 스타일(강조 색상)이 전환된다
- [ ] 존재하지 않는 id로 진입해도 크래시 없이 로딩 상태가 해제된다 (에러는 AppLogger로 로깅)
- [ ] `travelPlanDetailUseCase.fetch(planId:)`가 `onAppear`에서 호출되고, 결과 유무/에러와 무관하게 화면이 정상 표시된다 (UI 미노출)
- [ ] `tuist generate` 후 빌드 성공

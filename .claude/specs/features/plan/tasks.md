# Tasks: 여행 일정 플랜

## 참조
- spec: `.claude/specs/features/plan/spec.md`
- plan: `.claude/specs/features/plan/plan.md`

## Task 목록

### Phase 1. Domain

#### [x] Task 1 — `KoreanRegion.swift` (수정)
**파일**: `Projects/Domain/Sources/Entity/KoreanRegion.swift`
- `case etc` 추가 (연관값 없음, 기존 `String` raw value 유지)
- 연관값을 붙이면 `CaseIterable` 자동 합성이 깨지므로 절대 연관값 추가 금지
- 주의: 이 케이스 추가로 `Presentation/Sources/Home/Model/KoreanRegion+.swift`의 exhaustive switch(`jaTitle`/`koTitle`/`image`) 3곳이 즉시 컴파일 에러가 남 — Phase 4 Task 17에서 대응

---

#### [x] Task 2 — `TravelPlan.swift` (신규)
**파일**: `Projects/Domain/Sources/Entity/TravelPlan.swift`
- `public struct TravelPlan: Equatable, Identifiable, Sendable` 정의
- 프로퍼티: `id: UUID`(let), `title: String`, `region: KoreanRegion`, `customRegionText: String?`, `customEmoji: String?`, `startDate: Date`, `endDate: Date`
- 모듈 외부 생성이 필요하므로 `public init` 명시

---

#### [x] Task 3 — `TravelPlanRepositoryProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/RepositoryProtocol/TravelPlanRepositoryProtocol.swift`
- `Sendable` 채택 프로토콜 정의
- `fetch() async throws -> [TravelPlan]`
- `add(_ plan: TravelPlan) async throws`
- `remove(id:)`는 이번 범위에서 제외

---

#### [x] Task 4 — `TravelPlanUseCaseProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/TravelPlan/TravelPlanUseCaseProtocol.swift`
- Repository 프로토콜과 동일한 시그니처(`fetch()`, `add(_:)`)로 정의

---

#### [x] Task 5 — `TravelPlanUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/TravelPlan/TravelPlanUseCase.swift`
- `final class`, `TravelPlanUseCaseProtocol` 채택
- `private let repository: TravelPlanRepositoryProtocol` + `public init(repository:)`
- MARK 순서: Properties → Init → Method (`BookmarkUseCase`와 동일 구조 참고)

---

#### [x] Task 6 — `TestTravelPlanUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/TravelPlan/TestTravelPlanUseCase.swift`
- `public final class TestTravelPlanUseCase: TravelPlanUseCaseProtocol, @unchecked Sendable`
- 데이터 주입용 `public var plans: [TravelPlan] = []` 공개 프로퍼티

---

#### [x] Task 7 — `TravelPlanUseCaseDependencyKey.swift` (신규)
**파일**: `Projects/Domain/Sources/Dependency/Keys/TravelPlanUseCaseDependencyKey.swift`
- `TestDependencyKey` 채택
- `testValue`만 정의 (`TestTravelPlanUseCase()` 반환)

---

#### [x] Task 8 — `DependencyValues.swift` (수정)
**파일**: `Projects/Domain/Sources/Dependency/DependencyValues.swift`
- `public var travelPlanUseCase: TravelPlanUseCaseProtocol` get/set 프로퍼티 확장 추가

---

### Phase 2. Data

#### [x] Task 9 — `TravelPlanModel.swift` (신규)
**파일**: `Projects/Data/Sources/SwiftData/TravelPlanModel.swift`
- `@Model final class`
- 프로퍼티: `@Attribute(.unique) var id: UUID`, `title`, `regionRaw: String`, `customRegionText: String?`, `customEmoji: String?`, `startDate`, `endDate`
- 전체 인자 `init` 작성
- 접근 제어는 `BookmarkModel`과 동일하게 internal

---

#### [x] Task 10 — `TravelPlanDetailModel.swift` (신규, 스켈레톤)
**파일**: `Projects/Data/Sources/SwiftData/TravelPlanDetailModel.swift`
- `@Model final class`
- `@Attribute(.unique) var planId: UUID` + `init(planId:)`만 정의
- 상세 전용 필드는 절대 정의하지 않음(향후 Plan Detail 기능 작업 소관) — 스켈레톤만 생성

---

#### [x] Task 11 — `TravelPlanModelContainer.swift` (신규)
**파일**: `Projects/Data/Sources/SwiftData/TravelPlanModelContainer.swift`
- `public final class ... Sendable`, `public static let shared`, `private init`
- `Schema([TravelPlanModel.self, TravelPlanDetailModel.self])` — 두 모델 동시 등록 필수(향후 마이그레이션 없이 확장 가능하도록)
- 초기화 실패 시 `AppLogger.core.log(.error, ...)` 후 in-memory 폴백, 폴백까지 실패하면 `fatalError` (`BookmarkModelContainer` 패턴 동일)

---

#### [x] Task 12 — `TravelPlanModel+.swift` (신규)
**파일**: `Projects/Data/Sources/Extension/TravelPlanModel+.swift`
- `var toDomain: TravelPlan?` — `KoreanRegion(rawValue: regionRaw)` 복원 실패 시 `AppLogger.core` 로그 후 `nil` 반환
- `convenience init(plan: TravelPlan)` 작성
- DTO 없이 Model ↔ Entity 직접 변환 (`BookmarkModel+.swift` 패턴 준수)

---

#### [x] Task 13 — `TravelPlanRepository.swift` (신규)
**파일**: `Projects/Data/Sources/Repository/TravelPlan/TravelPlanRepository.swift`
- `public final class ... Sendable`, `private let modelContainer: ModelContainer`
- `public init(modelContainer: ModelContainer = TravelPlanModelContainer.shared.modelContainer)`
- 프로토콜 채택은 `// MARK: - TravelPlanRepositoryProtocol` extension으로 분리
- `fetch()`: 메서드 내부에서 `ModelContext(self.modelContainer)` 생성 → `FetchDescriptor<TravelPlanModel>(sortBy: [SortDescriptor(\.startDate, order: .forward)])` → `compactMap(\.toDomain)`
- `add(_:)`: context insert + save
- `ModelContext`는 `Sendable`이 아니므로 프로퍼티로 보관하지 않고 메서드마다 생성(`BookmarkRepository`와 동일 이유)
- 모든 메서드 `do/catch` → `AppLogger.core` 로그 후 `TabiError.persistenceFailed(message:)` throw

---

### Phase 3. DesignSystem

#### [x] Task 14 — `TabiRangeCalendar.swift` (신규)
**파일**: `Projects/DesignSystem/Sources/Calendar/TabiRangeCalendar.swift`
- 월 단위 그리드 + 요일 헤더 + 이전/다음 월 이동 UI
- 입력: 선택된 시작/종료일 바인딩(또는 값 + 콜백), 출력: 범위 확정 콜백
- 선택 규칙: 첫 탭 = 시작일, 두 번째 탭이 시작일 이후면 종료일 확정 / 이전이면 시작일 재설정 → 종료일 < 시작일을 UI 단에서 사전 차단
- 색상/서체/라운드는 기존 `TabiColor`, `TypographyStyle`, `TabiRadius`, `TabiAnimation` 재사용(신규 정의 금지)
- 주의: 네이티브 `DatePicker` 휠이 아닌 커스텀 월 그리드 컴포넌트이며 프로젝트 내 최초 도입 — 참고할 기존 코드 없음

---

#### [x] Task 15 — `TabiTextField.swift` (신규)
**파일**: `Projects/DesignSystem/Sources/Field/TabiTextField.swift`
- placeholder + `@Binding text` + 선택적 최대 글자수 파라미터(이모지 1자 제한용)
- 일정명 / 커스텀 지역명 / 이모지 입력 세 곳에서 공용으로 사용 가능한 형태로 설계
- 기존 `DesignSystem/Sources/SearchField/TabiSearchField.swift`는 검색 전용(돋보기/취소 등) 구성이라 폼 입력에 재사용 불가 확인됨 → 별도 제작 진행

---

#### [x] Task 16 — `Strings.swift` (수정)
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- `public enum Plan {}` 네임스페이스 추가 + `public extension Strings.Plan` 블록 신설
- 필요 문자열: 화면 타이틀, `+ 신규작성`, 섹션 헤더(진행중/다가오는/지난), `N일간` 배지, `N일차` 칩, `합계 0스팟`, `탭하여 상세를 표시`, 빈 상태 문구, 추가 화면 각 라벨/placeholder, 확인 버튼, 저장 실패 알림 문구
- 기존 파일 컨벤션 준수: 일본어 값 + 한국어 주석
- 파라미터가 있는 문자열(예: `N일간`, `N일차`)은 `nonisolated(unsafe) static let x: ((Int) -> String)` 클로저 형태로 작성(`Strings.Bookmark.savedCountTitle` 패턴 참고)

---

### Phase 4. Presentation

#### [x] Task 17 — `KoreanRegion+.swift` (수정)
**파일**: `Projects/Presentation/Sources/Home/Model/KoreanRegion+.swift`
- 주의: Task 1의 `KoreanRegion.etc` 추가로 `jaTitle` / `koTitle` / `image` exhaustive switch 3개가 컴파일 에러 상태 — 반드시 함께 수정
- `jaTitle` / `koTitle`에 `.etc` 케이스 대응 추가(`Strings.Region.etc*` 신설 필요)
- `image`의 `.etc` 처리 방침 확정 — 대응 에셋이 없으므로 반환 타입 옵셔널화 또는 대표 이미지 폴백 중 택1로 결정하고 근거를 코드에 남길 것
- 주의: `image` 반환 방식 변경은 `HomeView.swift:520`의 `regionCard(_:)` 호출부에 영향을 줄 수 있으므로, 현재 태스크와 무관한 홈 화면 동작이 바뀌지 않도록 확인 후 진행
- `emoji` 매핑 추가 — `.etc`는 `nil` 반환하여 `customEmoji` 입력을 유도
- `static let allItems`는 홈 화면 전용이므로 변경하지 않음(`.etc` 추가 금지) — 추가 화면 지역 그리드용 목록은 별도 상수로 분리

---

#### [x] Task 18 — `PlanSection.swift` (신규)
**파일**: `Projects/Presentation/Sources/Plan/Entity/PlanSection.swift`
- `ongoing` / `upcoming` / `past` 케이스 정의
- 각 케이스별 섹션 타이틀(Strings.Plan 참조) 제공

---

#### [x] Task 19 — `TravelPlan+.swift` (신규, 화면 전용 확장)
**파일**: `Projects/Presentation/Sources/Plan/Model/TravelPlan+.swift`
- `dayCount`(시작~종료 포함 일수) 계산 프로퍼티
- `dayChipTitles`(1일차~N일차 목록) 계산 프로퍼티
- `periodTitle`(시작일〜종료일 표기) 계산 프로퍼티
- `displayEmoji`(`customEmoji ?? region.emoji`) 계산 프로퍼티
- `displayRegionTitle`(`region == .etc`이면 `customRegionText` 사용) 계산 프로퍼티
- 오늘 날짜 기준 진행중/다가오는/지난 섹션 분류 헬퍼
- 날짜 포맷은 `Presentation/Sources/Extension/Date+.swift`에 추가(기존 `DateFormatter` + `ja_JP` locale 패턴 준수, 신규 포맷 로직 임의 작성 금지)

---

#### [x] Task 20 — `AddTravelPlanFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/AddTravelPlan/AddTravelPlanFeature.swift`
- State 선언 순서: 공개 프로퍼티(`title`, `selectedRegion`, `customRegionText`, `emojiText`, `startDate`, `endDate`) → fileprivate → `@Presents var alert: AlertState<Action.Alert>?`
- 저장 가능 여부는 State의 computed property `isConfirmEnabled`로 파생: 이름 비어있지 않음 && 지역 선택됨 && (`.etc`인 경우 `customRegionText` 비어있지 않음) && 시작·종료일 모두 선택됨
- Action 선언 순서: `binding` → 생명주기 → 사용자 인터랙션(`closeTapped`, `regionSelected`, `dateRangeSelected`, `confirmTapped`) → 비동기 결과(`saveResult`) → 하위(`alert`)
- body: `BindingReducer()` → `Reduce { ... }` → `.ifLet(\.$alert, action: \.alert)`
- 지역 선택 시 해당 지역의 기본 이모지를 `emojiText`에 자동 채움(사용자가 텍스트필드로 직접 타이핑해 오버라이드 가능)
- 저장 Effect는 `private extension`의 `saveEffect()`로 분리, `.run { [travelPlanUseCase = self.travelPlanUseCase] send in ... }` 형태로 의존성 값 캡처(TCA `.run` 예외 규칙 준수)
- 저장 실패 시 `AppLogger.view` 로그 + alert 표시
- 주의: `@Presents` / `AlertState` / `.ifLet(\.$alert, action:)`는 프로젝트 최초 도입 패턴(`RootFeature.tabBarState`가 유일한 `.ifLet` 참고 사례이나 Alert 용도는 아님) — 참고할 기존 Alert 코드가 없으므로 TCA 표준 패턴을 신중히 적용할 것

---

#### [x] Task 21 — `AddTravelPlanView.swift` + `Sub/` (신규)
**파일**: `Projects/Presentation/Sources/AddTravelPlan/AddTravelPlanView.swift`, `Projects/Presentation/Sources/AddTravelPlan/Sub/AddPlanRegionGridView.swift`, `Projects/Presentation/Sources/AddTravelPlan/Sub/AddPlanDateRangeView.swift`, `Projects/Presentation/Sources/AddTravelPlan/Sub/AddPlanBottomCTAView.swift`
- `AddTravelPlanView`: 시트 상단 드래그 핸들 + X 닫기 버튼(`closeTapped` 액션 연결)
- `AddPlanRegionGridView`: 2열 그리드로 지역 표시(이모지 + 라벨), `.etc` 선택 시 커스텀 지역명 입력용 `TabiTextField`(Task 15) 노출
- `AddPlanDateRangeView`: 출발/귀국 날짜 표시 필드 + `TabiRangeCalendar`(Task 14) 연동
- `AddPlanBottomCTAView`: `TabiButton(.primary, isExpanded: true)` 재사용(`DetailBottomCTAView` 컨셉 참고) + `.disabled(!isConfirmEnabled)` — `TabiButton`이 `@Environment(\.isEnabled)`로 0.5 opacity 처리하므로 비활성 스타일은 별도 구현 없이 자동 적용됨
- body가 50줄 초과하는 부분은 `private extension`의 View 메서드 또는 `Sub/`로 분리

---

#### [x] Task 22 — `PlanFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/Plan/PlanFeature.swift`
- State: `plans: [TravelPlan] = []`, `isLoading: Bool = false`, 섹션별 파생 computed property(`ongoingPlans`/`upcomingPlans`/`pastPlans`), `@Presents var addPlanState: AddTravelPlanFeature.State?`
- Action 선언 순서: 생명주기(`onAppear`) → 인터랙션(`addButtonTapped`, `planTapped(id: UUID)`) → 비동기 결과(`plansResult([TravelPlan])`) → 하위(`addPlan(PresentationAction<AddTravelPlanFeature.Action>)`)
- `addPlan(.presented(.saveResult(성공)))` 수신 시 `state.addPlanState = nil` 처리 + 목록 재조회 트리거
- body: `Reduce { ... }` → `.ifLet(\.$addPlanState, action: \.addPlan) { AddTravelPlanFeature() }`
- `planTapped`는 `.none` 반환 — 상위 `TabBarFeature`가 가로채 path push 처리(`BookmarkFeature.spotTapped`와 동일한 위임 패턴 준수)
- 조회 Effect는 `// MARK: - Method` `private extension`으로 분리

---

#### [x] Task 23 — `PlanView.swift` + `Sub/` (신규)
**파일**: `Projects/Presentation/Sources/Plan/PlanView.swift`, `Projects/Presentation/Sources/Plan/Sub/PlanCardView.swift`, `Projects/Presentation/Sources/Plan/Sub/PlanEmptyState.swift`
- `.safeAreaBar(edge: .top) { TabiNavigationBar(title:) { trailing 버튼 } }` (`BookmarkView` 패턴 참고)
- 섹션별 리스트 구성, 데이터 없는 섹션은 헤더 포함 렌더링 자체를 건너뜀
- 전체 목록이 비었을 때만 `PlanEmptyState`(`BookmarkEmptyState` 패턴 참고) 표시
- `.sheet(item: $store.scope(state: \.addPlanState, action: \.addPlan)) { AddTravelPlanView(store: $0) }` — 프로젝트 최초 `.sheet(item: $store.scope(...))` 도입이므로 신중히 적용
- `.onAppear { store.send(.onAppear) }`
- `PlanCardView`: `TabiCard`로 감싸고 상단 컬러 배너(이모지 + `N일간` 배지) / 일정 이름 + chevron / 핀 아이콘 + `도시 · 기간` / 일자 칩 행 / `합계 0스팟` + `탭하여 상세를 표시`
- 주의: 일자 칩(1일차~N일차)에 기존 `TabiChip`을 재사용할지 판단 필요 — `TabiChip`은 `action` 클로저가 필수 인자인데 일자 칩은 탭 대상이 아니므로, no-op 클로저로 그대로 재사용할지 표시 전용 변형 컴포넌트를 추가할지 구현 시 결정할 것

---

#### [x] Task 24 — `StackPath.swift` (수정)
**파일**: `Projects/Presentation/Sources/Navigation/StackPath.swift`
- Plan Detail push용 케이스 추가
- 주의: `PlanDetailFeature`가 이번 스펙 범위 밖이므로, 리듀서 없는 `@Reducer enum` 케이스는 컴파일되지 않는 제약이 있음
- 셀 탭 → `TravelPlan.id`(UUID) 전달 흐름을 우선 확보하는 것이 목적이므로, 실제 케이스 추가는 `PlanDetailFeature` 스켈레톤을 함께 만들지 여부를 구현 착수 시 결정
- Acceptance Criteria의 "id가 StackPath를 통해 전달되는 구조가 마련"을 충족하는 최소 형태를 선택할 것(예: 최소 스켈레톤 Feature 동반 추가 등)

---

#### [x] Task 25 — `TabBarFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
- 임시 `PlanState` 구조체(라인 25 부근) 삭제 — 탭 3번째 슬롯을 채우기 위한 플레이스홀더였고 실제 `PlanFeature.State`가 생기면 존재 이유가 사라짐
- `var planState: PlanFeature.State = .init()`로 교체
- `Action`에 `case plan(PlanFeature.Action)` 추가
- body 상단에 `Scope(state: \.planState, action: \.plan) { PlanFeature() }` 추가
- `case .plan(.planTapped(let id)):`에서 path push 처리(Task 24의 StackPath 케이스로), `case .plan: return .none` fallthrough 추가

---

#### [x] Task 26 — `TabBarView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarView.swift`
- `Text(AppTab.plan.title)` 플레이스홀더를 `PlanView(store: self.store.scope(state: \.planState, action: \.plan))`로 교체
- `.tabItem`은 Image only 유지 — 텍스트(Label) 임의 추가 절대 금지
- `destination:` switch에 Task 24에서 추가된 새 `StackPath` 케이스가 있으면 함께 대응 처리

---

### Phase 5. App (DI)

#### [x] Task 27 — `TravelPlanUseCaseDependencyKey.swift` (신규, liveValue)
**파일**: `Projects/App/Sources/Dependency/TravelPlanUseCaseDependencyKey.swift`
- `extension TravelPlanUseCaseDependencyKey: @retroactive DependencyKey`
- `liveValue: TravelPlanUseCaseProtocol { TravelPlanUseCase(repository: TravelPlanRepository()) }`

---

### Phase 6. 프로젝트 생성 및 빌드 검증

#### [x] Task 28 — Tuist 프로젝트 재생성
- 신규 `.swift` 파일이 다수 추가되었으므로 `tuist install && tuist generate` 실행 필수
- 미실행 시 stale 프로젝트로 인한 오탐 빌드 에러 발생

---

#### [x] Task 29 — 빌드 검증
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` 실행
- iPhone 16 Pro 시뮬레이터가 미설치 상태이므로 destination은 iPhone 17 사용
- 빌드 성공 여부 확인

---

## 체크리스트

### 품질 (DoD)
- [x] 빌드 성공
- [ ] 테스트 통과 (테스트 타겟 미구성 상태이므로 해당 없음 — 추가 시 `.claude/rules/test-style.md` 준수)

### 기능 (AC)
- [ ] 탭바 3번째 탭 진입 시 일정 목록이 진행중 → 다가오는 → 지난 순서로 섹션 표시된다
- [ ] 각 카드에 이모지(도시 기본값 또는 커스텀), 기간 배지, 일정 이름, "도시 · 시작일〜종료일", 일자 칩(1일차~N일차), "합계 0스팟" 고정 텍스트가 표시된다
- [ ] 데이터가 없는 섹션은 화면에서 숨겨진다
- [ ] NavigationBar의 + 버튼으로 일정 추가 화면이 `.sheet` 모달로 표시된다
- [ ] 추가 화면에서 이름 / 도시(기타 직접입력 포함) / 이모지(도시 기본값 자동 지정 + 텍스트필드로 직접 타이핑 가능) / 기간(인라인 캘린더 범위 선택)을 입력하고 확인 버튼으로 저장할 수 있다
- [ ] 필수값 미입력 시 확인 버튼이 비활성화된다
- [ ] 저장된 일정은 SwiftData에 영속화되어 앱 재시작 후에도 유지된다
- [ ] 셀 탭 시 `TravelPlan.id`(UUID)가 `StackPath`를 통해 전달되는 구조가 마련되어 있다 (Detail 화면 자체는 미구현)
- [ ] `TravelPlanDetailModel` 스켈레톤(`planId` 연동 키만 보유)이 생성되어 있다

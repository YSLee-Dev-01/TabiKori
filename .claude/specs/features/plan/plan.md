# Plan: 여행 일정 플랜

## 참조 Spec
- @.claude/specs/features/plan/spec.md

## 참조 Skill
- 해당 프로젝트에 `create-feature` 스킬 없음 — 신규 화면은 기존 `Bookmark` 기능(Feature/View/Sub, Repository, UseCase, DependencyKey)의 파일 구성을 레퍼런스로 삼는다.

---

## 현재 상태 파악

### 신규

**Domain**
- `Projects/Domain/Sources/Entity/TravelPlan.swift` — 일정 엔티티
- `Projects/Domain/Sources/RepositoryProtocol/TravelPlanRepositoryProtocol.swift`
- `Projects/Domain/Sources/UseCase/TravelPlan/TravelPlanUseCase.swift`
- `Projects/Domain/Sources/UseCase/TravelPlan/TravelPlanUseCaseProtocol.swift`
- `Projects/Domain/Sources/UseCase/TravelPlan/TestTravelPlanUseCase.swift`
- `Projects/Domain/Sources/Dependency/Keys/TravelPlanUseCaseDependencyKey.swift`

**Data**
- `Projects/Data/Sources/SwiftData/TravelPlanModel.swift`
- `Projects/Data/Sources/SwiftData/TravelPlanDetailModel.swift` (스켈레톤)
- `Projects/Data/Sources/SwiftData/TravelPlanModelContainer.swift`
- `Projects/Data/Sources/Extension/TravelPlanModel+.swift` — Model ↔ Entity 변환 (`BookmarkModel+.swift` 패턴)
- `Projects/Data/Sources/Repository/TravelPlan/TravelPlanRepository.swift`

**DesignSystem**
- `Projects/DesignSystem/Sources/Calendar/TabiRangeCalendar.swift` — 월 그리드 + 범위 선택 인라인 캘린더 (프로젝트 최초 도입)
- `Projects/DesignSystem/Sources/Field/TabiTextField.swift` — 일정명/커스텀 지역명/이모지 공용 입력 필드
  - 확인: `DesignSystem/Sources/SearchField/TabiSearchField.swift`는 검색 전용(돋보기/취소 등) 구성이라 폼 입력에 재사용 부적합 → 별도 제작

**Presentation**
- `Projects/Presentation/Sources/Plan/PlanFeature.swift`
- `Projects/Presentation/Sources/Plan/PlanView.swift`
- `Projects/Presentation/Sources/Plan/Sub/PlanCardView.swift` — 카드 셀(배너/이름/위치·기간/일자 칩/하단 행)
- `Projects/Presentation/Sources/Plan/Sub/PlanEmptyState.swift` — `BookmarkEmptyState` 패턴
- `Projects/Presentation/Sources/Plan/Model/TravelPlan+.swift` — 일수 계산, 일자 칩 목록, 기간 표기 등 화면 전용 파생값
- `Projects/Presentation/Sources/Plan/Entity/PlanSection.swift` — 진행중/다가오는/지난 섹션 구분 타입
- `Projects/Presentation/Sources/AddTravelPlan/AddTravelPlanFeature.swift`
- `Projects/Presentation/Sources/AddTravelPlan/AddTravelPlanView.swift`
- `Projects/Presentation/Sources/AddTravelPlan/Sub/AddPlanRegionGridView.swift`
- `Projects/Presentation/Sources/AddTravelPlan/Sub/AddPlanDateRangeView.swift`
- `Projects/Presentation/Sources/AddTravelPlan/Sub/AddPlanBottomCTAView.swift` — `DetailBottomCTAView` 컨셉 참고

**App**
- `Projects/App/Sources/Dependency/TravelPlanUseCaseDependencyKey.swift` — `liveValue`

### 재사용
- `DesignSystem`: `TabiNavigationBar`(trailing ViewBuilder 슬롯 보유 → `+ 신규작성` 버튼 그대로 주입 가능), `TabiButton`(`.primary`, `isExpanded: true`, `height: 45`), `TabiCard`(카드 배경/보더), `TabiChip`(일자 칩 — 단, 탭 액션이 필수 인자이므로 no-op 클로저 사용 여부는 구현 시 판단), `TabiLabel`, `TabiTag`, `TabiPressStyle`, `TabiRadius`, `TabiAnimation`
- `Core`: `AppLogger.core`(Repository), `AppLogger.view`(Feature)
- `Domain`: `TabiError.persistenceFailed`
- `Data`: `BookmarkModelContainer` / `BookmarkRepository` 패턴(구조만 참조, 코드 공유 아님)
- `Presentation`: `Extension/Date+.swift`(날짜 포맷 헬퍼 추가 위치), `Home/Model/KoreanRegion+.swift`(지역 UI 매핑 확장 위치)

### 수정
- `Projects/Domain/Sources/Entity/KoreanRegion.swift` — `case etc` 추가
- `Projects/Presentation/Sources/Home/Model/KoreanRegion+.swift` — **`.etc` 추가 시 컴파일 에러 발생 지점**. `jaTitle` / `koTitle` / `image` 세 개의 switch가 전부 exhaustive → `.etc` 케이스 대응 필요. `image`는 대응 에셋이 없으므로 반환 타입/기본값 처리 방침을 구현 시 확정. `static let allItems`는 수동 배열이라 `.etc`를 넣지 않으면 홈 화면 지역 카드에는 영향 없음
- `Projects/Domain/Sources/Dependency/DependencyValues.swift` — `travelPlanUseCase` 프로퍼티 추가
- `Projects/Presentation/Sources/Navigation/StackPath.swift` — Plan Detail push용 케이스 자리 추가 (Detail Feature 미구현이므로 실제 케이스 추가 시점/형태는 Phase 4에서 판단, 아래 기술적 결정사항 참조)
- `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift` — 임시 `PlanState` 제거, `planState: PlanFeature.State`로 교체 + `Scope` 연결 + `Action.plan` 추가 + 셀 탭 → path push 처리
- `Projects/Presentation/Sources/Tabbar/TabBarView.swift` — `Text(AppTab.plan.title)` 플레이스홀더를 `PlanView(store:)`로 교체
- `Projects/Resource/Sources/Strings/Strings.swift` — `public enum Plan {}` 네임스페이스 및 문자열 추가 (일본어 표기, 기존 컨벤션 준수)

### 삭제
- `TabBarFeature.State.PlanState` 임시 구조체 (라인 25) — 탭 3번째 슬롯을 채우기 위한 플레이스홀더였고, 실제 `PlanFeature.State`가 생기면 존재 이유가 사라짐

---

## 기술적 결정사항

- **일정 추가 화면을 `.sheet` 모달로 표시**: 목록 → 추가는 되돌아오는 일회성 입력 플로우이고 저장 후 즉시 dismiss되어야 하므로, `NavigationStack` path에 push하면 탭 전환/뒤로가기와 얽힌다. `@Presents` + `.ifLet` + `.sheet(item:)` 조합으로 `PlanFeature`가 표시 수명을 소유한다. (대안: `StackPath` 케이스 추가 → 스택 상태 관리 복잡도만 증가)
- **이미지 대신 `customEmoji`**: PhotosPicker/파일 저장 없이 카드 시각 요소를 확보하기 위해 도시 기본 이모지 + 사용자 직접 입력 이모지로 대체. 저장 데이터가 `String?` 하나로 끝나 SwiftData 스키마와 마이그레이션이 단순해진다.
- **`KoreanRegion.etc`는 연관값 없음**: 연관값을 붙이면 `CaseIterable` 자동 합성이 깨진다(기술적 제약 확인됨). 실제 커스텀 지역명은 `TravelPlan.customRegionText`에 별도 보관해 enum을 순수 케이스 집합으로 유지한다.
- **지역별 기본 이모지 매핑은 Presentation 확장**: 이모지는 표현 계층 관심사이므로 Domain 엔티티가 아닌 `Presentation/Sources/Home/Model/KoreanRegion+.swift`의 `jaTitle`/`koTitle` 패턴을 따라 추가한다. (`folder-structure.md`의 "화면 전용 변환/헬퍼 타입" 규칙)
- **`TravelPlanModel` / `TravelPlanDetailModel` 분리**: 목록은 개요 필드만 필요하고 상세는 일자별 스팟 배정 등 향후 확장이 예정되어 있다. 한 모델에 몰면 목록 조회마다 불필요한 상세 데이터가 따라오고 이후 스키마 변경 폭도 커진다. 두 모델을 `id` ↔ `planId` 1:1로 연동하고, **지금 Schema에 함께 등록**해 나중에 마이그레이션 없이 확장할 수 있게 한다.
- **`TravelPlanDetailModel`은 스켈레톤만**: 상세 화면이 이번 범위 밖이라 필드를 지금 정의하면 근거 없는 추측이 된다. 연동 키(`planId`)만 두고 Repository/UseCase는 만들지 않는다.
- **셀 탭 시 엔티티 전체가 아닌 `TravelPlan.id`(UUID)만 전달**: List/Detail이 서로 다른 SwiftData 모델을 쓰므로, Detail은 넘겨받은 `id`로 각 Repository를 직접 조회하는 편이 데이터 정합성이 좋다(목록 스냅샷의 stale 값 전파 방지).
- **DTO 없이 Model ↔ Entity 직접 변환**: SwiftData는 네트워크 응답이 아니므로 `BookmarkModel+.swift`와 동일하게 중간 DTO를 두지 않는다.
- **`ModelContext`를 메서드마다 생성**: `BookmarkRepository`가 이미 이 방식이다. `ModelContext`는 `Sendable`이 아니라 프로퍼티로 보관하면 actor 경계를 넘길 수 없다.
- **`ModelContainer` 초기화 실패 시 in-memory 폴백**: `BookmarkModelContainer`와 동일. 앱이 크래시하는 대신 세션 한정으로 동작을 유지한다.
- **정렬 기준은 시작일 오름차순**: `FetchDescriptor(sortBy:)`에서 처리하고, 진행중/다가오는/지난 섹션 분류는 "오늘"이 필요한 화면 로직이므로 `PlanFeature`(또는 화면 전용 확장)에서 파생 계산한다.
- **"합계 0스팟"은 고정 텍스트**: 스팟 배정이 Detail 기능 소관이라 카운트 로직 자체를 만들지 않는다. 실제 값이 생기는 시점에 교체.
- **인라인 캘린더 신규 제작**: 네이티브 `DatePicker` 휠/그래픽 스타일로는 디자인의 월 그리드 범위 선택을 만들 수 없고, 종료일 < 시작일을 UI 차원에서 사전 차단하려면 선택 로직을 직접 통제해야 한다.
- **저장 실패 알림 방식**: 프로젝트에 `@Presents` / `AlertState` 사용 선례가 없다(`.ifLet` 사용처는 `RootFeature`의 `tabBarState` 하나뿐). 저장 실패 알림은 TCA 표준 `@Presents var alert: AlertState<Action.Alert>?` + `.ifLet(\.$alert, action: \.alert)`로 새로 도입하며, 이 패턴이 프로젝트 최초 적용임을 인지하고 진행한다.

---

## 구현 순서

### Phase 1. Domain

1. `Domain/Sources/Entity/KoreanRegion.swift`
   - `case etc` 추가 (연관값 없음, `String` raw value 유지)
2. `Domain/Sources/Entity/TravelPlan.swift` 신규
   - `public struct TravelPlan: Equatable, Identifiable, Sendable` — `id: UUID`(let), `title`, `region: KoreanRegion`, `customRegionText: String?`, `customEmoji: String?`, `startDate: Date`, `endDate: Date`
   - `public init` 명시 (모듈 외부 생성 필요)
3. `Domain/Sources/RepositoryProtocol/TravelPlanRepositoryProtocol.swift` 신규
   - `Sendable` 채택, `fetch() async throws -> [TravelPlan]`, `add(_ plan: TravelPlan) async throws` (필요 시 `remove(id:)`는 이번 범위에서 제외)
4. `Domain/Sources/UseCase/TravelPlan/TravelPlanUseCaseProtocol.swift` 신규 — Repository 프로토콜과 동일 시그니처
5. `Domain/Sources/UseCase/TravelPlan/TravelPlanUseCase.swift` 신규
   - `final class`, `private let repository: TravelPlanRepositoryProtocol` + `public init(repository:)`
   - MARK 순서: Properties → Init → Method (`BookmarkUseCase` 동일 구조)
6. `Domain/Sources/UseCase/TravelPlan/TestTravelPlanUseCase.swift` 신규
   - `@unchecked Sendable`, 주입용 `public var plans: [TravelPlan] = []`
7. `Domain/Sources/Dependency/Keys/TravelPlanUseCaseDependencyKey.swift` 신규
   - `TestDependencyKey` 채택, `testValue`만 정의
8. `Domain/Sources/Dependency/DependencyValues.swift` 수정
   - `public var travelPlanUseCase: TravelPlanUseCaseProtocol` get/set 추가

### Phase 2. Data

1. `Data/Sources/SwiftData/TravelPlanModel.swift` 신규
   - `@Model final class`, `@Attribute(.unique) var id: UUID`, `title`, `regionRaw: String`, `customRegionText: String?`, `customEmoji: String?`, `startDate`, `endDate` + 전체 인자 `init`
   - 접근 제어는 `BookmarkModel`과 동일하게 internal
2. `Data/Sources/SwiftData/TravelPlanDetailModel.swift` 신규
   - `@Model final class`, `@Attribute(.unique) var planId: UUID` + `init(planId:)`만. 상세 필드 정의 금지(다음 기능 작업 소관)
3. `Data/Sources/SwiftData/TravelPlanModelContainer.swift` 신규
   - `public final class ... Sendable`, `public static let shared`, `private init`
   - `Schema([TravelPlanModel.self, TravelPlanDetailModel.self])` — **두 모델 동시 등록**
   - 실패 시 `AppLogger.core.log(.error, ...)` + in-memory 폴백, 폴백까지 실패하면 `fatalError` (`BookmarkModelContainer` 동일)
4. `Data/Sources/Extension/TravelPlanModel+.swift` 신규
   - `var toDomain: TravelPlan?` — `KoreanRegion(rawValue: regionRaw)` 복원 실패 시 `AppLogger.core` 로그 후 `nil`
   - `convenience init(plan: TravelPlan)`
5. `Data/Sources/Repository/TravelPlan/TravelPlanRepository.swift` 신규
   - `public final class ... Sendable`, `private let modelContainer: ModelContainer`
   - `public init(modelContainer: ModelContainer = TravelPlanModelContainer.shared.modelContainer)`
   - 프로토콜 채택은 `// MARK: - TravelPlanRepositoryProtocol` extension으로 분리
   - `fetch()`: `ModelContext(self.modelContainer)` 생성 → `FetchDescriptor<TravelPlanModel>(sortBy: [SortDescriptor(\.startDate, order: .forward)])` → `compactMap(\.toDomain)`
   - `add(_:)`: context insert + save
   - 모든 메서드 `do/catch` → `AppLogger.core` 로그 후 `TabiError.persistenceFailed(message:)` throw

### Phase 3. DesignSystem

1. `DesignSystem/Sources/Calendar/TabiRangeCalendar.swift` 신규
   - 월 단위 그리드 + 요일 헤더 + 이전/다음 월 이동
   - 입력: 선택된 시작/종료일 바인딩(또는 값 + 콜백), 출력: 범위 확정 콜백
   - 규칙: 첫 탭 = 시작일, 두 번째 탭이 시작일 이후면 종료일 확정 / 이전이면 시작일 재설정 → **종료일 < 시작일을 UI에서 사전 차단**
   - 색상/서체/라운드는 `TabiColor`, `TypographyStyle`, `TabiRadius`, `TabiAnimation` 재사용
2. `DesignSystem/Sources/Field/TabiTextField.swift` 신규
   - placeholder + `@Binding text` + 선택적 최대 글자수(이모지 1자 제한용)
   - 일정명 / 커스텀 지역명 / 이모지 세 곳에서 공용 사용
3. `Resource/Sources/Strings/Strings.swift` 수정
   - `public enum Plan {}` 네임스페이스 추가 + `public extension Strings.Plan` 블록
   - 필요 문자열: 화면 타이틀, `+ 신규작성`, 섹션 헤더(진행중/다가오는/지난), `N일간` 배지, `N일차` 칩, `합계 0스팟`, `탭하여 상세를 표시`, 빈 상태 문구, 추가 화면 각 라벨/placeholder, 확인 버튼, 저장 실패 알림 문구
   - 기존 파일 컨벤션 준수: 일본어 값 + 한국어 주석, 파라미터가 있는 문자열은 `nonisolated(unsafe) static let x: ((Int) -> String)` 클로저 형태(`Strings.Bookmark.savedCountTitle` 참고)

### Phase 4. Presentation

1. `Presentation/Sources/Home/Model/KoreanRegion+.swift` 수정
   - `jaTitle` / `koTitle`에 `.etc` 케이스 추가 (`Strings.Region.etc*` 신설)
   - `image`의 `.etc` 처리 방침 확정 — 대응 에셋 없음. 옵셔널화 또는 대표 이미지 폴백 중 택1(홈 화면 `regionCard` 호출부 영향 확인 필수, `HomeView.swift:520`)
   - `emoji` 매핑 추가 — `.etc`는 `nil` 반환하여 `customEmoji` 입력을 유도
   - `allItems`는 홈 화면 전용이므로 **변경하지 않음**. 추가 화면 지역 그리드용 목록은 별도 상수로 분리
2. `Presentation/Sources/Plan/Entity/PlanSection.swift` 신규
   - `ongoing` / `upcoming` / `past` 케이스 + 섹션 타이틀
3. `Presentation/Sources/Plan/Model/TravelPlan+.swift` 신규
   - `dayCount`(시작~종료 포함 일수), `dayChipTitles`(1일차~N일차), `periodTitle`(시작일〜종료일), `displayEmoji`(`customEmoji ?? region.emoji`), `displayRegionTitle`(`region == .etc` → `customRegionText`), 오늘 기준 섹션 분류 헬퍼
   - 날짜 포맷은 `Presentation/Sources/Extension/Date+.swift`에 추가(기존 `DateFormatter` + `ja_JP` locale 패턴 준수)
4. `Presentation/Sources/AddTravelPlan/AddTravelPlanFeature.swift` 신규
   - State 순서: 공개 프로퍼티(`title`, `selectedRegion`, `customRegionText`, `emojiText`, `startDate`, `endDate`) → fileprivate → `@Presents`
   - 저장 가능 여부는 State의 computed property(`isConfirmEnabled`)로 파생: 이름 비어있지 않음 && 지역 선택됨 && (`.etc`면 `customRegionText` 비어있지 않음) && 시작·종료일 모두 선택됨
   - Action 순서: `binding` → 생명주기 → 사용자 인터랙션(`closeTapped`, `regionSelected`, `dateRangeSelected`, `confirmTapped`) → 비동기 결과(`saveResult`) → 하위(`alert`)
   - body: `BindingReducer()` → `Reduce` → `.ifLet(\.$alert, action: \.alert)`
   - 지역 선택 시 해당 지역의 기본 이모지를 `emojiText`에 자동 채움(사용자 타이핑으로 오버라이드 가능)
   - 저장 Effect는 `private extension`의 `saveEffect()`로 분리, `.run { [travelPlanUseCase = self.travelPlanUseCase] send in ... }` 형태로 의존성 값 캡처
   - 실패 시 `AppLogger.view` 로그 + alert
5. `Presentation/Sources/AddTravelPlan/AddTravelPlanView.swift` + `Sub/` 신규
   - 시트 상단 드래그 핸들 + X 닫기 버튼
   - `AddPlanRegionGridView`: 2열 그리드, 이모지 + 라벨, `.etc` 선택 시 커스텀 지역명 `TabiTextField` 노출
   - `AddPlanDateRangeView`: 출발/귀국 표시 필드 + `TabiRangeCalendar`
   - `AddPlanBottomCTAView`: `TabiButton(.primary, isExpanded: true)` + `.disabled(!isConfirmEnabled)` (`TabiButton`이 `@Environment(\.isEnabled)`로 0.5 opacity 처리 → 비활성 스타일 자동 적용)
   - body 50줄 초과분은 `private extension`의 View 메서드 또는 `Sub/`로 분리
6. `Presentation/Sources/Plan/PlanFeature.swift` 신규
   - State: `plans: [TravelPlan] = []`, `isLoading: Bool = false`, 섹션별 파생 computed property(`ongoingPlans`/`upcomingPlans`/`pastPlans`), `@Presents var addPlanState: AddTravelPlanFeature.State?`
   - Action: 생명주기(`onAppear`) → 인터랙션(`addButtonTapped`, `planTapped(id: UUID)`) → 비동기 결과(`plansResult([TravelPlan])`) → 하위(`addPlan(PresentationAction<AddTravelPlanFeature.Action>)`)
   - `addPlan(.presented(.saveResult(성공)))` 수신 시 `state.addPlanState = nil` + 목록 재조회
   - body: `Reduce` → `.ifLet(\.$addPlanState, action: \.addPlan) { AddTravelPlanFeature() }`
   - `planTapped`는 `.none` 반환 — 상위 `TabBarFeature`가 가로채 path push (`BookmarkFeature.spotTapped`와 동일한 위임 패턴)
   - 조회 Effect는 `// MARK: - Method` `private extension`으로 분리
7. `Presentation/Sources/Plan/PlanView.swift` + `Sub/` 신규
   - `.safeAreaBar(edge: .top) { TabiNavigationBar(title:) { trailing 버튼 } }` (`BookmarkView` 패턴)
   - 섹션별 리스트, 데이터 없는 섹션은 헤더 포함 렌더링 자체를 건너뜀
   - 전체가 비었을 때만 `PlanEmptyState`
   - `.sheet(item: $store.scope(state: \.addPlanState, action: \.addPlan)) { AddTravelPlanView(store: $0) }`
   - `.onAppear { store.send(.onAppear) }`
   - `PlanCardView`: `TabiCard`로 감싸고 상단 컬러 배너(이모지 + `N일간` 배지) / 이름 + chevron / 핀 아이콘 + `도시 · 기간` / 일자 칩 행 / `합계 0스팟` + `탭하여 상세를 표시`
8. `Presentation/Sources/Navigation/StackPath.swift` 수정
   - Plan Detail용 케이스 추가. **단 `PlanDetailFeature`가 이번 범위 밖**이므로, 리듀서 없는 `@Reducer enum` 케이스는 컴파일되지 않는다. 셀 탭 → `id` 전달 흐름을 우선 확보하고, 실제 `StackPath` 케이스 추가는 `PlanDetailFeature` 스켈레톤을 함께 만들지 여부를 구현 착수 시 결정한다(Acceptance Criteria의 "전달되는 구조가 마련"을 충족하는 최소 형태 선택).
9. `Presentation/Sources/Tabbar/TabBarFeature.swift` 수정
   - `PlanState` 임시 구조체 삭제, `var planState: PlanFeature.State = .init()`
   - `Action`에 `case plan(PlanFeature.Action)` 추가
   - body 상단에 `Scope(state: \.planState, action: \.plan) { PlanFeature() }` 추가
   - `case .plan(.planTapped(let id)):` 에서 path push, `case .plan: return .none` fallthrough 추가
10. `Presentation/Sources/Tabbar/TabBarView.swift` 수정
    - `Text(AppTab.plan.title)` → `PlanView(store: self.store.scope(state: \.planState, action: \.plan))`
    - `.tabItem`은 **Image only 유지** (텍스트 추가 금지)
    - `destination:` switch에 새 `StackPath` 케이스가 생기면 함께 대응

### Phase 5. App (DI)

1. `App/Sources/Dependency/TravelPlanUseCaseDependencyKey.swift` 신규
   - `extension TravelPlanUseCaseDependencyKey: @retroactive DependencyKey`
   - `liveValue: TravelPlanUseCaseProtocol { TravelPlanUseCase(repository: TravelPlanRepository()) }`

### Phase 6. 프로젝트 생성 및 빌드 검증

1. `tuist install && tuist generate` — 신규 `.swift` 파일이 다수라 필수 (미실행 시 stale 프로젝트로 오탐 에러)
2. `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'`
   - iPhone 16 Pro 시뮬레이터 미설치 → destination은 iPhone 17 사용

---

## 리스크 / 확인 필요

- `KoreanRegion.etc` 추가는 `KoreanRegion+.swift`의 exhaustive switch 3개(`jaTitle`, `koTitle`, `image`)를 즉시 깨뜨린다. 특히 `image: TabiImage`는 `.etc`용 에셋이 없어 반환 타입 변경 또는 폴백 결정이 필요하고, 이는 `HomeView.swift:520 regionCard(_:)` 호출부에 영향을 준다 — **현재 태스크와 무관한 홈 화면 동작이 바뀌지 않도록 폴백 방식을 먼저 확정할 것**
- `StackPath`에 Detail 케이스를 추가하려면 대응 Reducer가 필요하다. `PlanDetailFeature` 미구현 범위와 충돌하므로 Phase 4-8에서 최소 형태를 결정해야 함
- `@Presents` / `AlertState` / `.sheet(item: $store.scope(...))`는 이 프로젝트 최초 도입 패턴이라 참고할 기존 코드가 없다
- `TabiChip`은 `action` 클로저가 필수 인자다. 일자 칩은 탭 대상이 아니므로 그대로 재사용할지, 표시 전용 변형을 추가할지 구현 시 판단 필요

---

## 완료 조건
- [ ] 탭바 3번째 탭 진입 시 일정 목록이 진행중 → 다가오는 → 지난 순서로 섹션 표시된다
- [ ] 각 카드에 이모지(도시 기본값 또는 커스텀), 기간 배지, 일정 이름, "도시 · 시작일〜종료일", 일자 칩(1일차~N일차), "합계 0스팟" 고정 텍스트가 표시된다
- [ ] 데이터가 없는 섹션은 화면에서 숨겨진다
- [ ] NavigationBar의 + 버튼으로 일정 추가 화면이 `.sheet` 모달로 표시된다
- [ ] 추가 화면에서 이름 / 도시(기타 직접입력 포함) / 이모지(도시 기본값 자동 지정 + 텍스트필드 직접 입력) / 기간(인라인 캘린더 범위 선택)을 입력하고 확인 버튼으로 저장할 수 있다
- [ ] 필수값 미입력 시 확인 버튼이 비활성화된다
- [ ] 저장된 일정은 SwiftData에 영속화되어 앱 재시작 후에도 유지된다
- [ ] 종료일 < 시작일 선택이 캘린더 단계에서 차단된다
- [ ] SwiftData 저장/조회 실패 시 `AppLogger`로 로그가 남고 사용자에게 저장 실패 알림이 표시된다
- [ ] 셀 탭 시 `TravelPlan.id`(UUID)가 `StackPath`를 통해 전달되는 구조가 마련되어 있다 (Detail 화면 자체는 미구현)
- [ ] `TravelPlanDetailModel` 스켈레톤(`planId` 연동 키만 보유)이 생성되고 `TravelPlanModelContainer` Schema에 등록되어 있다
- [ ] `tuist generate` 후 AppDebug 스킴 빌드 성공

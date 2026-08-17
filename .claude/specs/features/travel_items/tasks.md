# Tasks: travel_items (툴박스 탭 준비물 마스터 리스트 → 플랜 저장 → PlanDetail 체크리스트)

## 참조
- spec: `.claude/specs/features/travel_items/spec.md`
- plan: `.claude/specs/features/travel_items/plan.md`

## Task 목록

### Phase 1. Domain

#### [x] Task 1 — `TravelItem.swift` (신규)
**파일**: `Projects/Domain/Sources/Entity/TravelItem.swift`
**의존**: 없음
- `public struct TravelItem: Equatable, Sendable, Identifiable` 선언
- 프로퍼티: `id: String`(RTDB 키), `order: Int`, `title: String`, `note: String?`

---

#### [x] Task 2 — `TravelPlanItem.swift` (신규)
**파일**: `Projects/Domain/Sources/Entity/TravelPlanItem.swift`
**의존**: 없음
- `public struct TravelPlanItem: Equatable, Sendable, Identifiable` 선언
- 프로퍼티: `id: UUID`, `planId: UUID`, `order: Int`, `title: String`, `note: String?`, `isChecked: Bool`

---

#### [x] Task 3 — `TravelItemRepositoryProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/RepositoryProtocol/TravelItemRepositoryProtocol.swift`
**의존**: Task 1
- `fetchMasterItems() async throws -> [TravelItem]` 메서드 정의

---

#### [x] Task 4 — `TravelPlanItemRepositoryProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/RepositoryProtocol/TravelPlanItemRepositoryProtocol.swift`
**의존**: Task 2
- `fetch(planId: UUID) async throws -> [TravelPlanItem]`
- `replace(planId: UUID, items: [TravelPlanItem]) async throws`
- `updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws`

---

#### [x] Task 5 — `TravelItemUseCaseProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/TravelItem/TravelItemUseCaseProtocol.swift`
**의존**: Task 1, Task 2
- 두 Repository의 메서드를 그대로 노출: `fetchMasterItems()` / `fetchSavedItems(planId:)` / `save(planId:items:)` / `updateChecked(planId:itemId:isChecked:)`

---

#### [x] Task 6 — `TravelItemUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/TravelItem/TravelItemUseCase.swift`
**의존**: Task 3, Task 4, Task 5
- `init(travelItemRepository:travelPlanItemRepository:)` — 두 Repository를 함께 주입받는 단일 UseCase
- `save(planId:items:)`에서 `[TravelItem]` → `[TravelPlanItem]` 변환(신규 `UUID()` 발급, `isChecked: false`, `order`/`title`/`note` 값 복사 승계) 후 `replace` 호출 — 사본 생성 규칙을 UseCase가 책임지고 Presentation은 모르게 함
- 저장 사본은 원본 RTDB 키를 참조하지 않음 (마스터 갱신이 사본에 소급되지 않도록 구조적으로 보장)

---

#### [x] Task 7 — `TestTravelItemUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/TravelItem/TestTravelItemUseCase.swift`
**의존**: Task 5
- `public final class TestTravelItemUseCase: TravelItemUseCaseProtocol, @unchecked Sendable`
- 데이터 주입용 `public var masterItems: [TravelItem] = []` / `public var savedItems: [TravelPlanItem] = []` 공개 프로퍼티
- `.claude/rules/test-style.md` 3번 규칙(Test 더블 작성 규칙)을 따름

---

#### [x] Task 8 — `TravelItemUseCaseDependencyKey.swift` (신규, Domain)
**파일**: `Projects/Domain/Sources/Dependency/Keys/TravelItemUseCaseDependencyKey.swift`
**의존**: Task 7
- `TestDependencyKey` 채택, `testValue`만 정의 (`TestTravelItemUseCase()` 반환)

---

#### [x] Task 9 — `DependencyValues.swift` (수정)
**파일**: `Projects/Domain/Sources/Dependency/DependencyValues.swift`
**의존**: Task 8
- `travelItemUseCase` 프로퍼티 확장 추가 (파일 하단, 기존 선언 스타일 유지)

---

### Phase 2. Data

#### [x] Task 10 — `TravelPlanItemModel.swift` (신규)
**파일**: `Projects/Data/Sources/SwiftData/TravelPlanItemModel.swift`
**의존**: 없음
- `@Model final class TravelPlanItemModel`
- `@Attribute(.unique) var id: UUID`
- 나머지 필드(`planId`, `order`, `title`, `note`, `isChecked`)는 기본값을 가진 non-optional로 선언 (기존 `TravelPlanDetailSpotModel` 관례 준수)

---

#### [x] Task 11 — `TravelPlanModelContainer.swift` (수정)
**파일**: `Projects/Data/Sources/SwiftData/TravelPlanModelContainer.swift`
**의존**: Task 10
- `Schema([...])`에 `TravelPlanItemModel.self` 추가
- 기존 3개 모델 필드는 건드리지 않으므로 SwiftData 경량 마이그레이션 범위 안, 별도 `VersionedSchema`/`MigrationPlan` 불필요

---

#### [x] Task 12 — `TravelPlanItemModel+.swift` (신규)
**파일**: `Projects/Data/Sources/Extension/TravelPlanItemModel+.swift`
**의존**: Task 10, Task 2
- `init(item: TravelPlanItem)` — `convenience`가 아닌 이니셜라이저
- `var toDomain: TravelPlanItem?` — 기존 `TravelPlanDetailSpotModel+.swift`와 동일 관례

---

#### [x] Task 13 — `TravelItemRepository.swift` (신규)
**파일**: `Projects/Data/Sources/Repository/TravelItem/TravelItemRepository.swift`
**의존**: Task 3, Task 1
- `public final class TravelItemRepository`, `public init() {}`
- `extension TravelItemRepository: TravelItemRepositoryProtocol`로 채택 분리 (swift-style.md 3번 규칙)
- `Database.database().reference(withPath: "TabiKori/travelItems")` → `getData()` → `snapshot.value as? [String: Any]`에서 `items` 딕셔너리 파싱 → 키를 `TravelItem.id`로, `order` 오름차순 정렬
- `items`가 없거나 비어있으면 `TabiError.dataNotFound`
- 실패 로그는 `AppLogger.network.log(.error, ...)`
- 참고: RTDB 스키마는 `ExchangeRateRepository`와 같은 딕셔너리 직접 파싱 방식 재사용, 필드는 `order: Number` / `title: String` / `note: String(optional)`

---

#### [x] Task 14 — `TravelPlanItemRepository.swift` (신규)
**파일**: `Projects/Data/Sources/Repository/TravelPlanItem/TravelPlanItemRepository.swift`
**의존**: Task 4, Task 10, Task 12
- `init(modelContainer: ModelContainer = TravelPlanModelContainer.shared.modelContainer)`
- `fetch(planId:)` — `FetchDescriptor` + `#Predicate { $0.planId == planId }` + `SortDescriptor(\.order)`
- `replace(planId:items:)` — 같은 `ModelContext`에서 기존 `planId` 항목 전체 `delete` 후 신규 `insert`, 마지막에 `save()` 1회 (단일 트랜잭션으로 "플랜당 리스트 1개" 불변 조건을 저장소 레벨에서 보장)
- `updateChecked(planId:itemId:isChecked:)` — 대상 1건 조회 후 플래그 갱신, 없으면 조용히 return (`removeSpot` 관례)
- 모든 `catch`에서 `AppLogger.core` 로깅 + `TabiError.persistenceFailed(message:)` 변환

---

#### [x] Task 15 — `TravelPlanRepository.swift` (수정)
**파일**: `Projects/Data/Sources/Repository/TravelPlan/TravelPlanRepository.swift`
**의존**: Task 10
- `remove(planId:)` — 해당 플랜의 `TravelPlanItemModel` 삭제 로직 추가 (고아 데이터 방지)
- `removeAll()` — `try context.delete(model: TravelPlanItemModel.self)` 추가 (설정 > 데이터 초기화에 자동 반영, `DataResetUseCase` 자체는 수정 불필요)

---

### Phase 3. App (DI 조립)

#### [x] Task 16 — `TravelItemUseCaseDependencyKey.swift` (신규, App)
**파일**: `Projects/App/Sources/Dependency/TravelItemUseCaseDependencyKey.swift`
**의존**: Task 8, Task 13, Task 14
- `extension TravelItemUseCaseDependencyKey: @retroactive DependencyKey`
- `liveValue = TravelItemUseCase(travelItemRepository: TravelItemRepository(), travelPlanItemRepository: TravelPlanItemRepository())`

---

### Phase 4. Resource

#### [x] Task 17 — `Strings.swift` (수정)
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
**의존**: 없음
- `public enum Strings` 블록에 `public enum TravelItems {}` 추가
- `Strings.Tabbar`에 `toolbox` 추가 (제안값 `"ツール"`)
- `public extension Strings.TravelItems` 신설, 항목마다 한국어 주석(기존 파일 관례) 포함:
  - 마스터 화면: `title`(제안 `"持ち物リスト"`), `saveToPlanButton`(제안 `"旅程に保存"`)
  - 마스터 로드 실패: `loadFailedDescription`
  - 플랜 선택 시트: `planPickerTitle`, `planPickerEmptyTitle` / `planPickerEmptyDescription`(플랜 0건)
  - 덮어쓰기 알림: `overwriteAlertTitle` / `overwriteAlertMessage` / `overwriteAlertConfirm` (취소 문구는 `Strings.Common` 기존 항목 확인 후 없으면 추가)
  - 저장 실패: `saveFailedDescription`
  - PlanDetail 진입 버튼: `planDetailEntryTitle`(접근성 라벨용)
  - 저장된 체크리스트 화면: `savedEmptyTitle` / `savedEmptyDescription`(아직 저장 안 된 플랜), `checkedCountTitle(_:_:)`(예: 완료 n/m)
  - 재시도 버튼 문구는 `Strings.RegionSpot.retryButtonTitle`을 쓰는 `TabiRetryableEmptyState` 내부 처리이므로 신규 정의 불필요

---

### Phase 5. Presentation — 툴박스 탭 + 준비물 마스터 화면

#### [x] Task 18 — `TravelItemsFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/TravelItems/TravelItemsFeature.swift`
**의존**: Task 9(`travelItemUseCase`), Task 1, Task 26(시트 Reducer 타입, 컴파일 시점 의존 — Phase 6 완료 후 최종 컴파일 가능)
- `@Dependency(\.travelItemUseCase)`
- `State`: `items: [TravelItem] = []`, `isLoading: Bool = false`, `hasLoadFailed: Bool = false`, `fileprivate var hasStartedLoading: Bool = false`, `@Presents var planPickerState: TravelItemsPlanPickerFeature.State?`
- `Action`: `onAppear`, `retryButtonTapped`, `saveToPlanButtonTapped`, `masterItemsResult([TravelItem])`, `masterItemsFailed`, `planPicker(PresentationAction<TravelItemsPlanPickerFeature.Action>)`
- `.onAppear` — `hasStartedLoading` 가드(`PlanDetailFeature` 관례) 후 조회 Effect
- `.retryButtonTapped` — 가드 없이 재조회, `.cancellable(id:cancelInFlight: true)` 적용
- `.saveToPlanButtonTapped` — `items.isEmpty == false` 가드 후 `planPickerState = .init(items: state.items)`
- `.planPicker(.presented(.savedToPlan))` — 시트 닫기 (`planPickerState = nil`)
- body 마지막에 `.ifLet(\.$planPickerState, action: \.planPicker) { TravelItemsPlanPickerFeature() }`
- `private extension`에 `fetchMasterItemsEffect()` (실패 시 `AppLogger.view` 로깅 + `masterItemsFailed`)

---

#### [x] Task 19 — `TravelItemRow.swift` (신규)
**파일**: `Projects/Presentation/Sources/TravelItems/Sub/TravelItemRow.swift`
**의존**: Task 1
- `title` + `note`(있을 때만) 2줄 구성, 체크박스 없는 읽기 전용 행
- 기존 목록 화면과 동일한 시각 언어(`TabiCard` 또는 구분선 목록 중 선택)

---

#### [x] Task 20 — `TravelItemsView.swift` (신규)
**파일**: `Projects/Presentation/Sources/TravelItems/TravelItemsView.swift`
**의존**: Task 18, Task 19, Task 26(시트 뷰 타입)
- `@Bindable private var store`, `public init(store:)`
- 상태 3분기: 로딩 `ProgressView` / 실패 `TabiRetryableEmptyState(description:onRetry:)` / 성공 `List`(`.plain`, 구분선·배경 제거)
- 하단 고정 `TabiButton(Strings.TravelItems.saveToPlanButton, style: .primary, isExpanded: true)` — 로딩·실패 상태에서는 비활성
- `.sheet(item: self.$store.scope(state: \.planPickerState, action: \.planPicker))`
- `.navigationTitle(Strings.TravelItems.title)` + `.navigationBarTitleDisplayMode(.inline)` (탭 루트가 `TabBarView`의 `NavigationStack` 안이므로 자체 스택 생성 금지)
- `#Preview` — `TestTravelItemUseCase.masterItems` 주입

---

#### [x] Task 21 — `AppTab.swift` (수정)
**파일**: `Projects/Presentation/Sources/Tabbar/Entity/AppTab.swift`
**의존**: 없음
- `case toolbox` 추가
- `title` / `systemImage`(`"shippingbox"`) 분기 추가

---

#### [x] Task 22 — `TabBarFeature.swift` (수정, 1차 — 툴박스 탭 연결)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
**의존**: Task 18, Task 21
- `State`에 `toolboxState: TravelItemsFeature.State` 추가
- `Action`에 `case toolbox(TravelItemsFeature.Action)` 추가
- `Scope(state: \.toolboxState, action: \.toolbox)` 추가
- `case .toolbox: return .none` 기본 처리

---

#### [x] Task 23 — `TabBarView.swift` (수정, 1차 — 툴박스 탭 노출)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarView.swift`
**의존**: Task 20, Task 21, Task 22
- `TravelItemsView(...)`를 `TabView`에 `.tabItem { Image(systemName: AppTab.toolbox.systemImage) }` + `.tag(AppTab.toolbox)`로 마지막(4번째 탭 다음)에 추가
- 텍스트 라벨(`Label`/`Text`) 추가 금지 — 이미지 전용 탭 유지 (기존 관례)

---

### Phase 6. Presentation — 플랜 선택 시트 (저장 확정)

#### [x] Task 24 — `TravelItemsPlanPickerFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/TravelItemsPlanPicker/TravelItemsPlanPickerFeature.swift`
**의존**: Task 9(`travelPlanUseCase`, `travelItemUseCase`), Task 1
- `@Dependency(\.travelPlanUseCase)`, `@Dependency(\.travelItemUseCase)`, `@Dependency(\.dismiss)`
- `State`: `let items: [TravelItem]`, `plans: [TravelPlan] = []`, `isLoading: Bool = false`, `isSaving: Bool = false`, `@Presents var alert: AlertState<Action.Alert>?`
- `Action`: `onAppear`, `closeButtonTapped`, `planRowTapped(TravelPlan)`, `plansResult([TravelPlan])`, `existingItemsResult(plan: TravelPlan, hasSaved: Bool)`, `saveFailed`, `savedToPlan`, `alert(PresentationAction<Alert>)` / `enum Alert { case overwriteConfirmed(TravelPlan) }`
- `.onAppear` — `travelPlanUseCase.fetch()`로 플랜 목록 조회
- `.planRowTapped` — `isSaving == false` 가드 후 해당 플랜의 저장 여부 조회 Effect
- `.existingItemsResult` — 저장분 없으면 즉시 저장 Effect 실행, 있으면 `alert = AlertState { 덮어쓰기 확인 }` 설정 (spec 미결 항목 확정: 덮어쓰기 확인 알림)
- `.alert(.presented(.overwriteConfirmed(plan)))` — 저장 Effect 실행
- 저장 Effect — `travelItemUseCase.save(planId:items:)` 호출 → 성공 시 `savedToPlan` / 실패 시 `AppLogger.view` 로깅 + `saveFailed`
- `.savedToPlan` — `.run { await dismiss() }` (부모 `TravelItemsFeature`도 `planPickerState = nil` 처리하므로 sheet 상태가 이중으로 정리됨)
- body: `Reduce` → `.ifLet(\.$alert, action: \.alert)`

---

#### [x] Task 25 — `TravelItemsPlanPickerRow.swift` (신규)
**파일**: `Projects/Presentation/Sources/TravelItemsPlanPicker/Sub/TravelItemsPlanPickerRow.swift`
**의존**: 없음 (`Domain.TravelPlan` 참조)
- `plan` + `onTap` 파라미터
- 제목 · `displayRegionTitle` · 기간 표시
- `TabiPressStyle` 적용
- `AddToItineraryPlanRow`는 아코디언 펼침 전제라 재사용하지 않고 신규 제작 (플랜 1건 선택만 필요하므로 펼침 개념 없음, `TabiCard` + `TabiLabel` 조합)

---

#### [x] Task 26 — `TravelItemsPlanPickerView.swift` (신규)
**파일**: `Projects/Presentation/Sources/TravelItemsPlanPicker/TravelItemsPlanPickerView.swift`
**의존**: Task 24, Task 25
- 헤더: 타이틀 + `TabiCircleIconButton`(닫기) — `AddCustomPlace`/`PlanDetailAddSpot` 헤더와 동일 배치
- 본문 3분기: 로딩 `ProgressView` / 플랜 0건 `TabiEmptyState(systemImageName:title:description:)` / 목록은 `PlanSection`(진행중·예정·지난) 그룹 헤더 + 행
- 저장 중에는 목록 `disabled` + `ProgressView` 오버레이 (`AddToItineraryPlanListView` 관례)
- `.alert($store.scope(state: \.alert, action: \.alert))`
- `.presentationDetents([.medium, .large])` + `.presentationDragIndicator(.visible)`

---

### Phase 7. Presentation — PlanDetail 연결 + 저장된 체크리스트 화면

#### [x] Task 27 — `PlanTravelItemsFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanTravelItems/PlanTravelItemsFeature.swift`
**의존**: Task 9(`travelItemUseCase`), Task 2
- `@Dependency(\.travelItemUseCase)`
- `State`: `let plan: TravelPlan`, `items: [TravelPlanItem] = []`, `isLoading: Bool = false`, `fileprivate var hasStartedLoading: Bool = false`
- 계산 프로퍼티 `checkedCount` / `isEmpty`
- `Action`: `onAppear`, `itemTapped(id: UUID)`, `savedItemsResult([TravelPlanItem])`, `checkUpdateFailed(id: UUID, previous: Bool)`
- `.itemTapped` — State에서 즉시 토글(낙관적 갱신) 후 `updateChecked` Effect, 실패 시 `checkUpdateFailed`로 원복 + `AppLogger.view` 로깅
- `public init(plan:)` (`StackPath`에서 생성)

---

#### [x] Task 28 — `PlanTravelItemCheckRow.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanTravelItems/Sub/PlanTravelItemCheckRow.swift`
**의존**: Task 2
- `item` + `onTap` 파라미터
- 체크 아이콘 SF Symbols `checkmark.circle.fill` / `circle` + `TabiColor.tabiPrimary`, `.tabiFast` 애니메이션
- 체크 시 제목 색상 `tabiTextTertiary`
- DesignSystem으로 승격하지 않음 (사용처가 이 화면 하나뿐, 두 번째 사용처 발생 시 승격 검토)

---

#### [x] Task 29 — `PlanTravelItemsView.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanTravelItems/PlanTravelItemsView.swift`
**의존**: Task 27, Task 28
- 로딩 `ProgressView` / 저장분 0건 `TabiEmptyState(.fill)`(`savedEmpty*` 문구) / 목록 `List(.plain)`
- `.navigationTitle(Strings.TravelItems.title)`, 진행률(`checkedCountTitle`)은 서브타이틀 또는 목록 상단 라벨로 표시
- `#Preview` — `TestTravelItemUseCase.savedItems` 주입

---

#### [x] Task 30 — `StackPath.swift` (수정)
**파일**: `Projects/Presentation/Sources/Navigation/StackPath.swift`
**의존**: Task 27
- `case planTravelItems(PlanTravelItemsFeature)` 추가

---

#### [x] Task 31 — `PlanDetailDayHeader.swift` (수정)
**파일**: `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailDayHeader.swift`
**의존**: 없음
- `let onTravelItemsTapped: (() -> Void)?`(기본값 `nil`) 파라미터 추가
- 값이 있을 때만 `Spacer()` + 우측 버튼(아이콘 + 라벨, `TabiPressStyle`) 렌더링
- 기존 호출부(전체보기 Section 헤더)는 파라미터를 넘기지 않아 무변경 — "준비물" 버튼이 일자 모드에서만 노출되어 "플랜당 1회" 불변 조건을 렌더링 구조상 보장

---

#### [x] Task 32 — `PlanDetailFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/PlanDetail/PlanDetailFeature.swift`
**의존**: 없음
- `Action`에 `case travelItemsButtonTapped` 추가
- `Reduce`에서 `.none` 반환 (상태 변화 없이 부모 `TabBarFeature`가 가로챔, `spotRowTapped`와 동일 성격)

---

#### [x] Task 33 — `PlanDetailView.swift` (수정)
**파일**: `Projects/Presentation/Sources/PlanDetail/PlanDetailView.swift`
**의존**: Task 31, Task 32
- `dayHeader(plan:)`의 `PlanDetailDayHeader` 호출에만 `onTravelItemsTapped: { self.store.send(.travelItemsButtonTapped) }` 주입 (전체보기 Section 헤더 호출부는 미주입)

---

#### [x] Task 34 — `TabBarFeature.swift` (수정, 2차 — PlanDetail 연결)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
**의존**: Task 30, Task 32
- `case .path(.element(id: _, action: .planDetail(.travelItemsButtonTapped)))` 수신 시 `state.path[id: id]` 패턴 매칭(`photoCellTapped` 관례)으로 해당 `planDetail` state의 `plan`을 꺼내 `path.append(.planTravelItems(PlanTravelItemsFeature.State(plan: plan)))`

---

#### [x] Task 35 — `TabBarView.swift` (수정, 2차 — 체크리스트 화면 destination)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarView.swift`
**의존**: Task 29, Task 30
- `destination` switch에 `case .planTravelItems(let store): PlanTravelItemsView(store: store)` 분기 추가

---

### Phase 8. 빌드 / 검증

#### [ ] Task 36 — Firebase 콘솔 데이터 입력 (사전 작업, 코드 외)
**대상**: Firebase Realtime Database `TabiKori/travelItems`
**의존**: 없음 (Phase 4 이전에 해두면 Phase 5 검증이 수월)
- 경로: `TabiKori/travelItems/items/<key>` 형태로 `{ "order": Number, "title": String, "note": String(optional) }` 데이터 입력
- 필드명(`items` / `order` / `title` / `note`)을 다르게 쓰기로 하면 Task 13(`TravelItemRepository`) 파싱 로직도 함께 수정

---

#### [x] Task 37 — Tuist 프로젝트 재생성
**명령어**: `tuist install && tuist generate`
**의존**: Task 1 ~ Task 35 (신규 `.swift` 파일 전부)
- 신규 `.swift` 파일 약 22개 추가로 인해 필수 (생략 시 stale 프로젝트로 오탐 에러 발생)

---

#### [x] Task 38 — 빌드 확인
**명령어**: `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'`
**의존**: Task 37
- 빌드 성공 확인 (시뮬레이터는 iPhone 16 Pro 미설치 환경이므로 iPhone 17 사용)

---

#### [ ] Task 39 — 시나리오 검증
**의존**: Task 38
- 툴박스 탭 → 마스터 리스트 로드 / 기내모드에서 재시도 빈 상태 확인
- "플랜에 저장" → 플랜 0건 빈 상태 / 플랜 선택 → 저장 → 시트 닫힘 확인
- 같은 플랜에 재저장 → 덮어쓰기 알림 → 확인 시 1개 리스트만 유지되는지 확인
- PlanDetail 일자 헤더 버튼 1회 노출, 전체보기 전환 시 중복 노출 없음 확인
- 체크 토글 → 앱 강제 종료 후 재실행에도 상태 유지 확인
- 준비물 미저장 플랜에서 버튼 탭 → 빈 상태 확인
- 플랜 삭제 / 설정 > 데이터 초기화 후 해당 준비물도 함께 사라지는지 확인

---

## 체크리스트

### 품질 (DoD)
- [x] `tuist install && tuist generate` 후 빌드 성공
- [x] `TravelPlanDetail` / `TravelPlanDetailSpot` 및 기존 일정 로직에 변경 없음 (Diff 확인)
- [x] Domain은 Data/Firebase를 직접 참조하지 않음 (RepositoryProtocol 경유)
- [x] 신규 문자열은 `Strings.TravelItems` / `Strings.Tabbar.toolbox`로만 정의, 하드코딩 없음
- [x] 신규 UI는 DesignSystem 기존 컴포넌트(`TabiButton`, `TabiCard`, `TabiEmptyState`, `TabiRetryableEmptyState`, `TabiCircleIconButton`, `TabiPressStyle` 등) 우선 재사용
- [x] 접근 제어: Feature/State/Action/`init`은 `public`, 탭 루트/스택 push View(`TravelItemsView`, `PlanTravelItemsView`)만 `public`, 나머지 View/`Sub/`는 `internal`

### 기능 (AC)
- [x] 툴박스 탭이 Tabbar에 노출되고 진입 시 준비물 화면(마스터 리스트)으로 연결된다 (코드 구현 완료, 시뮬레이터 수동 확인 필요)
- [ ] 준비물 화면에서 Firebase Realtime Database의 마스터 체크리스트가 로드된다 (로딩/에러 상태 포함) — Firebase 콘솔 데이터 미입력으로 실기기 검증 불가 (Task 36 선행 필요)
- [x] "플랜에 저장" 버튼으로 플랜 선택 화면에서 플랜을 고르면, 해당 플랜에 준비물 리스트 전체가 저장되고 SwiftData에 영속화된다 (코드 구현 완료, 시뮬레이터 수동 확인 필요)
- [x] PlanDetail 일자 헤더 영역에 "준비물" 버튼이 플랜당 1회만 노출된다 (코드 구현 완료, 시뮬레이터 수동 확인 필요)
- [x] "준비물" 버튼 탭 시 저장된 체크리스트 화면으로 이동하며, 각 항목을 체크/해제할 수 있고 상태가 영속화된다 (코드 구현 완료, 시뮬레이터 수동 확인 필요)
- [x] 준비물이 아직 저장되지 않은 플랜에서는 빈 상태 UI가 표시된다 (코드 구현 완료, 시뮬레이터 수동 확인 필요)
- [x] 이미 저장된 플랜을 다시 선택하면 덮어쓰기 확인 알림이 뜨고, 확인 시에도 해당 플랜의 준비물 리스트는 1개만 유지된다 (코드 구현 완료, 시뮬레이터 수동 확인 필요)
- [x] 플랜 삭제 및 설정 > 데이터 초기화 시 해당 준비물 데이터도 함께 제거된다 (코드 구현 완료, 시뮬레이터 수동 확인 필요)

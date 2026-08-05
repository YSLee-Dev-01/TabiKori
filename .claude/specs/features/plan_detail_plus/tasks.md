# Tasks: plan_detail_plus

## 참조
- spec: `.claude/specs/features/plan_detail_plus/spec.md`
- plan: `.claude/specs/features/plan_detail_plus/plan.md`

## Task 목록

### Phase 1. Resource

#### [x] Task 1 — `Strings.swift`
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- `Strings.Plan`에 `spotAddSearchTabTitle = "観光地検索"` 추가 (주석: `/// 스팟 추가 시트 - 관광지 검색 탭`)
- 즐겨찾기 탭 라벨(`Strings.Bookmark.title`), 시트 타이틀(`Strings.Plan.spotAddButtonTitle`), 검색 placeholder(`Strings.Map.searchPlaceholder`)는 기존 문자열을 그대로 재사용하고 신규 정의하지 않는다

---

### Phase 2. Presentation — 새 Feature (Reducer)

#### [x] Task 2 — `PlanDetailAddSpotFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetailAddSpot/PlanDetailAddSpotFeature.swift`
- 의존성 선언: `@Dependency(\.touristSpotUseCase)`, `@Dependency(\.bookmarkUseCase)`, `@Dependency(\.travelPlanDetailUseCase)`, `@Dependency(\.dismiss)`
- `State` 정의 (선언 순서: 공개 → fileprivate → @Presents)
  - 주입값: `planId: UUID`, `dayIndex: Int`, `date: Date` (전부 `let`)
  - `step: Step = .selectingSpot`, `tab: Tab = .search`
  - 검색 관련: `searchKeyword: String = ""`, `searchResults: [TouristSpot] = []`, `isSearchLoading: Bool = false`, `hasSearched: Bool = false`
  - 즐겨찾기 관련: `bookmarks: [Bookmark] = []`, `isBookmarkLoading: Bool = false`
  - 선택/시간 관련: `selectedSpot: TouristSpot? = nil`, `startTime: Date = Date()`, `endTime: Date = Date()`, `isSaving: Bool = false`
  - `fileprivate let existingDetail: TravelPlanDetail?`
  - 중첩 타입: `enum Step { case selectingSpot, configuringTime }`, `enum Tab { case search, bookmark }`
  - 계산 프로퍼티: `durationMinutes`, `isSaveEnabled`(= `endTime > startTime`) — `AddToItineraryFeature.State`와 동일 구현
  - `public init(planId:dayIndex:date:detail:)` 정의
- `Action: BindableAction, Equatable` 정의 (선언 순서: 바인딩 → 생명주기 → 인터랙션 → 결과 → 하위)
  - `binding(BindingAction<State>)`
  - `tabSelected(State.Tab)`, `searchSubmitted`, `spotRowTapped(TouristSpot)`, `backButtonTapped`, `closeButtonTapped`, `saveButtonTapped`
  - `searchResultsResult([TouristSpot])`, `bookmarksResult([Bookmark])`, `saveFailed`, `spotAdded`
- `body` 구현: `BindingReducer()` → `Reduce`
  - `.binding(\.searchKeyword)`에서 키워드가 빈 문자열이 되면 `searchResults = []`, `hasSearched = false`, `.cancel(id: CancelID.search)` 반환
  - `.tabSelected`: 동일 탭 재선택 시 `.none`, `.bookmark`로 전환 시 `isBookmarkLoading = true` + 북마크 조회 Effect(`cancellable(cancelInFlight: true)`)
  - `.searchSubmitted`: 트림 후 빈 문자열이면 `.none`, 아니면 `isSearchLoading = true`, `hasSearched = true`, 검색 Effect(`cancellable(cancelInFlight: true)`)
  - `.spotRowTapped(spot)`: `selectedSpot = spot`, `makeDefaultTimeRange`로 `startTime`/`endTime` 설정, `step = .configuringTime`
  - `.backButtonTapped`: `selectedSpot = nil`, `step = .selectingSpot`
  - `.closeButtonTapped`: `.run { await dismiss() }`
  - `.saveButtonTapped`: `isSaveEnabled && isSaving == false && selectedSpot != nil` 가드 → `isSaving = true` → 해당 `dayIndex` 스팟 개수로 `order` 계산 → `TravelPlanDetailSpot` 생성 → 저장 Effect 호출
  - 결과 액션: 로딩 플래그 해제 + 값 대입, `.saveFailed`는 `isSaving = false`, `.spotAdded`는 `.none`
- `private enum CancelID { case search, fetchBookmarks }` 파일 하단에 정의 (`// MARK: - CancelID`)
- `// MARK: - Method` `private extension`에 헬퍼 정의
  - `searchEffect(keyword:)` — 실패 시 `AppLogger.view.log(.error, ...)` + `searchResultsResult([])`
  - `fetchBookmarksEffect()` — 실패 시 로깅 + `bookmarksResult([])`
  - `saveEffect(planId:spot:)` — `travelPlanDetailUseCase.add(TravelPlanDetail(planId:spots:[spot]))` 호출, 성공 시 `spotAdded`, 실패 시 로깅 + `saveFailed`
  - `static func makeDefaultTimeRange(date:dayIndex:detail:)` — 해당 `dayIndex`의 마지막 스팟 종료 시각 이후, 없으면 09:00 시작, 종료는 +60분 (`AddToItineraryFeature.makeDefaultTimeRange`와 동일 로직으로 복제)

---

### Phase 3. Presentation — 새 View 계층

#### [x] Task 3 — `PlanDetailAddSpotSpotRow.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetailAddSpot/Sub/PlanDetailAddSpotSpotRow.swift`
- `spot: TouristSpot`, `onTap: () -> Void` 파라미터를 받는 뷰 정의
- 내부에서 `TabiSpotRow`로 렌더링 — `japaneseTitle.removingBracketedTags` / `koreanTitle?.removingBracketedTags`를 제목/부제로 전달
- `distance`는 항상 `nil` 전달 (검색·북마크 모두 기준 좌표 없음, `BookmarkView`와 동일 처리)
- 검색/즐겨찾기 두 리스트에서 공용으로 사용

---

#### [x] Task 4 — `PlanDetailAddSpotEmptyState.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetailAddSpot/Sub/PlanDetailAddSpotEmptyState.swift`
- `systemImageName: String`, `title: String`, `description: String` 파라미터를 받는 뷰 정의
- 아이콘 + 제목 + 설명 3요소를 세로 중앙 정렬로 배치
- 검색 안내 / 검색 결과 없음 / 북마크 없음 3가지 문구를 파라미터로 주입받아 재사용

---

#### [x] Task 5 — `PlanDetailAddSpotTabBar.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetailAddSpot/Sub/PlanDetailAddSpotTabBar.swift`
- `selectedTab: PlanDetailAddSpotFeature.State.Tab`, `onTabSelected: (PlanDetailAddSpotFeature.State.Tab) -> Void` 파라미터
- "観光地検索" / "保存済み" 2분할 균등 폭 탭 UI 구현 (`TabiChip`이 아닌 전용 컴포넌트, `DesignSystem` 승격 없음)
- 색/타이포는 `TabiChip`과 동일 토큰(`tabiPrimary`/`tabiSurface`/`tabiBorder`, `captionMBold`/`captionM`) 사용
- 탭 선택 전환에 `.tabiFast` 애니메이션 적용

---

#### [x] Task 6 — `PlanDetailAddSpotSearchListView.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetailAddSpot/Sub/PlanDetailAddSpotSearchListView.swift`
- `TabiSearchField(placeholder: Strings.Map.searchPlaceholder, text:focus:onSubmit:)` 배치
- 로딩 중일 때 `ProgressView` 표시
- 미검색 상태(`hasSearched == false`)일 때 `Strings.Map.searchEmptyDescription` 안내 빈 상태(`PlanDetailAddSpotEmptyState`) 표시
- 검색 완료 후 결과 0건이면 `Strings.Map.searchResultEmptyTitle` / `searchResultEmptyDescription` 빈 상태 표시
- 결과 존재 시 `List` + `.listStyle(.plain)` + 구분선/배경 제거(`BookmarkView` 관행), 각 행은 `PlanDetailAddSpotSpotRow` 사용

---

#### [x] Task 7 — `PlanDetailAddSpotBookmarkListView.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetailAddSpot/Sub/PlanDetailAddSpotBookmarkListView.swift`
- 로딩 / 빈 상태(`Strings.Bookmark.emptyTitle` / `emptyDescription`) / 목록 3분기 처리
- 목록 표시 시 각 행은 `PlanDetailAddSpotSpotRow`(Task 3) 재사용

---

#### [x] Task 8 — `PlanDetailAddSpotView.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetailAddSpot/PlanDetailAddSpotView.swift`
- `@Bindable private var store: StoreOf<PlanDetailAddSpotFeature>` 선언
- 헤더 구현: Step 2일 때만 back 버튼 표시 + `Strings.Plan.spotAddButtonTitle` 타이틀 + 닫기 버튼 (`AddToItineraryView.header()`와 동일 레이아웃)
- Step 1 분기: `PlanDetailAddSpotTabBar` + 선택된 탭에 따라 `PlanDetailAddSpotSearchListView` 또는 `PlanDetailAddSpotBookmarkListView` 표시
- Step 2 분기: `AddToItineraryTimeConfigView(planTitle: 선택 스팟 일본어명, dayTitle: Strings.Plan.dayChipTitle(dayIndex + 1), dateTitle: date.planDayHeaderTitle, startTime: $store.startTime, endTime: $store.endTime, durationMinutes:isSaveEnabled:isSaving:onSaveTapped:)` 사용 (Step 2 전용 뷰 신규 제작 없음)
- Step 전환에 `.transition(.move(edge:))` + `.animation(.tabiStandard, value: store.step)` 적용
- `body`가 50줄 초과 시 `private extension`으로 `header()` / `stepContent()` 분리
- `#Preview` 작성 — `TestTouristSpotUseCase.searchResults`, `TestBookmarkUseCase.bookmarks`, `TestTravelPlanDetailUseCase.details`에 `TravelPlanDetail.mock` 주입

---

### Phase 4. Presentation — PlanDetail 연결

#### [x] Task 9 — `PlanDetailFeature.swift`
**파일**: `Projects/Presentation/Sources/PlanDetail/PlanDetailFeature.swift`
- State 하단(`fileprivate var hasStartedLoading` 다음)에 `@Presents var addSpotState: PlanDetailAddSpotFeature.State?` 추가
- Action 최하단에 `case addSpot(PresentationAction<PlanDetailAddSpotFeature.Action>)` 추가
- `.addSpotButtonTapped` 핸들러에서 기존 `// TODO: 스팟 추가 플로우 연결` 주석 제거
  - `guard state.plan.dayDates.indices.contains(state.selectedDayIndex)` 확인 후 `addSpotState` 생성 (`planId` / `dayIndex` / `date` / `detail: state.travelPlanDetail` 주입)
- `.addSpot(.presented(.spotAdded))` 수신 시 `addSpotState = nil` + `fetchTravelPlanDetailEffect(id: state.plan.id)` 재호출
- 그 외 `.addSpot` 케이스는 `.none` 처리
- `body` 마지막에 `.ifLet(\.$addSpotState, action: \.addSpot) { PlanDetailAddSpotFeature() }` 추가

---

#### [x] Task 10 — `PlanDetailView.swift`
**파일**: `Projects/Presentation/Sources/PlanDetail/PlanDetailView.swift`
- `private let store` → `@Bindable private var store`로 변경 (`init`의 `self.store = store` 대입은 유지)
- 루트 뷰에 `.sheet(item: self.$store.scope(state: \.addSpotState, action: \.addSpot)) { PlanDetailAddSpotView(store: $0).presentationDetents([.large]).presentationDragIndicator(.visible) }` 추가

---

## 체크리스트

### 품질 (DoD)
- [x] `tuist generate` 실행 (Phase 2~3에서 7개 신규 파일 추가)
- [x] 빌드 성공 (`xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` — BUILD SUCCEEDED, iPhone 16 Pro 미설치로 iPhone 17 사용)
- [x] `AddToItineraryFeature` / `AddToItineraryView` / `TouristSpotUseCaseProtocol` / `BookmarkUseCaseProtocol` / `TravelPlanDetailUseCaseProtocol`에 변경 없음 (code-review로 확인)

### 기능 (AC)
- [ ] PlanDetail "+" 탭 시 `.large` 시트가 열리고 "観光地検索" / "保存済み" 탭이 표시된다
- [ ] "관광지 검색" 탭에서 키워드 입력 후 제출(`onSubmit`) 시 검색 결과가 `TabiSpotRow` 리스트로 표시된다
- [ ] "즐겨찾기" 탭 진입 시 북마크한 관광지 목록이 표시된다
- [ ] 검색/즐겨찾기 목록에서 스팟 탭 시 시간 설정 화면(Step 2)으로 전환되고, 기본 시작 시각이 해당 Day 마지막 스팟 종료 시각(없으면 09:00)으로 채워진다
- [ ] 시간 설정 화면에서 저장 시 시트가 닫히고 PlanDetail의 해당 날짜 목록에 새 스팟이 즉시 반영된다
- [ ] `endTime <= startTime`이면 저장 버튼이 비활성화된다
- [ ] 저장 실패 시 시트가 닫히지 않고 `isSaving`이 해제되며 `AppLogger.view` 에러 로그가 남는다
- [ ] 검색어를 지우면 안내 빈 상태로 복귀하고 이전 검색 결과가 사라진다

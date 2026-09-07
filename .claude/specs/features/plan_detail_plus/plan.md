# Plan: plan_detail_plus (일정 상세 "+" → 스팟 검색/즐겨찾기 선택 후 시간 설정 추가)

## 참조 Spec
- @.claude/specs/features/plan_detail_plus/spec.md

## 참조 Skill
- 프로젝트에 `create-feature` 스킬 없음 (`.claude/skills/`에는 code-review / commit / feature / prompt만 존재)
- 레퍼런스 패턴:
  - `@.claude/specs/features/plan_detail_list/plan.md` — `PlanDetail` 계층 구성 및 스팟 모델
  - `Presentation/Detail` + `Presentation/AddToItinerary` — `@Presents` + `.sheet(item:)` 하단 시트 표시 / Step 전환 / 저장 Effect
  - `Presentation/Map` — 키워드 검색 State/Effect/취소 처리
  - `Presentation/Bookmark` — 북마크 목록 조회 + `TabiSpotRow` 렌더링

---

## 현재 상태 파악

### 신규

**Presentation** (전부 `Projects/Presentation/Sources/PlanDetailAddSpot/` 하위)
- `PlanDetailAddSpotFeature.swift` — TCA Reducer. Step 1(스팟 선택: 검색/즐겨찾기 탭) ↔ Step 2(시간 설정) 전환, 검색/북마크 조회/저장 Effect 보유
- `PlanDetailAddSpotView.swift` — 시트 루트 뷰. 헤더(뒤로/타이틀/닫기) + Step 분기
- `Sub/PlanDetailAddSpotTabBar.swift` — "観光地検索" / "保存済み" 2개 탭 전환 UI (DesignSystem에 세그먼트 컴포넌트 없음 → 화면 전용 신규 제작, 승격하지 않음)
- `Sub/PlanDetailAddSpotSearchListView.swift` — 검색 필드 + 결과 리스트 + 로딩/빈 상태
- `Sub/PlanDetailAddSpotBookmarkListView.swift` — 북마크 리스트 + 로딩/빈 상태
- `Sub/PlanDetailAddSpotSpotRow.swift` — `TouristSpot` → `TabiSpotRow` 어댑터 (검색/즐겨찾기 두 탭 공용)
- `Sub/PlanDetailAddSpotEmptyState.swift` — 아이콘 + 제목 + 설명 3요소 빈 상태 (검색 안내 / 검색 결과 없음 / 북마크 없음 3가지 문구를 파라미터로 받음)

**Resource**
- `Strings.Plan.spotAddSearchTabTitle = "観光地検索"` — 기존에 동일 문구 없음. 나머지 문구는 전부 기존 재사용

### 재사용
- **Presentation/AddToItinerary/Sub**: `AddToItineraryTimeConfigView`, `AddToItineraryTimeForm` — Step 2 전체를 그대로 사용 (같은 Presentation 모듈 내 `internal` 접근이라 import 없이 참조 가능). **수정하지 않는다**
- **Presentation/Plan/Model**: `TravelPlan+.swift`의 `dayCount` / `dayDates` — 시트에 넘길 선택 일자 `Date` 산출
- **Presentation/PlanDetail**: `PlanDetailMock.swift`의 `TravelPlan.mock` / `TravelPlanDetail.mock` — Preview에 재사용 (신규 Mock 파일 없음)
- **Presentation/Extension**: `Date+.swift`의 `planDayHeaderTitle`
- **DesignSystem**: `TabiSearchField(placeholder:text:focus:onSubmit:)`, `TabiSpotRow`, `TabiLabel`, `TabiChip`(탭바 시각 언어 참고), `TabiPressStyle`, `TabiColor`, `.tabiRadiusMd/.tabiRadiusFull`, `.tabiStandard/.tabiFast`
- **Domain**: `TouristSpotUseCaseProtocol.searchByKeyword(keyword:pageNo:)`, `BookmarkUseCaseProtocol.fetch()`, `TravelPlanDetailUseCaseProtocol.fetch/add`, 엔티티 `TouristSpot` / `Bookmark` / `TravelPlanDetail` / `TravelPlanDetailSpot`
- **Domain (Preview)**: `TestTouristSpotUseCase.searchResults`, `TestBookmarkUseCase.bookmarks`, `TestTravelPlanDetailUseCase.details` — 그대로 사용, 더블 수정 없음
- **Core**: `AppLogger.view`, `String.removingBracketedTags`
- **Resource**: `Strings.Plan.spotAddButtonTitle`(시트 타이틀), `Strings.Bookmark.title`(즐겨찾기 탭 라벨) / `emptyTitle` / `emptyDescription`, `Strings.Map.searchPlaceholder` / `searchEmptyDescription` / `searchResultEmptyTitle` / `searchResultEmptyDescription`, `Strings.Plan.dayChipTitle`, `Strings.AddToItinerary.*`(TimeConfigView 내부에서 사용)

### 수정
- `Projects/Presentation/Sources/PlanDetail/PlanDetailFeature.swift`
  - State: `@Presents var addSpotState: PlanDetailAddSpotFeature.State?` 추가 (선언 순서 규칙상 `fileprivate var hasStartedLoading` 다음, 즉 State 최하단)
  - Action: `case addSpot(PresentationAction<PlanDetailAddSpotFeature.Action>)` 추가 (하위 액션이므로 마지막)
  - `.addSpotButtonTapped`의 `// TODO: 스팟 추가 플로우 연결` 제거 → `addSpotState` 생성
  - `.addSpot(.presented(.spotAdded))` 수신 시 시트 닫기 + `fetchTravelPlanDetailEffect(id:)` 재호출
  - body 마지막에 `.ifLet(\.$addSpotState, action: \.addSpot) { PlanDetailAddSpotFeature() }`
- `Projects/Presentation/Sources/PlanDetail/PlanDetailView.swift`
  - `private let store` → `@Bindable private var store` (`$store.scope`를 쓰려면 필수)
  - 루트에 `.sheet(item: self.$store.scope(state: \.addSpotState, action: \.addSpot))` 추가
- `Projects/Resource/Sources/Strings/Strings.swift` — `Strings.Plan`에 검색 탭 라벨 1개 추가
- `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailAddSpotButton.swift` — **수정 없음** (이미 `action` 클로저만 노출)

### 삭제
- 없음
- `AddToItineraryFeature` / `AddToItineraryView` / `AddToItineraryPlanListView` / `AddToItineraryDayRow`는 손대지 않는다 (spec 제약). 관광지 상세 → 일정 추가 경로는 그대로 유지된다

---

## 기술적 결정사항

- **`AddToItineraryFeature`를 재사용하지 않고 새 Feature를 만든다**: `AddToItineraryFeature.State`는 `touristSpot`을 `let`으로 받아 생성되고 Step 1이 "일정 선택 → 날짜 선택"에 고정돼 있다. 이번 화면은 진입 시 plan/day가 이미 확정되고 반대로 spot이 미정이라 State의 확정 순서 자체가 뒤집힌다. 기존 Feature에 모드 플래그를 넣어 분기시키면 Step 1이 3가지(일정 선택 / 키워드 검색 / 북마크)로 늘어나 두 화면 모두의 로직이 얽힌다. Step 2는 완전히 동일하므로 **뷰 계층(`AddToItineraryTimeConfigView` / `AddToItineraryTimeForm`)만 공유**하는 선에서 끊는다
- **`makeDefaultTimeRange` 로직은 새 Feature에 동일 구현으로 복제한다**: 원본은 `AddToItineraryFeature`의 `private extension` 안 `static` 메서드라 외부에서 호출 불가하고, 공유 헬퍼로 추출하려면 spec이 금지한 `AddToItineraryFeature` 수정이 필요하다. 10줄 남짓의 순수 계산 함수이므로 복제 비용이 결합 비용보다 낮다고 판단. (두 화면이 안정화된 뒤 `Presentation/Extension`이나 Domain 헬퍼로 합치는 것은 별도 작업)
- **Step 2 요약 영역의 `planTitle` 슬롯에 "선택한 스팟 이름"을 넣는다**: `AddToItineraryTimeConfigView`는 `planTitle`(굵게) + `dayTitle · dateTitle`(작게) 구조다. 이번 화면에서 사용자는 이미 어떤 일정에 추가하는지 알고 있고, 방금 고른 스팟이 맞는지를 확인해야 한다. 파라미터명 의미와 표시 내용이 어긋나지만, 이름을 바꾸면 `AddToItineraryView`까지 수정해야 해서 spec 제약을 위반한다. `dayTitle`/`dateTitle`은 의미 그대로 사용
- **스팟 행은 `MapSearchResultRowView`를 재사용하지 않고 새 어댑터를 만든다**: 두 화면에서 공유하려면 folder-structure 규칙상 `DesignSystem`으로 승격해야 하는데, 이 뷰는 `Domain.TouristSpot`을 직접 받으므로 `DesignSystem`(→ Core/Resource만 의존)에 올릴 수 없다. 다른 화면의 `Sub/`를 가로질러 참조하면 "Sub는 해당 화면 전용" 전제가 깨진다. 새 어댑터는 `TabiSpotRow`에 `japaneseTitle.removingBracketedTags` / `koreanTitle?.removingBracketedTags`를 넘기는 얇은 래퍼로, `MapSearchResultRowView`의 `formattedDistance` private 확장은 복제하지 않고 `distance: nil`을 넘긴다 (키워드 검색·북마크 모두 기준 좌표가 없어 거리값이 의미 없음 — `BookmarkView`도 동일하게 `nil` 사용)
- **검색은 입력 즉시가 아니라 `onSubmit` 시점에 실행한다**: `TabiSearchField`가 이미 `submitLabel(.search)` + `onSubmit`을 제공하고, `MapFeature.searchSubmitted`와 동작이 일치한다. 타이핑 debounce 방식은 관광공사 API 호출 수를 키 입력만큼 늘리고 취소 처리 코드가 추가로 필요하다
- **빈 키워드 처리 (spec 미확정 항목 확정)**: ① `searchSubmitted` 시 `keyword.trimmed.isEmpty`면 API를 호출하지 않고 `.none` 반환. ② 바인딩으로 키워드가 빈 문자열이 되는 순간 `searchResults`를 비우고 진행 중 검색을 취소한다. 검색어를 지웠는데 이전 결과가 남아 "지금 보이는 목록이 무엇의 결과인지" 모호해지는 상태를 없애기 위함이며, 이때는 "地名やスポット名で検索できます" 안내 빈 상태를 보여준다
- **검색 결과 페이지네이션 없음**: `pageNo: 1` 고정. spec의 Acceptance Criteria에 무한 스크롤 요구가 없고, 시트 안 목록이라 스크롤 길이가 짧다. `MapFeature`의 next-page 상태 3종(`searchPage` / `hasMoreSearchResults` / `isSearchNextPageLoading`)을 들여오지 않아 State가 단순해진다
- **북마크는 탭 진입 시마다 재조회한다**: SwiftData 로컬 조회라 비용이 낮고, 다른 화면에서 북마크를 지운 뒤 돌아온 경우에도 항상 최신 목록을 보장한다. `cancellable(id:cancelInFlight: true)`로 연타 시 중복 Effect를 정리하고, 조회 중에도 직전 목록은 그대로 렌더링해 깜빡임을 막는다
- **저장 스팟의 `subtitle`은 `koreanTitle`을 쓴다**: `AddToItineraryFeature`는 `DetailFeature`가 이미 조회해 둔 `detail.address`를 넘기지만, 이번 화면의 `TouristSpot`(검색/북마크 결과)에는 주소 필드가 없다. 주소를 채우려면 스팟 선택마다 `touristSpotUseCase.fetchDetail`을 추가 호출해야 하는데, 네트워크 지연·실패 경로가 늘고 spec의 의존성 목록에도 없다. `PlanDetailSpotRow`의 subtitle은 옵셔널이라 한국어명이 없으면 `nil`로 두면 된다
- **`dayIndex`·`date`·기존 `TravelPlanDetail`은 시트 생성 시점에 값으로 주입한다**: 시트 안에서 재조회하지 않는다(spec). `PlanDetailFeature`가 이미 보유한 `travelPlanDetail`을 그대로 넘기고, 새 Feature는 그 값으로 기본 시간대와 `order`만 계산한다. 조회 Effect가 하나 줄고 Step 2 진입 시 로딩 스피너가 필요 없다
- **`order`는 저장 시점에 계산한다**: 주입받은 detail에서 `dayIndex`가 같은 스팟 개수를 세어 사용 (`AddToItineraryFeature.saveButtonTapped`와 동일)
- **저장 성공 후 시트를 닫는 주체는 부모**: 자식은 `.spotAdded`만 보내고 State를 유지한다(`AddToItineraryFeature`와 동일). `PlanDetailFeature`가 `addSpotState = nil` + 재조회를 한 번에 처리해, "닫힘"과 "목록 갱신"이 같은 액션에서 일어나 중간 상태가 노출되지 않는다
- **저장 후 로컬 State 병합이 아니라 전체 재조회**: `spotDeleted`는 낙관적 제거였지만, 추가는 SwiftData가 확정한 결과(정렬 포함)를 그대로 반영해야 순서가 어긋나지 않는다. `fetchTravelPlanDetailEffect`가 이미 존재하므로 신규 코드가 사실상 없다
- **탭 UI는 `TabiChip`이 아니라 전용 탭바로 만든다**: `TabiChip`은 캡슐형 필터 칩(다중 선택 필터 문맥)이고, 여기 필요한 것은 2분할 세그먼트다. `TabiChip` 2개를 나열하면 "필터"로 오인되고 폭도 균등하지 않다. 색/타이포는 `TabiChip`과 동일 토큰(`tabiPrimary`/`tabiSurface`/`tabiBorder`, `captionMBold`/`captionM`)을 써서 시각 언어를 맞추고, 재사용 가능성이 낮아 `DesignSystem` 승격은 하지 않는다 (spec 제약)
- **시트 detent는 `.large` 단독**: 검색 필드 + 키보드 + 결과 리스트가 동시에 보여야 해서 `.medium`은 사용성이 떨어진다. `DetailView`의 `[.medium, .large]`와 다른 선택이지만, 그쪽은 Step 1이 짧은 일정 목록이라 상황이 다르다
- **Step 전환 시 검색 State는 초기화하지 않는다**: 뒤로 가기(`backButtonTapped`)로 Step 1에 돌아왔을 때 직전 검색 결과와 탭이 유지돼야 다른 스팟을 곧바로 고를 수 있다. `selectedSpot`만 비운다
- **`isSaving` 중 중복 저장 차단**: `guard state.isSaving == false` (기존 패턴 동일). 실패 시 `isSaving = false`만 되돌리고 시트/입력값은 유지해 재시도 가능
- **Feature/State/Action은 `public`, View는 `internal`**: `AddToItineraryFeature`(public) / `AddToItineraryView`(internal)와 동일 수준을 따른다
- **에러는 전부 `AppLogger.view.log(.error, ...)` + 빈 결과 폴백**: 알림 UI를 새로 만들지 않는다 (spec의 실패 처리 명세와 기존 3개 Feature 관행 일치)

---

## 구현 순서

### Phase 1. Resource
1. `Projects/Resource/Sources/Strings/Strings.swift`
   - `Strings.Plan`에 `spotAddSearchTabTitle = "観光地検索"` 추가 (주석: `/// 스팟 추가 시트 - 관광지 검색 탭`)
   - 즐겨찾기 탭 라벨은 `Strings.Bookmark.title`("保存済み"), 시트 타이틀은 `Strings.Plan.spotAddButtonTitle`("スポットを追加"), 검색 placeholder는 `Strings.Map.searchPlaceholder`를 재사용 — 신규 정의하지 않는다

### Phase 2. Presentation — 새 Feature (Reducer)
1. `Projects/Presentation/Sources/PlanDetailAddSpot/PlanDetailAddSpotFeature.swift` 신규
   - 의존성: `@Dependency(\.touristSpotUseCase)`, `@Dependency(\.bookmarkUseCase)`, `@Dependency(\.travelPlanDetailUseCase)`, `@Dependency(\.dismiss)`
   - `State` (선언 순서: 공개 → fileprivate → @Presents)
     - 주입값: `planId: UUID`, `dayIndex: Int`, `date: Date` (전부 `let`)
     - `step: Step = .selectingSpot`, `tab: Tab = .search`
     - 검색: `searchKeyword: String = ""`, `searchResults: [TouristSpot] = []`, `isSearchLoading: Bool = false`, `hasSearched: Bool = false`
     - 즐겨찾기: `bookmarks: [Bookmark] = []`, `isBookmarkLoading: Bool = false`
     - 선택/시간: `selectedSpot: TouristSpot? = nil`, `startTime: Date = Date()`, `endTime: Date = Date()`, `isSaving: Bool = false`
     - `fileprivate let existingDetail: TravelPlanDetail?`
     - 중첩 `enum Step { case selectingSpot, configuringTime }`, `enum Tab { case search, bookmark }`
     - 계산 프로퍼티: `durationMinutes`, `isSaveEnabled`(= `endTime > startTime`) — `AddToItineraryFeature.State`와 동일 구현
     - `public init(planId:dayIndex:date:detail:)`
   - `Action: BindableAction, Equatable` (선언 순서: 바인딩 → 생명주기 → 인터랙션 → 결과 → 하위)
     - `binding(BindingAction<State>)`
     - `tabSelected(State.Tab)`, `searchSubmitted`, `spotRowTapped(TouristSpot)`, `backButtonTapped`, `closeButtonTapped`, `saveButtonTapped`
     - `searchResultsResult([TouristSpot])`, `bookmarksResult([Bookmark])`, `saveFailed`, `spotAdded`
   - `body`: `BindingReducer()` → `Reduce`
     - `.binding(\.searchKeyword)`에서 키워드가 빈 문자열이면 `searchResults = []`, `hasSearched = false`, `.cancel(id: CancelID.search)` 반환
     - `.tabSelected`: 같은 탭이면 `.none`, `.bookmark`로 전환 시 `isBookmarkLoading = true` + 북마크 조회 Effect(`cancellable(cancelInFlight: true)`)
     - `.searchSubmitted`: 트림 후 빈 문자열이면 `.none` / 아니면 `isSearchLoading = true`, `hasSearched = true`, 검색 Effect(`cancellable(cancelInFlight: true)`)
     - `.spotRowTapped(spot)`: `selectedSpot = spot`, 기본 시간대 계산해 `startTime`/`endTime` 설정, `step = .configuringTime`
     - `.backButtonTapped`: `selectedSpot = nil`, `step = .selectingSpot`
     - `.closeButtonTapped`: `.run { await dismiss() }`
     - `.saveButtonTapped`: `isSaveEnabled && isSaving == false && selectedSpot != nil` 가드 → `isSaving = true` → `order` 계산 → `TravelPlanDetailSpot` 생성 → 저장 Effect
     - 결과 액션들은 로딩 플래그 해제 + 값 대입, `.saveFailed`는 `isSaving = false`, `.spotAdded`는 `.none`
   - `private enum CancelID { case search, fetchBookmarks }` (파일 하단, `// MARK: - CancelID`)
   - `// MARK: - Method` `private extension`
     - `searchEffect(keyword:)` — 실패 시 `AppLogger.view.log(.error, ...)` + `searchResultsResult([])`
     - `fetchBookmarksEffect()` — 실패 시 로깅 + `bookmarksResult([])`
     - `saveEffect(planId:spot:)` — `travelPlanDetailUseCase.add(TravelPlanDetail(planId:spots:[spot]))`, 성공 `spotAdded` / 실패 로깅 + `saveFailed`
     - `static func makeDefaultTimeRange(date:dayIndex:detail:)` — 마지막 스팟 종료 시각 이후, 없으면 09:00, 종료는 +60분

### Phase 3. Presentation — 새 View 계층
1. `Sub/PlanDetailAddSpotSpotRow.swift` — `spot: TouristSpot` + `onTap` → `TabiSpotRow`(제목 `removingBracketedTags` 적용, `distance: nil`)
2. `Sub/PlanDetailAddSpotEmptyState.swift` — `systemImageName` / `title` / `description` 파라미터, 가운데 정렬
3. `Sub/PlanDetailAddSpotTabBar.swift` — `selectedTab` + `onTabSelected`, 2분할 균등 폭, 선택 상태에 `.tabiFast` 애니메이션
4. `Sub/PlanDetailAddSpotSearchListView.swift`
   - `TabiSearchField(placeholder: Strings.Map.searchPlaceholder, text:focus:onSubmit:)`
   - 로딩 시 `ProgressView`, 미검색 시 `Strings.Map.searchEmptyDescription` 안내, 결과 0건이면 `Strings.Map.searchResultEmpty*`
   - 결과는 `List` + `.listStyle(.plain)` + 구분선/배경 제거 (`BookmarkView` 관행)
5. `Sub/PlanDetailAddSpotBookmarkListView.swift` — 로딩/빈 상태(`Strings.Bookmark.empty*`)/목록 3분기, 행은 4번과 동일 컴포넌트
6. `PlanDetailAddSpotView.swift`
   - `@Bindable private var store`
   - 헤더: Step 2일 때만 back 버튼 + `Strings.Plan.spotAddButtonTitle` + 닫기 버튼 (`AddToItineraryView.header()`와 동일 레이아웃)
   - Step 1: 탭바 + 선택된 탭 리스트, Step 2: `AddToItineraryTimeConfigView(planTitle: 선택 스팟 일본어명, dayTitle: Strings.Plan.dayChipTitle(dayIndex + 1), dateTitle: date.planDayHeaderTitle, startTime: $store.startTime, endTime: $store.endTime, durationMinutes:isSaveEnabled:isSaving:onSaveTapped:)`
   - Step 전환 `.transition(.move(edge:))` + `.animation(.tabiStandard, value: store.step)`
   - `body` 50줄 초과 시 `private extension`의 `header()` / `stepContent()`로 분리
   - `#Preview` — `TestTouristSpotUseCase.searchResults`, `TestBookmarkUseCase.bookmarks`, `TestTravelPlanDetailUseCase.details`에 `TravelPlanDetail.mock` 주입

### Phase 4. Presentation — PlanDetail 연결
1. `PlanDetailFeature.swift`
   - State에 `@Presents var addSpotState: PlanDetailAddSpotFeature.State?`
   - Action에 `case addSpot(PresentationAction<PlanDetailAddSpotFeature.Action>)`
   - `.addSpotButtonTapped`: `guard state.plan.dayDates.indices.contains(state.selectedDayIndex)` 후 `addSpotState` 생성 (`planId` / `dayIndex` / `date` / `detail: state.travelPlanDetail`)
   - `.addSpot(.presented(.spotAdded))`: `addSpotState = nil` + `fetchTravelPlanDetailEffect(id: state.plan.id)`
   - `.addSpot`: `.none`
   - body 마지막 `.ifLet(\.$addSpotState, action: \.addSpot) { PlanDetailAddSpotFeature() }`
2. `PlanDetailView.swift`
   - `@Bindable private var store`로 변경 (`init`의 `self.store = store` 유지)
   - `.sheet(item: self.$store.scope(state: \.addSpotState, action: \.addSpot)) { PlanDetailAddSpotView(store: $0).presentationDetents([.large]).presentationDragIndicator(.visible) }`

### Phase 5. 빌드/검증
1. `tuist generate` — Phase 2~3에서 7개 파일이 추가되므로 필수
2. 빌드 후 시나리오 확인: "+" → 검색 탭 검색 → 행 탭 → 시간 설정 → 저장 → 시트 닫힘 + 해당 Day 목록에 즉시 반영 / 즐겨찾기 탭 동일 경로 / 종료 ≤ 시작일 때 저장 버튼 비활성 / 검색어 삭제 시 안내 빈 상태 복귀

---

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
- [ ] PlanDetail "+" 탭 시 `.large` 시트가 열리고 "観光地検索" / "保存済み" 탭이 보인다
- [ ] 키워드 제출 시 `searchByKeyword(keyword:pageNo: 1)` 결과가 `TabiSpotRow` 리스트로 표시되고, 0건이면 결과 없음 빈 상태가 보인다
- [ ] 즐겨찾기 탭 진입 시 `bookmarkUseCase.fetch()` 결과가 표시되고, 0건이면 북마크 빈 상태가 보인다
- [ ] 행 탭 → Step 2 전환, 기본 시작 시각이 해당 Day 마지막 스팟 종료 시각(없으면 09:00)으로 채워진다
- [ ] `endTime <= startTime`이면 저장 버튼 비활성
- [ ] 저장 성공 시 시트가 닫히고 PlanDetail 해당 Day 목록이 재조회되어 새 스팟이 보인다
- [ ] 저장 실패 시 시트가 유지되고 `isSaving`이 해제되며 `AppLogger.view` 에러 로그가 남는다
- [ ] `AddToItineraryFeature` / `AddToItineraryView` / 세 UseCase 프로토콜에 변경이 없다
- [ ] `tuist generate` 후 빌드 성공

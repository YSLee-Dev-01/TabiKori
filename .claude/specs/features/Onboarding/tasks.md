# Tasks: Onboarding (코치마크형 전환)

## 참조
- spec: `.claude/specs/features/Onboarding/spec.md`
- plan: `.claude/specs/features/Onboarding/plan.md`

## Task 목록

### Phase 1. Resource

#### [x] Task 1 — `Strings.swift`
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- 기존 `public extension Strings.Onboarding` 블록 하단에 코치마크 유도 툴팁 문구 7개 추가: `homeCategoryCoachMark`, `mapSearchResultCoachMark`, `planCardCoachMark`, `planDetailDayChipCoachMark`, `agreementPolicyCoachMark`, `agreementCheckBoxCoachMark`, `agreementStartCoachMark`
- 앱 표시 언어(일본어)에 맞춰 값은 일본어로 작성, 한국어 설명은 기존 컨벤션대로 `///` 주석으로 병기
- `nextButtonTitle`은 Phase 6(Step View 수정)에서 모든 참조가 제거된 것을 확인한 뒤 최종 삭제(`startButtonTitle`은 계속 사용하므로 유지)

---

### Phase 2. Presentation — Entity

#### [x] Task 2 — `OnboardingCoachMark.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Entity/OnboardingCoachMark.swift`
- `enum OnboardingCoachMark: Int, CaseIterable, Hashable` 정의, 7 케이스: `homeCategory`, `mapSearchResult`, `planCard`, `planDetailDayChip`, `agreementPolicyButton`, `agreementCheckBox`, `agreementStartButton`
- 각 케이스가 속한 `step: OnboardingStep` 제공
- 각 케이스의 유도 툴팁 문구(`tooltip`, Task 1의 Strings 참조), 하이라이트 홀 모양(`cornerRadius`, `padding`) 제공
- `next: OnboardingCoachMark?`(다음 코치마크, 마지막이면 `nil`), `isLast: Bool` 제공

---

#### [x] Task 3 — `OnboardingStep.swift` (수정)
**파일**: `Projects/Presentation/Sources/Onboarding/Entity/OnboardingStep.swift`
- `isLast` 프로퍼티 삭제(사용처 소멸 — 진행 완료 판단은 `OnboardingCoachMark.isLast`로 이동)
- `title` / `description` / `id`는 그대로 유지

---

### Phase 3. Presentation — 좌표 측정 인프라

#### [x] Task 4 — `OnboardingHighlightAnchorKey.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingHighlightAnchorKey.swift`
- `PreferenceKey` 정의: `defaultValue: [OnboardingCoachMark: Anchor<CGRect>] = [:]`
- `reduce`는 `merge(uniquingKeysWith: { _, new in new })` 사용(`PlanDetailView.swift:228`의 `DayHeaderOffsetPreferenceKey` 선례 패턴 참고)
- `// MARK: - View` 섹션에 `View` extension으로 `onboardingHighlight(_:shape:)` 모디파이어 추가 — `anchorPreference` 부착과 `.id(coachMark)`(스크롤 타겟팅용)를 한 번에 처리

---

### Phase 4. Presentation — 오버레이 컴포넌트

#### [x] Task 5 — `OnboardingTooltipView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingTooltipView.swift`
- 말풍선(꼬리 포함) 형태의 유도 툴팁 뷰
- 하이라이트 홀 위치 기준 위/아래 자동 배치 파라미터
- 좌우 화면 경계 클램프 처리(20pt)

---

#### [x] Task 6 — `OnboardingSpotlightOverlay.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingSpotlightOverlay.swift`
- 입력 파라미터: `highlightRect`, `containerSize`, `coachMark`
- 딤 레이어: `Rectangle().fill(TabiColor.tabiScrim.opacity(0.6))` + reverse mask(`RoundedRectangle` + `.blendMode(.destinationOut)` + `.compositingGroup()`), `.allowsHitTesting(false)`
- 홀 외곽 스트로크(`TabiColor.tabiPrimary`)
- 홀을 제외한 top/bottom/leading/trailing 4개 탭 차단 밴드: `Color.clear.contentShape(Rectangle()).onTapGesture {}`, 각 변 크기는 `max(0, ...)`로 클램프해 배치(홀 영역 자체는 히트테스트 요소 없음 → 아래 실제 버튼이 탭을 직접 받음)
- `OnboardingTooltipView`(Task 5) 배치
- `body`가 50줄 초과 시 `// MARK: - View` `private extension`으로 `dimLayer()` / `blockingBands()` / `tooltip()` 분리

---

### Phase 5. Presentation — Feature

#### [x] Task 7 — `OnboardingFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/Onboarding/OnboardingFeature.swift`
- **State**: `currentStepIndex` / `reachedStepIndex` / `visibleSteps` 삭제. `currentCoachMark: OnboardingCoachMark = .homeCategory` 신규 추가(진행의 단일 소스). `currentStep: OnboardingStep`은 `self.currentCoachMark.step`로 파생되는 computed로 변경. `hasViewedPolicy` / `isAgreed` / `isPolicyWebViewPresented` / `isPolicyLoadFailed` / `policyReloadTrigger` / `homeSelectedCategory` / `planDetailSelectedDayIndex`는 유지. `CGRect` 등 레이아웃 타입은 State에 포함하지 않음
- **Action**: `pageSelected(Int)`, `nextButtonTapped` 삭제. `mapSearchResultTapped`, `planCardTapped`, `coachMarkAdvanced` 신규 추가
  - `homeCategoryTapped(CategoryType)` — 토글이 아닌 단순 선택으로 변경 후 지연 advance
  - `mapSearchResultTapped` — 지연 advance
  - `planCardTapped` — 지연 advance
  - `planDetailDayTapped(Int)` — 선택 Day 갱신 후 지연 advance
  - `policyViewButtonTapped` — 시트 표시(advance 없음)
  - `policyWebViewDismissed` — `hasViewedPolicy = true` 반영, 지연 없이 즉시 advance(시트 dismiss 애니메이션이 이미 있으므로)
  - `policyRetryTapped` — 유지
  - `agreementCheckBoxTapped` — `guard state.hasViewedPolicy` 후 `isAgreed = true`(토글 아님) + 지연 advance
  - `startButtonTapped` — `guard state.isAgreed` → `onboardingUsecase.markAsCompleted()` 호출 → `.send(.delegate(.completed))`
  - `policyLoadFailed` — `AppLogger.network.log(.error, ...)` 유지
  - `coachMarkAdvanced` — `state.currentCoachMark = state.currentCoachMark.next ?? state.currentCoachMark`
  - `delegate(Delegate)` — 유지
- 각 탭 액션 진입부에 `guard state.currentCoachMark == .{해당 마크} else { return .none }` 방어 가드 추가(오버레이가 이미 막지만 리듀서에서도 이중 보장)
- `body`는 `Reduce { }` 단일 블록(BindingReducer·하위 Reducer 없음)
- `CancelID` enum과 `advanceEffect()`(0.3초 지연 `.run { try await Task.sleep(for: .seconds(0.3)); await send(.coachMarkAdvanced) }.cancellable(id: CancelID.coachMarkAdvance)`, `RootFeature.swift:138`/`HomeFeature.swift:96` 패턴 참고)는 `// MARK: - Method` `private extension OnboardingFeature`로 분리

---

### Phase 6. Presentation — Step View 수정

#### [x] Task 8 — `OnboardingStepFrame.swift` (수정)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingStepFrame.swift`
- `ScrollViewReader` 도입
- `scrollTarget: OnboardingCoachMark?` 파라미터 추가
- `.scrollDisabled(true)` 적용(딤이 스크롤 제스처를 이미 차단하므로 의도를 코드로 명시, 프로그래매틱 `scrollTo`는 계속 동작)
- `.task(id: scrollTarget)`에서 `proxy.scrollTo(target, anchor: .center)` 수행

---

#### [x] Task 9 — `OnboardingHomeStepView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingHomeStepView.swift`
- 첫 번째 카테고리 칩(`CategoryType.allItems.first` 기준 index 0)에 `.onboardingHighlight(.homeCategory)` 부착

---

#### [x] Task 10 — `OnboardingMapStepView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingMapStepView.swift`
- `onSearchResultTapped` 콜백 파라미터 추가
- 첫 번째 검색 결과 카드(`MapSearchResultRowView`)에 `.onboardingHighlight(.mapSearchResult)` 부착
- 기존에 비어있던 `onTapped: {}` 콜백을 `onSearchResultTapped`로 연결

---

#### [x] Task 11 — `OnboardingPlanStepView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingPlanStepView.swift`
- `onPlanTapped` 콜백 파라미터 추가
- 첫 번째 `PlanCardView`에 `.onboardingHighlight(.planCard)` 부착
- 기존에 비어있던 `onTapped: {}` 콜백을 `onPlanTapped`로 연결

---

#### [x] Task 12 — `OnboardingPlanDetailStepView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingPlanDetailStepView.swift`
- 두 번째(index 1) Day 칩에 `.onboardingHighlight(.planDetailDayChip)` 부착

---

#### [x] Task 13 — `OnboardingAgreementStepView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingAgreementStepView.swift`
- `onStartTapped` 콜백 파라미터 추가
- "始める"(시작하기) `TabiButton`을 스텝 내부 최하단으로 이동(`isExpanded: true`), `.disabled(self.isAgreed == false)` 유지
- "プライバシーポリシーを見る"(개인정보처리방침 보기) 버튼 → `.onboardingHighlight(.agreementPolicyButton)`
- `OnboardingAgreementCheckBox` → `.onboardingHighlight(.agreementCheckBox)`
- "始める" 버튼 → `.onboardingHighlight(.agreementStartButton)`
- 세 하이라이트는 순서대로 이동(정책 보기 → 체크박스 → 시작하기)
- `privacyPolicyUnviewedGuide` 캡션은 `hasViewedPolicy == false`일 때만 노출되는 기존 조건 유지

---

### Phase 7. Presentation — 루트 뷰

#### [x] Task 14 — `OnboardingView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Onboarding/OnboardingView.swift`
- `TabView`와 `bottomBar()` 내 "다음" `TabiButton` 블록 제거
- `stepView(store.currentStep)` 단일 렌더 + `.id(store.currentStep)` + `.transition(.opacity)` + `.animation(.tabiStandard, value: store.currentStep)` 적용(오프셋 전환 없이 opacity만 사용)
- `.overlayPreferenceValue(OnboardingHighlightAnchorKey.self) { anchors in GeometryReader { proxy in ... }.ignoresSafeArea() }`로 `OnboardingSpotlightOverlay`(Task 6) 합성
- `anchors[store.currentCoachMark]`가 `nil`이면 아무것도 렌더하지 않음(좌표 측정 전 오버레이 숨김 보장)
- `TabiPageIndicator`는 `.overlay(alignment: .bottom)`으로 오버레이보다 위에 배치, `.allowsHitTesting(false)`
- `.sheet` 웹뷰 블록(`OnboardingPolicyWebView`)은 기존 그대로 유지
- `#Preview` 갱신

---

### Phase 8. 빌드 · 검증

#### [x] Task 15 — Tuist 프로젝트 재생성
- 신규 `.swift` 파일 4개(`OnboardingCoachMark.swift`, `OnboardingHighlightAnchorKey.swift`, `OnboardingTooltipView.swift`, `OnboardingSpotlightOverlay.swift`) 반영을 위해 `tuist install` → `tuist generate` 실행

---

#### [x] Task 16 — 빌드 및 수동 검증
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` 빌드 성공 확인
- 온보딩 미완료 상태로 앱 실행 → 홈 스텝부터 시작, 카테고리 칩 외 영역 탭 시 스텝이 넘어가지 않음을 확인
- 7단계 코치마크(`homeCategory → mapSearchResult → planCard → planDetailDayChip → agreementPolicyButton → agreementCheckBox → agreementStartButton`)를 순서대로 실제 탭하여 통과 → TabBar 진입 확인
- 약관동의 스텝에서 정책 보기 → 웹뷰 열람/닫기 → 체크박스 → 시작하기 순서로 하이라이트가 이동하며, 각 단계는 실제 탭 없이는 진행되지 않음을 확인
- "시작하기" 탭 시 `markAsCompleted()` 호출 후 TabBar 진입, 앱 재실행 시 온보딩이 다시 표시되지 않음을 확인
- 홀 밖 탭·스와이프로는 스텝이 진행되지 않음을 확인
- 작은 기기(iPhone SE)에서 하이라이트 대상이 화면 밖에 있을 때 자동 스크롤(`scrollTo`)로 노출되는지 확인

---

## 체크리스트

### 품질 (DoD)
- [x] `tuist generate` 및 빌드 성공
- [x] `TabView` / 스와이프 / "다음" 버튼 코드가 `Onboarding` 폴더에서 완전히 제거됨
- [x] `OnboardingFeature.State`에 `CGRect` 등 레이아웃 타입이 없음(좌표는 View 계층에만 존재)
- [x] `Strings.Onboarding.nextButtonTitle` 참조 0건
- [x] `.claude/rules/swift-style.md` 준수: State/Action 선언 순서, `// MARK: - View` / `// MARK: - Method` + `private extension` 분리, `self` 명시, `body` 50줄 이하
- [x] 테스트 타겟 미구성 상태(프로젝트 현황) — 해당 없음

### 기능 (AC)
- [ ] 온보딩 미완료 상태로 앱 실행 시 홈 스텝이 표시되고, 카테고리 칩 외 영역을 탭해도 스텝이 넘어가지 않는다
- [ ] 홈 스텝에서 하이라이트된 카테고리 칩을 탭하면 지도 스텝으로 전환된다
- [ ] 지도 스텝에서 하이라이트된 검색 결과 카드를 탭하면 일정 스텝으로 전환된다
- [ ] 일정 스텝에서 하이라이트된 일정 카드를 탭하면 일정상세 스텝으로 전환된다
- [ ] 일정상세 스텝에서 하이라이트된 Day 칩을 탭하면 약관동의 스텝으로 전환된다
- [ ] 약관동의 스텝에서 "정책 보기" → 웹뷰 열람·닫기 → 체크박스 → "시작하기" 순서로 하이라이트가 이동하며, 각 단계는 실제 탭 없이는 넘어가지 않는다
- [ ] "시작하기" 탭 시 온보딩 완료 처리(`markAsCompleted`) 후 TabBar로 진입한다
- [ ] 앱을 재실행하면 온보딩이 다시 표시되지 않는다
- [ ] 각 체험 화면에서 실제 네트워크/DB/위치 호출 없이 더미 데이터만 표시된다

---

## 후속: 실제 Feature 재사용 전환

> `plan.md`의 "후속: 실제 Feature 재사용 전환" 섹션 참고. 코치마크가 가리키는 홈/지도/일정/일정상세를
> 더미 목업 Step View 대신 실제 Feature/View로 교체하는 작업.

#### [x] Task 17 — Domain Test UseCase 감사 (선행)
- `Test{Name}UseCase`(Location/TouristSpot/TravelPlan/TravelPlanDetail/Festival/ExchangeRate/SearchHistory/SubwayStation) 전부를 직접 Read해 `public init()`과 데이터 주입용 `public var` 공개 여부 확인
- `TestLocationUseCase`/`TestExchangeRateUseCase`에 `public init() {}`이 누락되어 다른 모듈(Presentation)에서 인스턴스화가 불가능한 버그 발견 → 추가(실제 `xcodebuild`에서 `'TestLocationUseCase' initializer is inaccessible due to 'internal' protection level` 에러로 확인)
- 나머지는 이미 공개되어 있어 수정 불필요

---

#### [x] Task 18 — `OnboardingMock.swift` 데이터 형태 확인
- 기존 `nearbySpots`/`searchResults`/`plan`/`plans`/`planDetail`이 Home/Map/Plan/PlanDetail 각 Test UseCase가 요구하는 데이터 형태와 그대로 일치함을 확인 → 데이터 추가 없음(재사용)

---

#### [x] Task 19 — `OnboardingHighlightAnchorKey.swift` 범용 키로 리팩터링
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingHighlightAnchorKey.swift`
- `PreferenceKey`의 `defaultValue`/`reduce` 키 타입을 `OnboardingCoachMark` → `AnyHashable`로 일반화
- `onboardingHighlight(_ key: AnyHashable)`로 모디파이어 시그니처 변경
- Swift 6 동시성 검사 대응: `Anchor<CGRect>`가 Sendable이 아니므로 `defaultValue`에 `nonisolated(unsafe)` 추가
- `Projects/Presentation/Sources/Onboarding/Entity/OnboardingCoachMark.swift`에 `anchorKey: AnyHashable` computed property 추가(홈/지도/일정/일정상세는 문자열 키, 약관동의 3종은 자기 자신을 키로 사용)
- `OnboardingView.swift`의 `anchors[store.currentCoachMark]` 조회를 `anchors[store.currentCoachMark.anchorKey]`로 변경
- `OnboardingAgreementStepView.swift`의 `.onboardingHighlight(.xxx)` 호출부를 `.onboardingHighlight(OnboardingCoachMark.xxx)`로 변경(`AnyHashable` 파라미터는 dot-shorthand로 타입 추론 불가)

---

#### [x] Task 20 — Home 실제 뷰 통합
**파일**: `Presentation/Sources/Home/HomeView.swift`(수정), `Presentation/Sources/Onboarding/Sub/OnboardingHomeHostView.swift`(신규)
- `HomeView.categoryView()`의 첫 번째 카테고리 칩에 `.onboardingHighlight("homeCategory")` 부착(프로덕션 화면 외관·동작 변화 없음)
- `OnboardingHomeHostView`: `HomeFeature.State()` + `locationUseCase`/`exchangeRateUseCase`/`touristSpotUseCase`/`festivalUseCase`/`travelPlanUseCase`/`analyticsCenter`를 Test 더블 + `OnboardingMock` 데이터로 `withDependencies` 오버라이드한 `Store`를 생성해 `HomeView` 렌더링
- `categoryTapped` 액션만 관찰해 `onCategoryTapped` 콜백을 호출하는 `private struct OnboardingHomeProgressReducer`(HomeFeature를 그대로 조립 + 관찰 Reduce 추가) 동일 파일에 포함

---

#### [x] Task 21 — Map 실제 뷰 통합 (지도 SDK만 목업)
**파일**: `Presentation/Sources/Map/MapView.swift`(수정), `Presentation/Sources/Onboarding/Sub/OnboardingMapHostView.swift`(신규), `Presentation/Sources/Onboarding/Sub/OnboardingMapBackgroundMockView.swift`(신규 — 기존 `OnboardingMapStepView.swift`의 지도 목업 시각 자산 대체)
- `MapView`에 `mapBackgroundOverride: AnyView? = nil` 이니셜라이저 파라미터 추가, `mapBackground()`에서 override 존재 시 이를 렌더링하고 기본값(nil)에서는 기존과 동일하게 `TabiMapView` 렌더링
- `MapView.searchResultList()`의 첫 검색 결과 행(지하철 결과 없을 때 index 0)에 `.onboardingHighlight("mapSearchResult")` 부착
- `OnboardingMapHostView`: 초기 `MapFeature.State`를 `mode: .result`/`searchResults: OnboardingMock.searchResults`로 채워 검색 없이 바로 결과 노출, `locationUseCase`/`touristSpotUseCase`/`subwayStationUseCase`/`searchHistoryUseCase`/`autoTranslateSearchUseCase`/`analyticsCenter` 오버라이드, `mapBackgroundOverride`로 `OnboardingMapBackgroundMockView` 주입
- `searchResultTapped` 액션만 관찰하는 `private struct OnboardingMapProgressReducer` 동일 파일에 포함

---

#### [x] Task 22 — Plan 실제 뷰 통합
**파일**: `Presentation/Sources/Plan/PlanView.swift`(수정), `Presentation/Sources/Onboarding/Sub/OnboardingPlanHostView.swift`(신규)
- `PlanView`에 `firstDisplayedPlanId`(진행중→예정→지난 순 첫 카드 id) computed property 추가, 해당 카드에만 `.onboardingHighlight("planCard")` 부착
- `OnboardingPlanHostView`: `PlanFeature.State()` + `travelPlanUseCase`/`travelPlanDetailUseCase`/`widgetSnapshotStore`를 Test 더블 + `OnboardingMock` 데이터로 오버라이드(위젯 App Group 스냅샷 쓰기 방지)
- `planTapped` 액션만 관찰하는 `private struct OnboardingPlanProgressReducer` 동일 파일에 포함

---

#### [x] Task 23 — PlanDetail 실제 뷰 통합
**파일**: `Presentation/Sources/PlanDetail/PlanDetailView.swift`(수정), `Presentation/Sources/Onboarding/Sub/OnboardingPlanDetailHostView.swift`(신규)
- `PlanDetailView.dayTabScroll()`의 둘째 날(index 1) Day 칩에 `.onboardingHighlight("planDetailDayChip")` 부착
- `OnboardingPlanDetailHostView`: 기존 `PlanDetailView`의 `#Preview`(`TestTravelPlanDetailUseCase` 주입) 패턴을 그대로 재사용해 `PlanDetailFeature.State(plan: OnboardingMock.plan)` + `travelPlanDetailUseCase` 오버라이드
- `onAppear`가 상세 조회 직후 자동 실행하는 `updateShareFileURLEffect`(공유 파일 생성)까지 추적해 `autoScrollToTodayUseCase`/`shoppingPlanItemUseCase`/`toolBarItemUseCase`/`travelPlanShareUseCase`도 함께 오버라이드(실제 프로세스에서는 `#Preview`와 달리 미지정 의존성이 `liveValue`로 풀리므로, `#Preview`보다 더 넓게 추적 필요)
- `dayButtonTapped` 액션만 관찰하는 `private struct OnboardingPlanDetailProgressReducer` 동일 파일에 포함

---

#### [x] Task 24 — `OnboardingView.swift` 배선 교체 + 목업 파일 삭제
**파일**: `Projects/Presentation/Sources/Onboarding/OnboardingView.swift`(수정)
- `stepView(_:)`의 `.home`/`.map`/`.plan`/`.planDetail` 분기를 각각 `OnboardingHomeHostView`/`OnboardingMapHostView`/`OnboardingPlanHostView`/`OnboardingPlanDetailHostView`로 교체(`.agreement`는 기존 `OnboardingAgreementStepView` 유지)
- `OnboardingHomeStepView.swift`/`OnboardingMapStepView.swift`/`OnboardingPlanStepView.swift`/`OnboardingPlanDetailStepView.swift` 4개 파일 삭제

---

#### [x] Task 25 — Tuist 재생성 및 빌드 검증
- 신규 6개 파일(`OnboardingHomeHostView`/`OnboardingMapHostView`/`OnboardingPlanHostView`/`OnboardingPlanDetailHostView`/`OnboardingMapBackgroundMockView` + 기존 미빌드 상태였던 `OnboardingHighlightAnchorKey`/`OnboardingSpotlightOverlay`/`OnboardingTooltipView`/`OnboardingCoachMark`)와 삭제 4개 파일 반영을 위해 `tuist install && tuist generate` 실행
- `xcodebuild build`로 컴파일 에러 확인 및 수정: `AnyHashable`은 dot-shorthand 타입 추론 불가(`OnboardingAgreementStepView`), `PreferenceKey.defaultValue` 동시성 안전성(`nonisolated(unsafe)`), `TestLocationUseCase`/`TestExchangeRateUseCase`의 `public init()` 누락(Task 17), `TabiColor`를 View로 직접 사용 불가(`Rectangle().fill(...)`로 수정)
- 이 세션의 `xcodebuild` CLI 실행은 터미널의 macOS "Developer Tools" 권한 미부여로 `ComposableArchitectureMacros`/`CasePathable` 매크로 플러그인이 spctl에 의해 rejected되어 완전한 빌드 통과를 CLI에서 확인하지 못함(기존에 알려진 환경 이슈, 이번 세션에서 수정한 모든 파일은 이 매크로 플러그인 오류 이전 단계에서 에러 없이 컴파일됨을 로그로 확인) — Xcode GUI 빌드로 최종 확인 필요

---

#### [ ] Task 26 — 수동 검증 (Xcode GUI 빌드 필요)
- 프로덕션 홈/지도/일정/일정상세 탭에서 기존 동작·외관 회귀 없음 확인
- 온보딩 체험 중 실제 네트워크/DB/위치 권한 요청이 발생하지 않는지 확인
- 7단계 코치마크 흐름이 실제 화면 위에서 기존과 동일하게 동작하는지 확인

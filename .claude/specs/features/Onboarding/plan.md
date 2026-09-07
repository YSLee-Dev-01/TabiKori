# Plan: Onboarding (코치마크형 전환)

## 참조 Spec
- `@.claude/specs/features/Onboarding/spec.md`

## 참조 Skill / Rule
- `@.claude/skills/feature/SKILL.md` (spec → plan → tasks → 구현 흐름)
- `@.claude/rules/swift-style.md` — State/Action 선언 순서, body 선언 순서, MARK 섹션, `private extension` 분리, `self` 명시, Strings/DesignSystem 재사용 원칙
- `@.claude/rules/folder-structure.md` — 단일 사용처 서브뷰는 `Presentation/{Feature}/Sub/`, 화면 전용 모델은 `Entity/`
- 신규 화면 생성이 아니므로 `create-feature` 스킬은 적용하지 않는다 (기존 `Onboarding` 폴더 전면 리팩터링)

---

## 현재 상태 파악

### 신규

| 경로 | 내용 |
|------|------|
| `Projects/Presentation/Sources/Onboarding/Entity/OnboardingCoachMark.swift` | 코치마크 7단계 enum (`Int` raw, `CaseIterable`, `Hashable`). 각 케이스가 속한 `OnboardingStep`, 유도 툴팁 문구, 하이라이트 홀 모양(코너 반경/여백), `next`, `isLast` 제공 |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingHighlightAnchorKey.swift` | `Anchor<CGRect>` 수집용 `PreferenceKey` + `View.onboardingHighlight(_:shape:)` 모디파이어 (anchorPreference + ScrollViewReader용 `.id`를 한 번에 부착) |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingSpotlightOverlay.swift` | 딤 + 하이라이트 홀(reverse mask) + 홀 외곽 스트로크 + 홀 밖 탭 차단 밴드 4개 + 툴팁 배치 |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingTooltipView.swift` | 말풍선(꼬리 포함) 유도 툴팁. 홀 위/아래 자동 배치, 좌우 클램프 |

### 재사용 (수정 없음)
- `Domain` — `OnboardingUseCase.isCompleted()/markAsCompleted()`, `TravelPlan`, `TravelPlanDetail`, `TouristSpot`, `CategoryType`
- `DesignSystem` — `TabiPageIndicator`, `TabiButton`, `TabiChip`, `TabiCard`, `TabiLabel`, `TabiSearchField`, `TabiSpotRow`, `TabiNavigationBar`, `TabiCircleIconButton`, `TabiRetryableEmptyState`, `TabiPressStyle`, `Animation.tabiStandard/tabiFast/tabiSpring`, `CGFloat.tabiRadius*`
- `Resource` — `TabiColor.tabiScrim`(딤 색), `TabiColor.tabiPrimary`(홀 외곽선), `TabiURL.privacyPolicy`
- `Presentation` 순수 표현 뷰 — `Map/Sub/MapSearchResultRowView`, `Plan/Sub/PlanCardView`, `PlanDetail/Sub/PlanDetailSpotRow`, `PlanDetail/Sub/PlanDetailDayHeader`
- `Projects/Presentation/Sources/Onboarding/OnboardingMock.swift` — **변경 없음**. `searchResults` 2건, `plans` 2건, `plan.dayDates` 2일(Day2 존재), `planDetail.spots`에 `dayIndex == 1` 스팟 존재 → 스펙이 요구하는 하이라이트 대상이 모두 이미 존재
- `Projects/Presentation/Sources/Onboarding/Sub/OnboardingPolicyWebView.swift` — **변경 없음**
- `Projects/Presentation/Sources/Root/RootFeature.swift` / `RootView.swift` — **변경 없음**. `delegate(.completed)` 계약 유지

### 수정

| 경로 | 내용 |
|------|------|
| `Projects/Presentation/Sources/Onboarding/OnboardingFeature.swift` | `currentStepIndex`/`reachedStepIndex`/`visibleSteps` → `currentCoachMark` 단일 소스로 재구성. `pageSelected`/`nextButtonTapped` 삭제, 스텝별 완료 액션 + `coachMarkAdvanced` 추가 |
| `Projects/Presentation/Sources/Onboarding/OnboardingView.swift` | `TabView` 제거 → 단일 스텝 렌더 + `.overlayPreferenceValue`로 스포트라이트 오버레이 합성. 하단 "다음/시작하기" 버튼 제거, `TabiPageIndicator`만 오버레이 위에 유지 |
| `Projects/Presentation/Sources/Onboarding/Entity/OnboardingStep.swift` | `isLast` 삭제(사용처 소멸), `title`/`description`/`id`는 유지 |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingStepFrame.swift` | `ScrollViewReader` 도입 + `scrollTarget: OnboardingCoachMark?` 파라미터 + `.scrollDisabled(true)` |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingHomeStepView.swift` | 첫 번째 카테고리 칩에 `.onboardingHighlight(.homeCategory)` 부착 |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingMapStepView.swift` | `onSearchResultTapped` 콜백 추가, 첫 번째 결과 카드에 `.onboardingHighlight(.mapSearchResult)` 부착 (기존 `onTapped: {}` 연결) |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingPlanStepView.swift` | `onPlanTapped` 콜백 추가, 첫 번째 `PlanCardView`에 `.onboardingHighlight(.planCard)` 부착 |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingPlanDetailStepView.swift` | 두 번째(index 1) Day 칩에 `.onboardingHighlight(.planDetailDayChip)` 부착 |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingAgreementStepView.swift` | "시작하기" 버튼을 스텝 내부로 이동(`onStartTapped` 추가), 정책보기/체크박스/시작하기 각각에 코치마크 부착 |
| `Projects/Resource/Sources/Strings/Strings.swift` | `public extension Strings.Onboarding`에 코치마크 툴팁 문구 7개 추가, `nextButtonTitle` 삭제 |

### 삭제
- `OnboardingFeature.Action.pageSelected(Int)`, `.nextButtonTapped`
- `OnboardingFeature.State.reachedStepIndex`, `.visibleSteps`
- `OnboardingView`의 `TabView` / `bottomBar()` 내 `TabiButton` 블록
- `OnboardingStep.isLast`
- `Strings.Onboarding.nextButtonTitle`

### 변경 불필요 (확인 완료)
- `Tuist/ProjectDescriptionHelpers/Dependency/DependencyInformation.swift` — 신규 모듈 의존 없음(전부 `Presentation` 내부 + 기존 `Resource`/`DesignSystem`)
- `Domain/Sources/UseCase/Onboarding/*` — 시그니처 그대로
- 프로젝트 내 `Anchor`/`anchorPreference` 최초 사용이지만, `PlanDetail/PlanDetailView.swift:228`에 `PreferenceKey` 선언·`onPreferenceChange` 선례가 있어 컨벤션 참고 가능

---

## 기술적 결정사항

### 1. 좌표 측정: `anchorPreference` + `overlayPreferenceValue` (GeometryReader 전역 좌표 방식 기각)

| | Anchor + overlayPreferenceValue (**채택**) | GeometryReader + `.frame(in: .named)` → `@State` |
|---|---|---|
| 좌표계 변환 | `proxy[anchor]`가 오버레이 자신의 좌표계로 자동 변환 | named coordinateSpace 명시 + 수동 오프셋 보정 필요 |
| 렌더 패스 | 단일 패스(레이아웃 → 오버레이 합성) | preference → `@State` 반영 → 재렌더 2패스, "Modifying state during view update" 위험 |
| 최초 프레임 | 앵커 없으면 오버레이 미렌더 = 스펙의 "측정 전 숨김"이 구조적으로 보장됨 | 초기 `.zero` 프레임이 1프레임 노출되어 깜빡임 |
| 스크롤/레이아웃 변화 추종 | 자동 재해석 | 수동 갱신 |

→ `OnboardingHighlightAnchorKey.defaultValue = [OnboardingCoachMark: Anchor<CGRect>]`, `reduce`는 `merge(uniquingKeysWith: { _, new in new })`(PlanDetailView의 `DayHeaderOffsetPreferenceKey`와 동일 패턴). `Anchor<CGRect>`가 `Equatable`이므로 딕셔너리도 `Equatable` 충족.

### 2. 하이라이트 프레임을 TCA State에 담지 않는다
`CGRect`를 `State`에 넣으면 레이아웃 변화마다 액션 디스패치 → 리듀서 왕복 → 재렌더 루프가 생긴다. 좌표는 **View 계층 내부에서만** 흐르게 하고(`overlayPreferenceValue` 클로저 안에서 즉시 소비), `State`에는 "지금 어떤 코치마크인가"(`currentCoachMark`)만 둔다. 결과적으로 `OnboardingFeature`는 UIKit/CoreGraphics 타입에 의존하지 않고 테스트 가능성이 유지된다.

### 3. 탭 차단: "홀을 제외한 4개 투명 밴드"로 히트테스트 구성
- 딤 비주얼: `Rectangle().fill(TabiColor.tabiScrim.opacity(0.6))` + reverse mask(`RoundedRectangle` + `.blendMode(.destinationOut)` + `.compositingGroup()`), **`.allowsHitTesting(false)`**
- 히트 차단: 홀 사각형 기준 top/bottom/leading/trailing 4개 `Color.clear.contentShape(Rectangle()).onTapGesture {}` 밴드를 `.frame` + `.position`으로 배치(각 변의 크기는 `max(0, ...)`로 클램프)
- 홀 영역에는 히트테스트 가능한 오버레이 요소가 아예 없으므로 **아래의 실제 버튼이 직접 탭을 받는다** → `TabiPressStyle` 눌림 애니메이션·칩 선택 상태가 그대로 재생되어 "직접 조작" 체감을 지킨다
- 대안(오버레이가 투명 프록시 버튼을 얹어 액션을 대신 보냄)은 실제 버튼의 시각 피드백이 사라지고, 스펙의 "실제 버튼을 탭" 의도와 어긋나므로 기각. 단, 라운드 코너 바깥 모서리 미세 영역이 통과되는 한계는 허용(대상 요소 밖이므로 무해)

### 4. 하이라이트 대상이 스크롤 밖에 있을 가능성 → `ScrollViewReader` + 스크롤 잠금
`OnboardingStepFrame`이 `ScrollView`를 쓰고, 지도 스텝의 검색 결과는 260pt 지도 목업 아래에 있어 기기 높이에 따라 화면 밖일 수 있다.
- `.onboardingHighlight(_:)` 모디파이어가 `.id(coachMark)`도 함께 부착 → `OnboardingStepFrame`이 `scrollTarget`을 받아 `.task(id: scrollTarget)`에서 `proxy.scrollTo(target, anchor: .center)` 수행
- 딤이 스크롤 제스처를 삼키므로 사용자 스크롤은 어차피 불가 → `.scrollDisabled(true)`를 명시해 의도를 코드로 드러낸다(프로그래매틱 `scrollTo`는 계속 동작)
- 스크롤 애니메이션 중 앵커가 움직여도 `overlayPreferenceValue`가 추종하므로 홀이 어긋나지 않는다

### 5. 스텝 전환은 offset 없는 **opacity 전환만** 사용
슬라이드/오프셋 전환을 쓰면 전환 중 두 스텝이 동시에 존재하면서 들어오는 스텝의 앵커가 최종 위치가 아닌 값을 내놓아 홀이 튄다. 스텝 컨테이너에 `.id(store.currentStep)` + `.transition(.opacity)` + `.animation(.tabiStandard, value: store.currentStep)`만 적용한다. 홀 자체도 `.animation(.tabiStandard, value: highlightRect)`로 부드럽게 이동시킨다.

### 6. 진행 트리거 후 0.3초 지연 advance
탭 → 즉시 스텝 전환이면 칩 선택/Day 전환 같은 시각 반영을 사용자가 못 본다. 각 탭 액션은 상태만 갱신하고 `.run { try await Task.sleep(for: .seconds(0.3)); await send(.coachMarkAdvanced) }.cancellable(id: CancelID.coachMarkAdvance)`로 진행한다.
- `Task.sleep`을 `.run` 안에서 직접 쓰는 방식은 `RootFeature.swift:138`, `HomeFeature.swift:96` 선례를 따른다(프로젝트에 `continuousClock` 도입 이력 없음 → 신규 의존성 추가하지 않음)
- 예외: `policyWebViewDismissed`는 시트 dismiss 애니메이션이 이미 있으므로 지연 없이 즉시 advance

### 7. 코치마크 7단계 enum을 진행의 단일 소스로
`OnboardingStep`(5개, 페이지 인디케이터용)과 코치마크 진행(7개, 약관동의 3단계 포함)의 단위가 다르다. `currentCoachMark`를 유일한 진행 상태로 두고 `currentStep`/`currentStepIndex`를 **computed**로 파생시키면 두 값의 동기화 버그가 원천 차단된다.

```
homeCategory → mapSearchResult → planCard → planDetailDayChip
  → agreementPolicyButton → agreementCheckBox → agreementStartButton
```
각 케이스는 `step`(소속 스텝), `tooltip`(Strings), `cornerRadius`, `padding`, `next` 제공.

### 8. 신규 컴포넌트 배치는 `Presentation/Onboarding/Sub/` (DesignSystem 승격 X)
`OnboardingAgreementCheckBox`, `OnboardingPolicyWebView`와 동일 원칙 — 온보딩 전용 단일 사용처. 향후 다른 화면에서 코치마크가 필요해지면 그때 `DesignSystem/Overlay/`로 승격한다. `OnboardingHighlightAnchorKey.swift`는 `PreferenceKey` + `View` 확장(뷰 인프라)이므로 `Model/`이 아닌 `Sub/`에 둔다.

---

## OnboardingFeature 재구성 상세

### State (swift-style 선언 순서: 공개 프로퍼티 → computed)
| 프로퍼티 | 처리 |
|---|---|
| `currentStepIndex: Int` | **삭제 → computed** (`self.currentStep.rawValue`, 페이지 인디케이터 전용) |
| `reachedStepIndex: Int` | **삭제** (뒤로가기·스와이프 없음) |
| `visibleSteps: [OnboardingStep]` | **삭제** (TabView 소멸) |
| `currentCoachMark: OnboardingCoachMark = .homeCategory` | **신규**, 진행 단일 소스 |
| `currentStep: OnboardingStep` | computed → `self.currentCoachMark.step` |
| `hasViewedPolicy` / `isAgreed` / `isPolicyWebViewPresented` / `isPolicyLoadFailed` / `policyReloadTrigger` | 유지 |
| `homeSelectedCategory: CategoryType?` / `planDetailSelectedDayIndex: Int` | 유지 |

### Action (swift-style 순서: 사용자 인터랙션 → 비동기 결과 → 하위 액션)
| 액션 | 처리 |
|---|---|
| `pageSelected(Int)` | **삭제** |
| `nextButtonTapped` | **삭제** |
| `homeCategoryTapped(CategoryType)` | 유지 — 토글이 아닌 **단순 선택**으로 변경 후 지연 advance |
| `mapSearchResultTapped` | **신규** — 지연 advance |
| `planCardTapped` | **신규** — 지연 advance |
| `planDetailDayTapped(Int)` | 유지 — 선택 Day 갱신 후 지연 advance |
| `policyViewButtonTapped` | 유지 — 시트 표시(advance 없음) |
| `policyWebViewDismissed` | 유지 + `hasViewedPolicy = true` 시 즉시 advance |
| `policyRetryTapped` | 유지 |
| `agreementCheckBoxTapped` | 유지 — `guard state.hasViewedPolicy` 후 `isAgreed = true`(토글 아님) + 지연 advance |
| `startButtonTapped` | 유지 — `guard state.isAgreed` → `markAsCompleted()` → `.send(.delegate(.completed))` |
| `policyLoadFailed` | 유지 (`AppLogger.network.log(.error, ...)`) |
| `coachMarkAdvanced` | **신규** — `state.currentCoachMark = state.currentCoachMark.next ?? state.currentCoachMark` |
| `delegate(Delegate)` | 유지 |

### 방어 가드 (오버레이가 이미 막지만 리듀서에서도 이중 보장)
- 각 탭 액션 진입부에 `guard state.currentCoachMark == .{해당 마크} else { return .none }`
- `planDetailDayTapped`는 추가로 하이라이트 대상 인덱스(1) 여부와 무관하게 선택은 반영하되 advance는 코치마크 가드로 제어
- `agreementCheckBoxTapped`는 `hasViewedPolicy` 가드 유지 → 스펙 불변조건("웹뷰 미열람 시 체크 불가") 보존
- `startButtonTapped`는 `isAgreed` 가드 유지 → 불변조건("미동의 시 완료 불가") 보존

### body / private extension
- `Reduce { }` 단일 블록(BindingReducer·하위 Reducer 없음)
- `CancelID` enum과 `advanceEffect()` 헬퍼는 `// MARK: - Method` + `private extension OnboardingFeature`로 분리

---

## 약관동의 스텝 래핑 방식

기존 실동작(웹뷰 열람 → 체크박스 활성화 → 시작하기)은 **그대로 두고**, 하이라이트만 순차 이동한다.

| 코치마크 | 하이라이트 대상 | 사용자 행동 | 진행 조건 |
|---|---|---|---|
| `agreementPolicyButton` | "プライバシーポリシーを見る" `TabiButton` | 탭 → 시트 표시 | 시트가 뜨면 오버레이는 시트 아래에 가려짐(별도 처리 불필요). `policyWebViewDismissed` 수신 시 `hasViewedPolicy = true` + 즉시 advance |
| `agreementCheckBox` | `OnboardingAgreementCheckBox` | 탭 → 체크 | `hasViewedPolicy == true`라 이미 활성 상태. 체크 시 지연 advance. 이후 하이라이트가 시작하기로 옮겨가 체크박스는 딤에 막혀 **해제 불가** → 불변조건 자동 보존 |
| `agreementStartButton` | "始める" `TabiButton` (스텝 내부로 이동) | 탭 → 완료 | `isAgreed == true`이므로 `.disabled(false)`. `markAsCompleted()` → `delegate(.completed)` |

- `privacyPolicyUnviewedGuide` 캡션은 `hasViewedPolicy == false`일 때만 노출되는 기존 조건 유지 → 첫 코치마크 단계에서 자연스러운 보조 안내로 작동
- 시작하기 버튼은 스텝 콘텐츠 최하단에 `isExpanded: true`로 배치하고 `.disabled(self.isAgreed == false)` 유지(이중 보장)
- 웹뷰 로드 실패 시나리오: `TabiRetryableEmptyState` + 재시도 흐름 그대로. 실패해도 시트를 닫으면 `hasViewedPolicy = true` → 기존 동작 유지

---

## 신규 Strings 추가 위치

`Projects/Resource/Sources/Strings/Strings.swift`의 기존 `public extension Strings.Onboarding` 블록 **하단에 이어서** 추가(신규 enum/파일 생성 없음). 앱 표시 언어는 일본어이므로 값도 일본어로 작성하고, 한국어 설명은 기존 컨벤션대로 `///` 주석으로 남긴다.

| 심볼 | 용도 |
|---|---|
| `homeCategoryCoachMark` | 홈 카테고리 칩 유도 |
| `mapSearchResultCoachMark` | 지도 검색 결과 카드 유도 |
| `planCardCoachMark` | 일정 카드 유도 |
| `planDetailDayChipCoachMark` | Day 칩 유도 |
| `agreementPolicyCoachMark` | 정책 보기 버튼 유도 |
| `agreementCheckBoxCoachMark` | 체크박스 유도 |
| `agreementStartCoachMark` | 시작하기 버튼 유도 |

동시에 `nextButtonTitle` 삭제(사용처 소멸). `startButtonTitle`은 약관동의 스텝 내부 버튼에서 계속 사용.

---

## 구현 순서

### Phase 1. Resource
1. `Strings.swift`의 `Strings.Onboarding`에 코치마크 툴팁 문구 7개 추가
2. `nextButtonTitle` 삭제 (Phase 6에서 참조가 사라진 뒤 최종 확인)

### Phase 2. Presentation — Entity
3. `Entity/OnboardingCoachMark.swift` 신규: `enum OnboardingCoachMark: Int, CaseIterable, Hashable` + `step` / `tooltip` / `cornerRadius` / `padding` / `next` / `isLast`
4. `Entity/OnboardingStep.swift`에서 `isLast` 삭제 (`title`/`description`/`id` 유지)

### Phase 3. Presentation — 좌표 측정 인프라
5. `Sub/OnboardingHighlightAnchorKey.swift` 신규: `PreferenceKey`(`[OnboardingCoachMark: Anchor<CGRect>]`) + `// MARK: - View` `private/internal extension View`의 `onboardingHighlight(_:)`(anchorPreference + `.id`)

### Phase 4. Presentation — 오버레이 컴포넌트
6. `Sub/OnboardingTooltipView.swift` 신규: 말풍선 + 꼬리, 홀 기준 위/아래 배치 파라미터, 좌우 20pt 클램프
7. `Sub/OnboardingSpotlightOverlay.swift` 신규: `highlightRect` / `containerSize` / `coachMark` 입력 → 딤(reverse mask, `allowsHitTesting(false)`) + 홀 외곽 스트로크 + 탭 차단 밴드 4개 + 툴팁. `body` 50줄 초과 시 `// MARK: - View` `private extension`으로 `dimLayer()` / `blockingBands()` / `tooltip()` 분리

### Phase 5. Presentation — Feature
8. `OnboardingFeature.swift` State/Action/body 재구성 (위 표대로). `CancelID` + `advanceEffect()`는 `// MARK: - Method` `private extension`으로 분리

### Phase 6. Presentation — Step View 수정
9. `Sub/OnboardingStepFrame.swift`: `ScrollViewReader` + `scrollTarget: OnboardingCoachMark?` + `.scrollDisabled(true)` + `.task(id:)` 스크롤
10. `OnboardingHomeStepView` — 첫 칩 하이라이트 (`CategoryType.allItems.first` 기준 index 0 비교)
11. `OnboardingMapStepView` — `onSearchResultTapped` 추가, 첫 결과 카드 하이라이트 + 콜백 연결
12. `OnboardingPlanStepView` — `onPlanTapped` 추가, 첫 `PlanCardView` 하이라이트 + 콜백 연결
13. `OnboardingPlanDetailStepView` — index 1 Day 칩 하이라이트
14. `OnboardingAgreementStepView` — `onStartTapped` 추가, "시작하기" 버튼 스텝 내부로 이동, 3개 요소 각각 하이라이트

### Phase 7. Presentation — 루트 뷰
15. `OnboardingView.swift`: `TabView`/`bottomBar` 제거 → `stepView(store.currentStep)` 단일 렌더 + `.id(store.currentStep)` + `.transition(.opacity)`
16. `.overlayPreferenceValue(OnboardingHighlightAnchorKey.self) { anchors in GeometryReader { proxy in ... } .ignoresSafeArea() }`로 오버레이 합성. `anchors[store.currentCoachMark]`가 `nil`이면 아무것도 렌더하지 않음(= 측정 전 숨김 보장)
17. `TabiPageIndicator`는 `.overlay(alignment: .bottom)`으로 오버레이보다 위에 배치, `.allowsHitTesting(false)`
18. `.sheet` 웹뷰 블록은 기존 그대로 유지
19. `#Preview` 갱신

### Phase 8. 빌드 · 검증
20. `tuist generate` (신규 `.swift` 4개 추가)
21. 빌드 후 시뮬레이터 수동 검증: 온보딩 미완료 상태 진입 → 7단계 코치마크 순차 통과 → TabBar 진입 → 재실행 시 미표시
22. 홀 밖 탭·스와이프로 진행 불가, 작은 기기(iPhone SE)에서 하이라이트 대상 자동 스크롤 확인

---

## 리스크 및 대응

| 리스크 | 대응 |
|---|---|
| `.ignoresSafeArea()`를 `overlayPreferenceValue` 내부 `GeometryReader`에 붙였을 때 `proxy[anchor]` 좌표계가 확장 프레임 기준으로 바뀜 | `proxy[anchor]`는 항상 해당 proxy 프레임 기준으로 해석되므로 정합하지만, 구현 시 실제 기기에서 상단 인셋만큼 어긋나는지 1회 육안 검증. 어긋나면 `.ignoresSafeArea()`를 제거하고 딤만 `Rectangle().ignoresSafeArea()`로 별도 레이어 처리 |
| 스텝 전환 순간 이전/다음 스텝 앵커가 동시에 존재 | opacity 전환만 사용(결정 5) + 코치마크 키가 스텝별로 유일하므로 오독 불가 |
| 라운드 홀 모서리 밖 미세 영역 탭 통과 | 대상 요소 바깥이라 무해. 필요 시 밴드 대신 홀 크기 원형 마스크로 축소 |
| `.scrollDisabled(true)`에서 `scrollTo`가 동작하지 않는 OS 버전 | 미동작 시 `.scrollDisabled` 제거 + 딤이 제스처를 삼키는 동작으로 대체(오버레이가 이미 스크롤 차단) |
| 0.3초 advance 지연 중 앱 백그라운드 전환 | 진행 상태를 저장하지 않으므로 재실행 시 처음부터 — 스펙과 동일. `cancellable(id:)`로 중복 advance 방지 |

---

## 완료 조건
- [ ] Spec Acceptance Criteria 10개 전부 충족
- [ ] `TabView`/스와이프/"다음" 버튼 코드가 `Onboarding` 폴더에서 완전히 제거됨
- [ ] `OnboardingFeature.State`에 `CGRect` 등 레이아웃 타입이 없음(좌표는 View 계층에만 존재)
- [ ] `Strings.Onboarding.nextButtonTitle` 참조 0건
- [ ] `.claude/rules/swift-style.md` 준수: State/Action 선언 순서, `// MARK: - View` / `// MARK: - Method` + `private extension` 분리, `self` 명시, `body` 50줄 이하
- [ ] `tuist generate` 및 빌드 성공

---

### Critical Files for Implementation
- /Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Onboarding/OnboardingFeature.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Onboarding/OnboardingView.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Onboarding/Entity/OnboardingStep.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Onboarding/Sub/OnboardingStepFrame.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/Resource/Sources/Strings/Strings.swift

---

## 후속: 실제 Feature 재사용 전환

> 위 Phase 1~8은 "TabView 페이징 → 코치마크형" 전환을 다룬다. 이 섹션은 그 위에서 진행된 **후속 리팩터링**을 다룬다:
> 코치마크가 가리키는 홈/지도/일정/일정상세 화면을 더미 목업 `OnboardingHomeStepView` 등이 아니라
> 실제 `HomeFeature`/`MapFeature`/`PlanFeature`/`PlanDetailFeature`와 실제 `HomeView`/`MapView`/`PlanView`/`PlanDetailView`를
> 그대로 렌더링하도록 바꾼다. Map 스텝의 `TabiMapView`(NMapsMap SDK) 지도 배경만 실제 타일 네트워크 호출을 피하기 위해 정적 목업을 유지한다.

### 핵심 설계

1. **더미 데이터 주입은 TCA `withDependencies`로** — 각 Host View가 실제 Feature의 `Store`를 직접 만들면서, `Domain`의 `Test{Name}UseCase` 더블(`testValue`용으로 이미 존재)에 `OnboardingMock` 데이터를 채워 `withDependencies` 클로저로 오버라이드한다. `PlanDetailView`의 기존 `#Preview`(`TestTravelPlanDetailUseCase` 주입)와 동일한 패턴. 단, `#Preview`/테스트 컨텍스트와 달리 온보딩은 **실제 앱 프로세스**에서 실행되므로 TCA가 자동으로 `previewValue`/`testValue`로 폴백해주지 않는다 — `onAppear`가 실제로 건드리는 모든 의존성을 하나하나 추적해 명시적으로 오버라이드해야 한다(예: `PlanDetailFeature.onAppear`는 상세 조회 이후 `updateShareFileURLEffect`를 자동 실행하므로 `travelPlanDetailUseCase`뿐 아니라 `autoScrollToTodayUseCase`/`shoppingPlanItemUseCase`/`toolBarItemUseCase`/`travelPlanShareUseCase`도 함께 오버라이드해야 실제 DB 호출이 섞이지 않는다)
2. **코치마크 진행 신호는 "관찰 전용 래퍼 Reducer"로** — 실제 Feature의 `Action`/`State`를 변형하지 않고, `HomeFeature()` 뒤에 `Reduce { _, action in if case .categoryTapped = action { onProgress() }; return .none }`를 이어붙이는 얇은 Reducer(TCA의 순차 합성 특성상 원본 리듀서의 로직·이펙트는 그대로 유지되고 관찰만 추가됨)로 감싼다. 이 래퍼는 각 Host View 파일 내부 `private struct`로 두어 공개 API를 늘리지 않는다
3. **하이라이트 앵커 키를 `AnyHashable`로 일반화** — `OnboardingHighlightAnchorKey`(`PreferenceKey`)와 `.onboardingHighlight(_:)` 모디파이어가 기존에는 `OnboardingCoachMark`(Onboarding 전용 타입)만 키로 받았으나, 이제 Home/Map/Plan/PlanDetailView(프로덕션 코드)가 `OnboardingCoachMark`를 몰라도(`"homeCategory"` 같은 문자열 리터럴만으로) 하이라이트를 부착할 수 있도록 `AnyHashable`로 넓혔다. `OnboardingCoachMark`에 `anchorKey: AnyHashable` computed property를 추가해 문자열/enum 두 종류의 키를 일관되게 조회한다. 약관동의 스텝(`OnboardingAgreementStepView`, 여전히 온보딩 전용 뷰)은 기존처럼 `OnboardingCoachMark` 케이스를 그대로 전달한다 — `AnyHashable`은 dot-shorthand(`.agreementPolicyButton`)로 타입을 추론하지 못하므로 호출부는 `OnboardingCoachMark.agreementPolicyButton`처럼 타입명을 명시해야 한다
4. **지도 배경만 주입 지점으로 분리** — `MapView`에 `mapBackgroundOverride: AnyView? = nil` 이니셜라이저 파라미터를 추가해, 기본값(nil)에서는 기존과 동일하게 `TabiMapView`가 렌더링되고, 온보딩에서만 `OnboardingMapBackgroundMockView`(정적 배경 + 마커 목업)를 주입한다. 지도 스텝의 검색 결과 상태(`mode: .result`, `searchResults: OnboardingMock.searchResults`)는 `MapFeature.State`의 internal 프로퍼티를 초기 State에서 직접 설정해(같은 Presentation 모듈이라 접근 가능) 실제 검색 없이 바로 노출한다
5. **하이라이트 대상은 프로덕션 뷰에 "항상" 부착, 온보딩 밖에서는 무해** — `HomeView`의 첫 카테고리 칩, `MapView`의 첫 검색 결과 행, `PlanView`의(진행중→예정→지난 순) 첫 카드, `PlanDetailView`의 둘째 날 Day 칩에 `.onboardingHighlight(...)`를 조건 없이 부착한다. `anchorPreference`는 아무도 그 키를 읽지 않으면(실제 홈/지도/일정 탭 화면) 좌표를 상위로 전달만 할 뿐 아무 동작도 하지 않으므로 프로덕션 화면 동작·외관에 회귀가 없다

### 변경 파일

| 경로 | 내용 |
|------|------|
| `Domain/Sources/UseCase/Location/TestLocationUseCase.swift`, `Domain/Sources/UseCase/ExchangeRate/TestExchangeRateUseCase.swift` | `public init() {}` 누락 발견·추가(다른 모듈에서 인스턴스화 불가능한 버그였음, Task 1 감사에서 발견) |
| `Presentation/Sources/Onboarding/Sub/OnboardingHighlightAnchorKey.swift` | 키 타입을 `OnboardingCoachMark`→`AnyHashable`로 일반화, `nonisolated(unsafe)`(Swift 6 동시성 검사 대응) |
| `Presentation/Sources/Onboarding/Entity/OnboardingCoachMark.swift` | `anchorKey: AnyHashable` computed property 추가 |
| `Presentation/Sources/Onboarding/OnboardingView.swift` | `stepView(_:)`가 4개 신규 `OnboardingXxxHostView`를 렌더링하도록 교체, `anchors[store.currentCoachMark.anchorKey]` 조회로 변경 |
| `Presentation/Sources/Onboarding/Sub/OnboardingAgreementStepView.swift` | `.onboardingHighlight(.xxx)` → `.onboardingHighlight(OnboardingCoachMark.xxx)`(AnyHashable dot-shorthand 미지원 대응) |
| `Presentation/Sources/Home/HomeView.swift` | 첫 카테고리 칩에 `.onboardingHighlight("homeCategory")` 부착 |
| `Presentation/Sources/Map/MapView.swift` | `mapBackgroundOverride: AnyView?` 주입 지점 추가, 첫 검색 결과 행에 `.onboardingHighlight("mapSearchResult")` 부착 |
| `Presentation/Sources/Plan/PlanView.swift` | 첫(진행중→예정→지난 순) 일정 카드에 `.onboardingHighlight("planCard")` 부착 |
| `Presentation/Sources/PlanDetail/PlanDetailView.swift` | 둘째 날(index 1) Day 칩에 `.onboardingHighlight("planDetailDayChip")` 부착 |
| `Presentation/Sources/Onboarding/Sub/OnboardingHomeHostView.swift`(신규) | `HomeFeature`/`HomeView` 실제 렌더링 + 의존성 오버라이드 + `categoryTapped` 관찰 래퍼 |
| `Presentation/Sources/Onboarding/Sub/OnboardingMapHostView.swift`(신규) | `MapFeature`/`MapView` 실제 렌더링(지도 배경만 목업) + 의존성 오버라이드 + `searchResultTapped` 관찰 래퍼 |
| `Presentation/Sources/Onboarding/Sub/OnboardingPlanHostView.swift`(신규) | `PlanFeature`/`PlanView` 실제 렌더링 + 의존성 오버라이드 + `planTapped` 관찰 래퍼 |
| `Presentation/Sources/Onboarding/Sub/OnboardingPlanDetailHostView.swift`(신규) | `PlanDetailFeature`/`PlanDetailView` 실제 렌더링 + 의존성 오버라이드 + `dayButtonTapped` 관찰 래퍼 |
| `Presentation/Sources/Onboarding/Sub/OnboardingMapBackgroundMockView.swift`(신규) | 정적 배경 + 마커 목업(기존 `OnboardingMapStepView`의 지도 목업 시각 자산을 대체) |

### 삭제 파일
- `OnboardingHomeStepView.swift` / `OnboardingMapStepView.swift` / `OnboardingPlanStepView.swift` / `OnboardingPlanDetailStepView.swift` — 더미 목업 Step View 전부 삭제(대체 파일은 위 "신규" 참고)

### 변경 불필요 (확인 완료)
- `Presentation/Sources/Onboarding/OnboardingMock.swift` — 기존 `nearbySpots`/`searchResults`/`plan`/`plans`/`planDetail`이 각 Test UseCase가 요구하는 형태와 그대로 맞아 추가 데이터 불필요
- `Presentation/Sources/Onboarding/OnboardingFeature.swift` — Action 시그니처·`currentCoachMark` 진행 로직·0.3초 지연 advance 변경 없음(요구사항 7)
- Domain의 나머지 Test UseCase(TouristSpot/Festival/TravelPlan/TravelPlanDetail/SearchHistory/SubwayStation/AnalyticsCenter/WidgetSnapshotStore/AutoScrollToToday/AutoTranslateSearch/ShoppingPlanItem/ToolBarItem/TravelPlanShare) — 이미 `public init()` + 데이터 주입용 `public var`가 공개되어 있어 수정 불필요

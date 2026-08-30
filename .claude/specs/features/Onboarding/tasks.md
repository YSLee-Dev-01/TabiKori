# Tasks: Onboarding

## 참조
- spec: `.claude/specs/features/Onboarding/spec.md`
- plan: `.claude/specs/features/Onboarding/plan.md`

## Task 목록

### Phase 1. Resource

#### [x] Task 1 — `TabiURL.swift` (신규)
**파일**: `Projects/Resource/Sources/Constant/TabiURL.swift`
- `public enum TabiURL` 선언
- `public static let privacyPolicy: String` — 값은 `Projects/Presentation/Sources/Setting/Entity/SettingEtcItem.swift`의 `privacyPolicyURLString`과 **바이트 단위로 동일**하게 복사(구현 전 원본 값을 직접 확인, 추측 금지)
- 한국어 doc 주석으로 용도(개인정보처리방침 URL, Setting/Onboarding 공용) 명시
- Tuist 타겟 sources glob이 `Sources/**`이므로 신규 하위 폴더(`Constant/`)는 별도 타겟 설정 없이 자동 포함됨

---

#### [x] Task 2 — `Strings.swift` 수정
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- 최상단 `public enum Strings` 내부, 기존 `Root` 자리에 `public enum Onboarding {}` 추가(선언 순서 유지)
- `public enum Root {}` 선언 및 `public extension Strings.Root` 블록 전체 삭제(비게 되는 네임스페이스이므로 완전 제거, `Strings.Root.onboardingCompleteButton` 참조는 Task 19에서 함께 제거됨을 확인)
- `public extension Strings.Onboarding` 신규 작성, 각 항목 위 한국어 주석 + 일본어 값:
  - 스텝별 제목/설명 5쌍(홈/지도/일정/일정상세/약관동의)
  - 공용 버튼 문구: 다음, 시작하기
  - 약관동의 화면: 체크박스 라벨, "개인정보처리방침 보기" 버튼, 웹뷰 열람 전 안내 문구
  - 웹뷰: 시트 타이틀, 로드 실패 설명 문구(`TabiRetryableEmptyState`용)
  - 목업 화면 전용 문구 중 기존 네임스페이스로 대체 불가한 것(체험용 안내 배지 등)
- 목업 화면에서 카테고리/공용 라벨이 필요하면 `Strings.Common.*`, `Strings.Home.*`, `Strings.Plan.*`, `Strings.Map.searchPlaceholder` 등 기존 항목을 **먼저 재사용**하고, 대응 항목이 없을 때만 `Strings.Onboarding`에 신규 추가

---

#### [x] Task 3 — `folder-structure.md` 수정
**파일**: `.claude/rules/folder-structure.md`
- Resource 트리 다이어그램에 `Constant/` 하위 폴더 항목 추가
- "파일 종류 / 위치" 표에 `공용 외부 URL 상수` → `Resource/Sources/Constant/TabiURL.swift` 행 추가
- 문서-코드 동기화 목적, 기능 코드 변경 없음

---

### Phase 2. DesignSystem

#### [x] Task 4 — `TabiPageIndicator.swift` 수정
**파일**: `Projects/DesignSystem/Sources/Indicator/TabiPageIndicator.swift`
- `private let inactiveColor: Color` 프로퍼티 추가
- `init(count:currentIndex:inactiveColor:)`에 `inactiveColor: Color = .white.opacity(0.6)` 기본값 파라미터 추가(기존 동작과 완전 동일한 기본값)
- 비선택 dot을 그리는 `dot(isSelected:)` 내부에서 하드코딩된 `Color.white.opacity(0.6)`를 `self.inactiveColor`로 교체
- 기존 3개 호출부(`PhotoViewerView`, `DetailHeroView`, `PlanDetailFullMapView`)가 `inactiveColor`를 넘기지 않아도 무변경으로 컴파일되는지 grep으로 재확인(파라미터 미전달 시 기존과 동일 색상 유지)

---

### Phase 3. Presentation — Onboarding 신규 화면

#### [x] Task 5 — `OnboardingStep.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Entity/OnboardingStep.swift`
- `enum OnboardingStep: Int, CaseIterable, Identifiable` — case: `home`, `map`, `plan`, `planDetail`, `agreement`
- `var id: Int` (rawValue 기반)
- `var title: String`, `var description: String` — `Strings.Onboarding.*`로 매핑
- `var isLast: Bool` — 마지막 스텝(`agreement`) 여부
- `Presentation/Sources/Tabbar/Entity/AppTab.swift`와 동일한 구성 방식 참고

---

#### [x] Task 6 — `OnboardingMock.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/OnboardingMock.swift`
- `enum OnboardingMock` 네임스페이스(기존 `PlanDetailMock`의 `TravelPlan.mock` extension 패턴과 이름 충돌을 피하기 위해 static extension이 아닌 별도 네임스페이스 타입 사용)
- `static let plan: TravelPlan`
- `static let planDetail: TravelPlanDetail`(2일치 데이터)
- `static let nearbySpots: [TouristSpot]`
- `static let searchResults: [TouristSpot]`
- `static let plans: [TravelPlan]`
- 모든 썸네일 URL 필드는 `nil`(네트워크 로드 방지), 좌표는 기존 상수(`Coordinate.seoulCityHall` 등) 재사용, 날짜는 `Date()` 기준 상대 계산(`PlanDetailMock.swift` 방식 참고)
- 홈 목업의 지역 배너 이미지는 번들 에셋(`TabiImage.regionSeoul` 등) 사용, Kingfisher 원격 로드 금지

---

#### [x] Task 7 — `OnboardingStepFrame.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingStepFrame.swift`
- `title: String`, `description: String`, `@ViewBuilder content: () -> Content` 파라미터를 받는 공용 프레임 뷰
- 모든 스텝의 상단 카피(제목/설명) 영역 레이아웃 통일, 하단에 `content()` 슬롯 배치
- `TabiLabel`, `TypographyStyle`, `TabiColor` 등 기존 DesignSystem 토큰 재사용

---

#### [x] Task 8 — `OnboardingHomeStepView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingHomeStepView.swift`
- `OnboardingStepFrame`으로 감싼 홈 체험 목업
- 구성 요소: `TabiSearchField`(비활성 상태) + 환율 카드 목업(`TabiCard`) + 지역 배너(`Image(TabiImage.regionSeoul)`) + 카테고리 칩(`TabiChip`, `store` 바인딩으로 선택 하이라이트) + 근처 스팟 리스트(`TabiSpotRow`, `OnboardingMock.nearbySpots` 사용)
- 카테고리 칩 탭 시 `homeCategoryTapped(CategoryType)` 액션 전송(실제 `HomeFeature`/UseCase 미의존)
- `body` 50줄 초과 시 파일 내 `private extension`의 `@ViewBuilder` 함수로 분리

---

#### [x] Task 9 — `OnboardingMapStepView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingMapStepView.swift`
- 실제 `TabiMapView`(NaverMap) 미사용 — `RoundedRectangle`(`.tabiSurfaceElevated` 배경 + `.tabiBorder` 스트로크) 위에 마커 핀을 `ZStack`으로 고정 배치한 정적 지도 목업
- 마커 핀은 `TabiMapMarkerPinView`가 DesignSystem 내부 `internal`이라 접근 불가하므로, 동일한 시각(Circle + `TabiIcon` + `.tabiOnColor` 테두리)을 이 파일 내부 `private` 서브뷰로 직접 재현(DesignSystem 접근 제어 확장 금지)
- 하단 검색 패널: `TabiSearchField` + `MapSearchResultRowView`(더미 `TouristSpot`, `thumbnailURLString: nil`, `OnboardingMock.searchResults` 사용)
- 네트워크/위치 권한 호출 없음을 코드 리뷰 시 재확인

---

#### [x] Task 10 — `OnboardingPlanStepView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingPlanStepView.swift`
- `TabiNavigationBar` 목업 + `PlanCardView`(`Plan/Sub/PlanCardView.swift`, Store 비의존 순수 뷰) 2~3장
- `OnboardingMock.plans` 데이터 사용, `PlanCardView`의 `onTapped`는 no-op 클로저(`{}`)로 전달하여 실제 `PlanFeature` 상태에 전혀 닿지 않도록 함

---

#### [x] Task 11 — `OnboardingPlanDetailStepView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingPlanDetailStepView.swift`
- `PlanDetailDayHeader`(`PlanDetail/Sub/PlanDetailDayHeader.swift`) + 일자 칩(`TabiChip`, `store.planDetailSelectedDayIndex` 바인딩으로 선택 전환) + `PlanDetailSpotRow`(`PlanDetail/Sub/PlanDetailSpotRow.swift`, `isEditing: false`) 타임라인
- `OnboardingMock.planDetail` 데이터 사용
- 일자 칩 탭 시 `planDetailDayTapped(Int)` 액션 전송(온보딩 State 내부에서만 완결, `PlanDetailFeature`/UseCase 미의존)

---

#### [x] Task 12 — `OnboardingAgreementCheckBox.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingAgreementCheckBox.swift`
- `Button` + `Image(systemName: isChecked ? "checkmark.square.fill" : "square")` + `TabiLabel` 조합, `TabiPressStyle` 적용
- `isEnabled: Bool`, `isChecked: Bool`, `onTapped: () -> Void` 파라미터
- 활성/비활성 표현: `.disabled(isEnabled == false)` + `.opacity(isEnabled ? 1 : 0.4)`(`TabiButton`의 `@Environment(\.isEnabled)` 0.5 opacity 방식과 동일 계열)
- `SettingToggleRow`는 `Toggle` 기반이라 "약관 동의 체크" 시맨틱에 맞지 않고 DesignSystem에도 체크박스가 없음을 확인했으므로 온보딩 전용 신규 컴포넌트로 제작(DesignSystem 승격 없음)

---

#### [x] Task 13 — `OnboardingPolicyWebView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingPolicyWebView.swift`
- `import WebKit`, `UIViewRepresentable` 채택
- `makeUIView`: `WKWebView` 생성 + `navigationDelegate = context.coordinator` 설정 + 최초 `load(URLRequest(url:))`(`TabiURL.privacyPolicy` 사용)
- `updateUIView`: `reloadTrigger`(Int) 값 변화 감지 시 `webView.load(request)` 재호출(재시도 대응)
- `makeCoordinator`: `WKNavigationDelegate` 채택한 `final class Coordinator` 반환, `onLoadFailed: () -> Void` 클로저 보유
- Coordinator의 `didFail` / `didFailProvisionalNavigation` 델리게이트 메서드에서 `onLoadFailed()` 호출, `[weak self]` 캡처 규칙 준수
- `Projects/Presentation/Sources/Setting/Sub/SettingMailComposeView.swift`(Representable을 Setting `Sub/`에 두고 `.sheet`로 표시하는 패턴)를 템플릿으로 참고

---

#### [x] Task 14 — `OnboardingAgreementStepView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/Sub/OnboardingAgreementStepView.swift`
- `OnboardingStepFrame`으로 감싼 약관동의 스텝
- 안내 문구(`Strings.Onboarding.*`) + `TabiButton("개인정보처리방침 보기", style: .secondary)`(탭 시 `policyViewButtonTapped` 액션) + `OnboardingAgreementCheckBox`(탭 시 `agreementCheckBoxTapped` 액션)
- 체크박스는 `store.hasViewedPolicy`가 `true`가 되기 전까지 `isEnabled: false`로 렌더

---

#### [x] Task 15 — `OnboardingFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/OnboardingFeature.swift`
- `@Dependency(\.onboardingUseCase)` 주입(신규 UseCase 없음, 기존 `isCompleted()`/`markAsCompleted()` 그대로 사용)
- `State`(선언 순서: 공개 프로퍼티 → fileprivate → `@Presents` 없음):
  - `currentStepIndex: Int`, `reachedStepIndex: Int`, `hasViewedPolicy: Bool`, `isAgreed: Bool`, `isPolicyWebViewPresented: Bool`, `isPolicyLoadFailed: Bool`, `policyReloadTrigger: Int`, `homeSelectedCategory: CategoryType?`, `planDetailSelectedDayIndex: Int`
  - 계산 프로퍼티: `currentStep: OnboardingStep`, `isStartEnabled: Bool`(= `isAgreed`), `visibleSteps: [OnboardingStep]`(`reachedStepIndex + 1`까지)
- `Action`(선언 순서: 바인딩 → 생명주기 → 인터랙션 → 비동기 결과 → delegate):
  - `binding`, `nextButtonTapped`, `policyViewButtonTapped`, `policyWebViewDismissed`, `policyRetryTapped`, `agreementCheckBoxTapped`, `startButtonTapped`, `homeCategoryTapped(CategoryType)`, `planDetailDayTapped(Int)`, `policyLoadFailed`, `delegate(Delegate)`
  - `enum Delegate { case completed }`
- `body`: `BindingReducer()` → `Reduce { state, action in }` (하위 리듀서 없음)
- 로직:
  - `nextButtonTapped`: 마지막 스텝(`currentStep.isLast`)이면 `.none`, 아니면 `reachedStepIndex = max(reachedStepIndex, currentStepIndex + 1)` 후 `currentStepIndex += 1`
  - `policyViewButtonTapped`: `isPolicyWebViewPresented = true`
  - `policyWebViewDismissed`: `isPolicyWebViewPresented = false`, `hasViewedPolicy = true`, `isPolicyLoadFailed = false`(이 액션이 `hasViewedPolicy` 갱신의 유일한 진입점)
  - `policyRetryTapped`: `policyReloadTrigger += 1`, `isPolicyLoadFailed = false`
  - `policyLoadFailed`: `isPolicyLoadFailed = true` + `AppLogger.network.log(.error, ...)`(이펙트 없이 즉시 로깅, `hasViewedPolicy`는 건드리지 않음)
  - `agreementCheckBoxTapped`: `guard state.hasViewedPolicy else { return .none }` 이중 방어 후 `isAgreed.toggle()`
  - `startButtonTapped`: `guard state.isAgreed else { return .none }` 이중 방어 후 `onboardingUseCase.markAsCompleted()` 호출, `.send(.delegate(.completed))` 반환
  - `homeCategoryTapped`: `homeSelectedCategory` 갱신(UseCase 호출 없음)
  - `planDetailDayTapped`: `planDetailSelectedDayIndex` 갱신(UseCase 호출 없음)
  - `delegate`: `.none`
- 진행 상태(스텝 인덱스 등)는 어디에도 영속화하지 않음(spec: 재실행 시 처음부터)

---

#### [x] Task 16 — `OnboardingView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Onboarding/OnboardingView.swift`
- `@Bindable private var store: StoreOf<OnboardingFeature>`
- `VStack`: `TabView(selection: $store.currentStepIndex)` — `store.visibleSteps`(도달 스텝까지만)를 `ForEach`로 순회하여 각 스텝 뷰(Task 8~11, 14에서 만든 Sub 뷰) 렌더 + `.tabViewStyle(.page(indexDisplayMode: .never))` + `.animation(.tabiStandard, value: store.currentStepIndex)`
- 하단 공용 바: `TabiPageIndicator(count:currentIndex:inactiveColor: Color.getTabiColor(.tabiBorder))` + `TabiButton(다음/시작하기, style: .primary, isExpanded: true)`(탭 시 마지막 스텝이면 `startButtonTapped`, 아니면 `nextButtonTapped`)
  - 마지막 스텝에서는 `.disabled(store.isStartEnabled == false)`
- `.sheet(isPresented: Binding(get:set:))` — `SettingView`의 드래그 dismiss 대응 패턴(`guard isPresented == false else { return }`)을 그대로 사용해 드래그로 닫아도 `policyWebViewDismissed` 액션이 반드시 발생하도록 구현
  - 시트 콘텐츠: 상단 `TabiNavigationBar` + `TabiCircleIconButton("xmark")`(닫기) + `OnboardingPolicyWebView` + 로드 실패 시 `TabiRetryableEmptyState(description:onRetry:)` 오버레이(`onRetry`는 `policyRetryTapped` 액션 전송)
- `#Preview` 추가(더미 `Store` 구성)

---

### Phase 4. 연결 및 참조 교체

> Phase 3까지 신규 `.swift` 파일이 다수 추가되므로, 이 Phase 시작 전 반드시 `tuist install && tuist generate`를 실행한다. 그 전 단계에서 빌드하면 stale 프로젝트로 인한 오탐 에러가 발생한다.

#### [x] Task 17 — `tuist install && tuist generate` 실행
**대상**: 프로젝트 전체(Tuist 워크스페이스)
- `tuist install` 실행 후 `tuist generate` 실행
- Phase 1~3에서 추가된 신규 `.swift` 파일(`TabiURL.swift`, `Onboarding/` 하위 전체)이 각 모듈 타겟에 정상 포함되는지 확인
- 이 Task 완료 전까지 Phase 4의 나머지 Task 및 Phase 5 빌드를 진행하지 않음

---

#### [x] Task 18 — `RootFeature.swift` 수정
**파일**: `Projects/Presentation/Sources/Root/RootFeature.swift`
- `State`에 `var onboardingState: OnboardingFeature.State? = nil` 추가(`tabBarState` 프로퍼티 다음 위치)
- `Action`: 기존 `testBtnTapped` case 삭제, `case onboarding(OnboardingFeature.Action)` 추가(하위 액션이므로 `tabBar` 옆 마지막 위치)
- `testBtnTapped`를 처리하던 `Reduce` 내부 분기 삭제
- `onboardingChecking` 액션 처리: `onboardingUseCase.isCompleted()`가 `true`면 `state.tabBarState = .init()`, `false`면 `state.onboardingState = .init()`으로 분기(완료 액션과 launch 분기를 분리 유지)
- `.onboarding(.delegate(.completed))` 처리 추가:
  1. `onboardingUseCase.isCompleted() == false`면 `AppLogger.core.log(.error, "온보딩 완료 저장 실패")` 로깅(`markAsCompleted()`가 `Void` 반환이므로 재조회로 검증)
  2. 로깅 여부와 무관하게 `state.onboardingState = nil`, `state.tabBarState = .init()`로 전환(에러 UI 없이 TabBar 진입 그대로 진행)
- `case .onboarding: return .none`(그 외 자식 액션 처리)
- `body` 마지막(`.ifLet(\.tabBarState, ...)` 다음)에 `.ifLet(\.onboardingState, action: \.onboarding) { OnboardingFeature() }` 추가
- 기존 toast/widget/deepLink 관련 로직은 무변경으로 유지

---

#### [x] Task 19 — `RootView.swift` 수정
**파일**: `Projects/Presentation/Sources/Root/RootView.swift`
- `#if DEBUG` 온보딩 완료 텍스트 버튼 블록 전체 삭제
- 기존 `Group` 분기를 `tabBarStore` → `onboardingStore` → `EmptyView` 순으로 재작성하여 `OnboardingView` 연결
- `#if DEBUG` 블록 삭제로 인해 `import Resource`가 더 이상 필요 없어지면 해당 import 정리(다른 곳에서 여전히 필요하면 유지)
- `.onAppear` / `.onOpenURL` / `.tabiToast` 관련 로직은 무변경으로 유지

---

#### [x] Task 20 — `SettingEtcItem.swift` 수정
**파일**: `Projects/Presentation/Sources/Setting/Entity/SettingEtcItem.swift`
- `case .privacyPolicy` 처리를 `return .openURL(TabiURL.privacyPolicy)`로 교체(`import Resource`는 이미 존재하므로 추가 import 불필요)
- 기존 `// MARK: - Privacy Policy` extension 및 `privacyPolicyURLString` 정적 상수 선언 삭제(별칭 없이 완전 이동, 진실 원천을 `TabiURL` 하나로 유지)
- `contactEmailAddress` 등 이번 범위 밖 상수는 건드리지 않음

---

### Phase 5. 생성 · 빌드 · 검증

#### [x] Task 21 — 빌드 검증
**대상**: `Tabikori.xcworkspace` / `AppDebug` 스킴
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` 실행(실제 사용 가능 시뮬레이터 확인 후 destination 조정)
- 빌드 성공 확인, 경고/에러 발생 시 원인 파악 후 해당 Task로 돌아가 수정

---

#### [ ] Task 22 — 수동 시나리오 검증 (Claude 자동화 불가, 사용자 확인 필요)
**대상**: 시뮬레이터 상 앱 실행
> Claude Code 세션에 시뮬레이터 탭 제스처를 실행할 Accessibility 권한이 없어 자동 탭 검증은 불가. 앱을 새로 설치해 홈 체험 화면(1번째 항목)까지는 스크린샷으로 렌더링을 확인했으나, 나머지 항목은 사용자가 직접 확인 필요
- 시뮬레이터 앱 삭제 후 최초 실행 → 홈 체험 화면 표시(디버그 버튼 없음) 확인
- 각 스텝에서 앞으로 스와이프가 막히는지 / "다음" 버튼으로만 진행되는지 / 뒤로 스와이프는 가능한지 확인
- 4개 체험 화면(홈/지도/일정/일정상세)에서 로딩 인디케이터·위치 권한 팝업·네트워크 요청이 전혀 발생하지 않는지 Xcode Network 계기판으로 확인
- 약관동의 화면: 체크박스가 회색·터치 불가 → "개인정보처리방침 보기" 탭 → 웹뷰 로드 → 닫기 → 체크박스 활성화 확인
- 체크 전 "시작하기" 비활성 → 체크 후 활성 → 탭 → TabBar 진입 확인
- 앱 강제 종료 후 재실행 → 온보딩 미표시, 바로 TabBar 진입 확인
- 기내모드 상태로 앱 삭제 후 재실행 → 웹뷰 로드 실패 오버레이(`TabiRetryableEmptyState`) 표시 → 그래도 닫으면 체크박스 활성화(불변 조건) 확인
- 온보딩 도중 백그라운드 전환 후 복귀 시 진행 상태 유지 / 강제 종료 후 재실행 시 홈 체험부터 다시 시작하는지 확인
- 설정 > 기타 > 개인정보처리방침 → 기존과 동일하게 외부 브라우저로 열리는지 회귀 확인(온보딩 웹뷰와 별개 경로)

---

## 체크리스트

### 품질 (DoD)
- [ ] `tuist install && tuist generate` 성공
- [ ] `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` 빌드 성공
- [ ] `RootFeature.testBtnTapped` / `RootView`의 `#if DEBUG` 블록 / `Strings.Root` 완전 제거 확인
- [ ] 개인정보처리방침 URL 문자열이 코드베이스에 `Resource/Sources/Constant/TabiURL.swift` 단 한 곳에만 존재(grep으로 확인)
- [ ] `Onboarding` 폴더가 `HomeFeature`/`MapFeature`/`PlanFeature`/`PlanDetailFeature` 및 관련 UseCase를 import·참조하지 않음(Store 비의존 순수 Sub 뷰 재사용만 허용)
- [ ] 체험 화면 전체에서 네트워크/위치/DB 의존성 호출 0건
- [ ] `hasViewedPolicy`가 `policyWebViewDismissed` 액션에서만 갱신되고, 리듀서에 체크박스/시작하기 이중 guard 존재
- [ ] 신규 문자열 전부 `Strings.Onboarding`(또는 기존 네임스페이스 재사용)에 정의, 코드 하드코딩 문자열 0건
- [ ] 신규 UI 컴포넌트는 `Presentation/Onboarding/Sub/`에만 위치, DesignSystem 변경은 `TabiPageIndicator` 기본값 파라미터 1건뿐이며 기존 3개 호출부 무변경
- [ ] 프로토콜 채택은 `extension` 분리, `private` 멤버는 하단 `extension`, 강제 언래핑 없음, `body` 50줄 규칙 준수
- [ ] `Domain`/`Data`/`App`/`DependencyInformation.swift` 무변경
- [ ] `.claude/rules/folder-structure.md`에 Resource `Constant/` 카테고리 반영

### 기능 (AC)
- [ ] 온보딩 미완료 상태로 앱 실행 시 디버그 버튼 대신 홈→지도→일정→일정상세→약관동의 순서의 온보딩이 표시된다
- [ ] 각 체험 화면에서 실제 네트워크/DB/위치 호출 없이 더미 데이터만 표시된다
- [ ] 약관동의 화면에서 웹뷰를 열람하기 전에는 체크박스가 비활성 상태다
- [ ] 웹뷰를 한 번 열었다가 닫으면 체크박스가 활성화된다
- [ ] 체크박스 체크 전에는 "시작하기" 버튼이 비활성 상태이고, 체크 후 버튼 탭 시 온보딩 완료 처리(`markAsCompleted`) 후 TabBar로 진입한다
- [ ] 앱을 재실행하면 온보딩이 다시 표시되지 않는다
- [ ] 개인정보처리방침 URL이 Resource 모듈에서 Setting/Onboarding 양쪽에 공용으로 참조된다
- [ ] `tuist generate` 및 빌드가 성공한다
</content>

# Plan: Onboarding

## 참조 Spec
- `@.claude/specs/features/Onboarding/spec.md`

## 참조 Skill
- `@.claude/skills/feature/SKILL.md` (spec → plan → tasks → 구현 흐름)
- 신규 화면(`Onboarding`) 폴더 구성은 `Presentation/Sources/Tabbar`(Entity 보유) + `Presentation/Sources/Map`(Sub 다수 보유) 조합을 레퍼런스로 삼는다
- `.claude/rules/swift-style.md`, `.claude/rules/folder-structure.md`

---

## 현재 상태 파악

### 신규

| 경로 | 내용 |
|------|------|
| `Projects/Resource/Sources/Constant/TabiURL.swift` | 앱 공용 외부 URL 상수 (`privacyPolicy`) |
| `Projects/Presentation/Sources/Onboarding/OnboardingFeature.swift` | 온보딩 TCA Reducer (스텝 진행 / 웹뷰 표시 / 동의 / 완료 delegate) |
| `Projects/Presentation/Sources/Onboarding/OnboardingView.swift` | TabView 페이징 루트 뷰 + 하단 공용 바 |
| `Projects/Presentation/Sources/Onboarding/OnboardingMock.swift` | 체험 화면 전용 정적 더미 데이터 네임스페이스 |
| `Projects/Presentation/Sources/Onboarding/Entity/OnboardingStep.swift` | 5스텝 enum (`home`/`map`/`plan`/`planDetail`/`agreement`) |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingStepFrame.swift` | 스텝 공용 프레임(제목·설명 + 콘텐츠 슬롯) |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingHomeStepView.swift` | 홈 목업 |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingMapStepView.swift` | 지도 목업 (실제 지도 SDK 미사용) |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingPlanStepView.swift` | 일정 목록 목업 |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingPlanDetailStepView.swift` | 일정 상세 목업 |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingAgreementStepView.swift` | 약관동의 스텝 |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingAgreementCheckBox.swift` | 온보딩 전용 체크박스 |
| `Projects/Presentation/Sources/Onboarding/Sub/OnboardingPolicyWebView.swift` | `WKWebView` `UIViewRepresentable` 래퍼 |

### 재사용
- **DesignSystem(수정 없이)**: `TabiButton`, `TabiLabel`, `TabiCard`, `TabiTag`, `TabiChip`, `TabiSpotRow`, `TabiNavigationBar`, `TabiSearchField`, `TabiCircleIconButton`, `TabiGlassIconButton`, `TabiEmptyState`, `TabiRetryableEmptyState`, `TabiPressStyle`, `TabiColor`, `TypographyStyle`, `TabiRadius`, `TabiAnimation`
- **Presentation 내부 순수 표현 뷰(Store 비의존 → 재사용 가능)**: `Plan/Sub/PlanCardView`(`plan`/`spotCount`/`onTapped`), `PlanDetail/Sub/PlanDetailSpotRow`(`spot`/`index`/`isFirst`/`isLast`/`isEditing`), `PlanDetail/Sub/PlanDetailDayHeader`, `Map/Sub/MapSearchResultRowView`(`spot`/`onTapped`), `PlanDetail/Model/TravelPlanDetailSpot+`, `Home/Model/CategoryType+`
  - 이들은 `HomeFeature`/`MapFeature`/`PlanFeature`/`PlanDetailFeature` 및 UseCase에 전혀 의존하지 않는 순수 뷰이므로, spec 제약("실제 Feature/UseCase 재사용 금지")을 위반하지 않는다
- **Domain Entity(생성만)**: `TravelPlan`, `TravelPlanDetail`, `TravelPlanDetailSpot`, `TouristSpot`, `Coordinate`, `CategoryType`
- **`OnboardingUseCase`** — `isCompleted()` / `markAsCompleted()` 그대로. 신규 UseCase·Repository·DependencyKey 없음
- **`AppLogger.core` / `AppLogger.network`**

### 수정

| 경로 | 내용 |
|------|------|
| `Projects/Presentation/Sources/Root/RootFeature.swift` | `testBtnTapped` 제거, `onboardingState` 추가, `onboarding` 하위 액션 + `.ifLet` 연결 |
| `Projects/Presentation/Sources/Root/RootView.swift` | `#if DEBUG` 버튼 제거 → `OnboardingView` 분기 |
| `Projects/Presentation/Sources/Setting/Entity/SettingEtcItem.swift` | `privacyPolicyURLString` 삭제, `.openURL(TabiURL.privacyPolicy)` 참조로 교체 |
| `Projects/Resource/Sources/Strings/Strings.swift` | `enum Onboarding` 네임스페이스 + 문자열 추가, `Strings.Root` 제거 |
| `Projects/DesignSystem/Sources/Indicator/TabiPageIndicator.swift` | `inactiveColor` 파라미터(기본값 = 기존 동작) 추가 |
| `.claude/rules/folder-structure.md` | Resource 하위 `Constant/` 카테고리 1줄 추가 |

### 삭제
- `RootFeature.Action.testBtnTapped` 및 해당 case 처리
- `RootView`의 `#if DEBUG` 온보딩 완료 버튼 블록
- `Strings.Root.onboardingCompleteButton` 및 비게 되는 `public enum Root {}` 선언
- `SettingEtcItem.privacyPolicyURLString` (Resource로 **이동**, 값 동일)

### 변경 불필요 (확인 완료)
- `Tuist/ProjectDescriptionHelpers/Dependency/DependencyInformation.swift` — 모듈 간 신규 의존 없음. `WebKit`은 시스템 프레임워크로, `Setting`이 `MessageUI`를 별도 선언 없이 `import`하는 선례와 동일하게 암시적 링크로 해결된다
- `Projects/Domain/Sources/UseCase/Onboarding/*` — `isCompleted`/`markAsCompleted` 시그니처 그대로
- `Projects/Domain/Sources/Dependency/Keys/OnboardingUseCaseDependencyKey.swift`, `DependencyValues.swift`, `Projects/App/Sources/Dependency/OnboardingUseCaseDependencyKey.swift` — DI 이미 완비
- `Projects/Data/Sources/Repository/Onboarding/OnboardingRepository.swift`, `TabiUserDefault`
- `Projects/Presentation/Sources/Navigation/StackPath.swift`, `Tabbar/TabBarFeature.swift`
- `Projects/Resource/Resources/Assets.xcassets` — 신규 에셋 없이 기존 `regionSeoul` 등 번들 이미지 사용

---

## 기술적 결정사항

### 1. `OnboardingFeature`는 `RootFeature`의 옵셔널 자식 리듀서로 붙인다 (`@Presents` 아님)
- `State`에 `var onboardingState: OnboardingFeature.State? = nil`을 추가하고 `body` 끝에 `.ifLet(\.onboardingState, action: \.onboarding) { OnboardingFeature() }`를 연결한다.
- **이유**: 온보딩은 시트/네비게이션 위에 얹히는 표현이 아니라 `tabBarState`와 **상호 배타적인 루트 화면**이다. 이미 `tabBarState`가 동일한 "옵셔널 + `.ifLet`" 패턴을 쓰고 있어 대칭이 유지된다.
- `.ifLet`은 `swift-style.md`의 body 선언 순서(하위 리듀서는 마지막)에 따라 기존 `.ifLet(\.tabBarState, ...)` **다음**에 배치한다.
- **대안(기각)**: `RootView`에서 `@State`로 온보딩 진행 상태를 들고 있기 — TCA 컨벤션 이탈이고 완료 처리 사이드이펙트를 리듀서 밖으로 밀어낸다.

### 2. 완료 처리는 `OnboardingFeature`가 수행하고, 진입 전환은 `RootFeature`가 delegate로 받는다
- `OnboardingFeature.Action.delegate(Delegate)` / `enum Delegate { case completed }` — `TranslateSearchFeature`, `PlanDetailFullMapFeature`가 이미 쓰는 패턴.
- `startButtonTapped` → `guard state.isAgreed` → `onboardingUsecase.markAsCompleted()` → `.send(.delegate(.completed))`
- `RootFeature`의 `.onboarding(.delegate(.completed))`:
  1. `onboardingUsecase.isCompleted() == false`면 `AppLogger.core.log(.error, "온보딩 완료 저장 실패")` — spec의 "저장 실패 시 Core 태그 로깅" 요구 충족. `markAsCompleted()`가 `Void`이므로 **재조회로 검증**하는 것이 유일한 실패 감지 수단이다.
  2. 로깅 여부와 무관하게 `state.onboardingState = nil`, `state.tabBarState = .init()` — spec의 "에러 UI 없이 TabBar 진입은 그대로 진행" 충족.
- **`onboardingChecking`은 분기만 담당**하도록 유지한다: `isCompleted()`면 `tabBarState = .init()`, 아니면 `onboardingState = .init()`. 완료 액션과 launch 분기를 한 액션에 섞으면 "저장 실패 시에도 진입"을 표현할 수 없다.
- **대안(기각)**: `RootFeature`가 `markAsCompleted()`를 호출 — 자식이 이미 UseCase를 필요로 하지 않게 되어 depth는 얕아지지만, "동의 완료"라는 도메인 이벤트의 소유자가 애매해지고 자식 단독 Preview/테스트가 불가능해진다.

### 3. 스텝 강제 순서는 "도달한 스텝까지만 렌더"로 구현한다
- `TabView(selection:)` + `.tabViewStyle(.page(indexDisplayMode: .never))`를 쓰되, `ForEach(OnboardingStep.allCases.prefix(store.reachedStepIndex + 1))`로 **아직 도달하지 않은 페이지를 트리에 넣지 않는다.**
- **이유**: SwiftUI 페이지 스타일 `TabView`는 스와이프 제스처를 선택적으로 막을 공식 API가 없다. 다음 페이지가 존재하지 않으면 앞으로 스와이프 자체가 불가능해지므로, 제스처를 해킹하지 않고 "순서대로만 진행 가능" 불변 조건을 구조적으로 만족한다. 뒤로 스와이프(이미 본 스텝 다시 보기)는 자연스럽게 허용된다.
- `State`는 `reachedStepIndex`(최대 도달)와 `currentStepIndex`(현재 표시) 두 값을 갖는다. "다음" 버튼 → `reachedStepIndex += 1` 후 `currentStepIndex`를 애니메이션과 함께 이동. 스와이프로 인한 selection 변경은 `currentStepIndex`만 갱신.
- `BindingReducer()` + `@ObservableState`로 `currentStepIndex`를 바인딩(`swift-style.md` body 순서: `BindingReducer()` 최상단).
- 진행 상태는 **저장하지 않는다** (spec: 재실행 시 처음부터).

### 4. 지도 체험은 실제 지도 SDK(`TabiMapView`/NMapsMap)를 쓰지 않는다
- `TabiMapView`는 NaverMap 타일을 네트워크로 내려받고 SDK 클라이언트 ID 초기화에 의존한다. spec 불변 조건("네트워크·위치·DB 호출 없음")과 정면 충돌한다.
- 대신 `OnboardingMapStepView`에서 `RoundedRectangle`(`.tabiSurfaceElevated` + `.tabiBorder` 스트로크) 위에 마커 핀을 `ZStack`으로 고정 배치한 **정적 지도 목업**을 그린다.
- 마커 핀은 `TabiMapMarkerPinView`가 DesignSystem 내부 `internal`이라 Presentation에서 접근 불가하므로, 동일한 시각(Circle + `TabiIcon` + `.tabiOnColor` 테두리)을 `OnboardingMapStepView` 내부 `private` 서브뷰로 재현한다. **DesignSystem의 접근 제어를 넓히지 않는다** — 온보딩 단독 사용처를 위해 공용 모듈의 API 표면을 늘리지 않기 위함.
- 하단 검색 패널은 `TabiSearchField` + `MapSearchResultRowView`(더미 `TouristSpot`, `thumbnailURLString: nil`)로 구성한다. `TabiSpotRow`는 `KFImage(nil)`이면 네트워크 요청 없이 placeholder만 그리므로 안전하다.

### 5. 더미 데이터는 `enum OnboardingMock` 네임스페이스로 모은다 (`.mock` 확장 금지)
- `PlanDetailMock.swift`가 이미 `TravelPlan.mock` / `TravelPlanDetail.mock`을 **같은 Presentation 모듈에** 선언하고 있어, 동일 패턴으로 `static let mock`을 추가하면 이름 충돌(중복 선언)이 발생한다.
- 따라서 `enum OnboardingMock { static let plan / planDetail / nearbySpots / searchResults / plans }` 형태의 네임스페이스 타입 1개로 모은다. 파일 위치는 기존 Mock 관례를 따라 `Onboarding/OnboardingMock.swift`(Feature 폴더 루트).
- 모든 이미지 필드는 `nil`, 좌표는 `Coordinate.seoulCityHall`(기존 상수) 등 상수만 사용 → 네트워크 0.
- 홈 목업의 지역 배너 이미지는 번들 에셋 `TabiImage.regionSeoul` 등을 쓴다(Kingfisher 원격 로드 금지).

### 6. 개인정보처리방침 URL은 `Resource/Sources/Constant/TabiURL.swift`에 신설한다
- spec 제약이 지적한 대로 URL 상수는 `folder-structure.md`의 Color/Image/Strings/Data 어디에도 맞지 않는다.
- **선택**: `Resource/Sources/Constant/TabiURL.swift`에 `public enum TabiURL { public static let privacyPolicy = "..." }` (값은 기존과 **완전 동일**한 문자열, 변경 금지).
  - Tuist 타겟의 sources glob이 `Sources/**`라 새 하위 폴더는 자동 포함된다.
  - `folder-structure.md`의 Resource 트리와 배치 표에 `Constant/` 한 줄을 추가한다(문서-코드 동기화).
- **대안(기각)**: `Strings.Common.privacyPolicyURLString` — 새 폴더가 필요 없지만, `Strings.swift`는 "일본어 UI 문구 + 한국어 주석" 규약을 가진 파일이라 로케일 무관 URL을 넣으면 파일의 의미가 흐려지고, 향후 이용약관/문의 URL이 추가될 때마다 같은 문제가 반복된다.
- `SettingEtcItem`의 정적 상수는 **삭제하고 참조만 교체**한다(별칭을 남기면 진실 원천이 둘이 된다). `contactEmailAddress`는 이번 범위 밖이므로 건드리지 않는다.

### 7. 웹뷰는 `Sub/`의 `UIViewRepresentable` + `.sheet`로 표시한다
- `SettingMailComposeView`(`UIViewControllerRepresentable`을 Setting 화면 `Sub/`에 두고 `.sheet`로 표시)와 동일한 배치·표현 패턴을 따른다. spec 제약대로 DesignSystem으로 승격하지 않는다.
- 시트 dismiss 경로가 **버튼과 드래그 두 가지**이므로, `SettingView`의 `Binding(get:set:)` + `guard isPresented == false else { return }` 패턴을 그대로 사용해 드래그 dismiss도 반드시 `policyWebViewDismissed` 액션을 발생시키게 한다. 이 액션 하나가 `hasViewedPolicy = true`의 유일한 진입점이다.
- 시트 상단에는 `TabiNavigationBar` + `TabiCircleIconButton("xmark")`로 닫기 버튼을 둔다(`WKWebView` 자체엔 내비게이션 크롬이 없음).
- **로드 실패 처리**: Coordinator(`WKNavigationDelegate`)의 `didFail` / `didFailProvisionalNavigation` → `onLoadFailed` 클로저 → `policyLoadFailed` 액션 → `AppLogger.network.log(.error, ...)` + `state.isPolicyLoadFailed = true`. 뷰는 웹뷰 위에 `TabiRetryableEmptyState(description:onRetry:)`를 오버레이한다. 재시도는 `state.policyReloadTrigger`(Int) 증가 → `updateUIView`에서 값 변화 감지 시 `webView.load(request)`.
- **불변 조건 유지**: 로드 성공/실패와 무관하게 **시트를 닫으면** 체크박스가 활성화된다. `hasViewedPolicy`는 `policyWebViewDismissed`에서만 갱신하고, `policyLoadFailed`는 절대 건드리지 않는다.

### 8. 체크박스는 온보딩 전용 컴포넌트로 `Sub/`에 만든다
- `SettingToggleRow`는 `Toggle` 기반이고 "약관 동의 체크" 시맨틱이 아니며, DesignSystem에도 체크박스가 없다(grep 확인).
- `OnboardingAgreementCheckBox`: `Button` + `Image(systemName: isChecked ? "checkmark.square.fill" : "square")` + `TabiLabel`, `TabiPressStyle` 적용.
- **활성/비활성 표현**: `.disabled(isEnabled == false)` + `.opacity(isEnabled ? 1 : 0.4)` (`TabiButton`이 `@Environment(\.isEnabled)`로 0.5 opacity를 주는 방식과 동일 계열).
- 리듀서에도 이중 방어를 둔다: `agreementCheckBoxTapped`에서 `guard state.hasViewedPolicy else { return .none }`, `startButtonTapped`에서 `guard state.isAgreed else { return .none }`. UI 비활성만으로 불변 조건을 지키지 않는다.

### 9. `TabiPageIndicator`는 기본값 있는 파라미터 추가로 재사용한다
- 현재 비선택 dot이 `Color.white.opacity(0.6)` 하드코딩이라 온보딩의 밝은 배경에서 보이지 않는다.
- `public init(count:currentIndex:inactiveColor: Color = .white.opacity(0.6))`로 **기본값을 기존 동작과 동일**하게 두면, 기존 3개 호출부(`PhotoViewerView`, `DetailHeroView`, `PlanDetailFullMapView`)는 무변경으로 컴파일된다. 온보딩만 `Color.getTabiColor(.tabiBorder)`를 넘긴다.
- `swift-style.md` 9번(재사용 우선) + CLAUDE.md("무관한 코드 수정 금지") 둘 다 만족하는 최소 변경. 이번 작업에서 DesignSystem을 건드리는 **유일한** 지점이다.
- **대안(기각)**: 온보딩 전용 인디케이터를 `Sub/`에 새로 만들기 — DesignSystem 무변경이지만 dot 레이아웃 로직이 중복된다.

### 10. 체험 화면의 인터랙션 범위
- 기본 원칙: 목업 뷰의 콜백은 **no-op 클로저**로 넘긴다(`PlanCardView(onTapped: {})`, `TabiSpotRow(onTap: {})`). 실제 Feature 상태·의존성에 전혀 닿지 않는다는 spec 불변 조건을 코드 구조로 보장한다.
- 다만 "체험형"이라는 목적을 위해, **`OnboardingFeature.State` 내부에서만 완결되는** 시각적 인터랙션 2개를 허용한다:
  - `homeSelectedCategory: CategoryType?` — 홈 목업 카테고리 칩 선택 하이라이트
  - `planDetailSelectedDayIndex: Int` — 일정상세 목업 일자 칩 전환
  - 두 값 모두 온보딩 State에만 존재하며 어떤 UseCase도 호출하지 않는다.

### 11. 범위 밖으로 명시하는 것
- **Analytics 이벤트**(`onboardingCompleted` 등) — `AnalyticsEvent`(Domain)와 App DI 양쪽을 건드려야 하고 spec 요구가 없다. 후속 과제로 기록.
- **온보딩 스텝 진행 상태 영속화 / 건너뛰기 버튼 / 재열람 진입점(설정에서 온보딩 다시 보기)** — spec 범위 외.
- **이용약관(개인정보처리방침 외 문서) 동의** — spec은 개인정보처리방침 단일 항목만 요구.
- **테스트 코드** — 프로젝트에 테스트 타겟이 아직 없음(CLAUDE.md).

---

## 구현 순서

> 의존 방향(`Resource` → `DesignSystem` → `Presentation`) 순서로 진행한다. Phase 1~3에서 신규 `.swift` 파일이 추가되므로 **Phase 4 직전에 `tuist install && tuist generate`를 1회 실행**한다. 그 전 단계에서 빌드하면 stale 프로젝트로 오탐 에러가 난다.

### Phase 1. Resource
1. `Resource/Sources/Constant/TabiURL.swift` 신규
   - `public enum TabiURL`, `public static let privacyPolicy` — 값은 `SettingEtcItem.privacyPolicyURLString`과 **바이트 단위로 동일**하게 복사. 한국어 doc 주석 유지.
2. `Resource/Sources/Strings/Strings.swift` 수정
   - 최상단 `public enum Strings` 안에 `public enum Onboarding {}` 추가 (`Root` 자리에 배치해 순서 유지)
   - `public enum Root {}` 및 `public extension Strings.Root` 블록 삭제
   - `public extension Strings.Onboarding` 신규 — 각 항목 위에 한국어 주석, 값은 일본어:
     - 스텝 제목/설명 5쌍 (홈/지도/일정/일정상세/약관동의)
     - 공용 버튼: 다음, 시작하기
     - 약관동의: 체크박스 라벨, "개인정보처리방침 보기" 버튼, 웹뷰 열람 전 안내 문구
     - 웹뷰: 시트 타이틀, 로드 실패 설명 문구
     - 목업 데이터에 노출되는 화면 문구 중 재사용 불가한 것(체험용 안내 배지 등)
   - 목업 화면의 카테고리/공용 라벨은 기존 `Strings.Common.*`, `Strings.Home.*`, `Strings.Plan.*`, `Strings.Map.searchPlaceholder`를 **먼저 재사용**하고, 없을 때만 `Strings.Onboarding`에 추가
3. `.claude/rules/folder-structure.md` — Resource 트리와 "파일 종류/위치" 표에 `Constant/` 항목 추가

### Phase 2. DesignSystem
1. `DesignSystem/Sources/Indicator/TabiPageIndicator.swift`
   - `private let inactiveColor: Color` + `init`에 `inactiveColor: Color = .white.opacity(0.6)` 추가
   - `dot(isSelected:)`의 비선택 분기를 `self.inactiveColor`로 교체
   - 기존 3개 호출부는 무변경임을 grep으로 재확인

### Phase 3. Presentation — Onboarding 신규 화면
1. `Onboarding/Entity/OnboardingStep.swift`
   - `enum OnboardingStep: Int, CaseIterable, Identifiable` — `home`/`map`/`plan`/`planDetail`/`agreement`
   - `var title: String` / `var description: String` → `Strings.Onboarding.*` 매핑
   - `var isLast: Bool`
   - `AppTab.swift`(Tabbar/Entity)와 동일한 구성 방식
2. `Onboarding/OnboardingMock.swift`
   - `enum OnboardingMock` — `plan: TravelPlan`, `planDetail: TravelPlanDetail`(2일치), `nearbySpots: [TouristSpot]`, `searchResults: [TouristSpot]`, `plans: [TravelPlan]`
   - 썸네일 URL 전부 `nil`, 좌표는 기존 상수 사용, 날짜는 `Date()` 기준 상대 계산(`PlanDetailMock` 방식)
3. `Onboarding/Sub/` 컴포넌트
   - `OnboardingStepFrame.swift` — `title`/`description` + `@ViewBuilder content` 공용 프레임(모든 스텝의 상단 카피 영역 통일)
   - `OnboardingHomeStepView.swift` — `TabiSearchField`(비활성) + 환율 카드 목업(`TabiCard`) + 지역 배너(`Image(TabiImage.regionSeoul)`) + 카테고리 칩(`TabiChip`, 선택 하이라이트) + 근처 스팟 리스트(`TabiSpotRow`)
   - `OnboardingMapStepView.swift` — 정적 지도 목업 + 마커 핀 + 하단 검색 패널(`MapSearchResultRowView`)
   - `OnboardingPlanStepView.swift` — `TabiNavigationBar` 목업 + `PlanCardView` 2~3장(`onTapped: {}`)
   - `OnboardingPlanDetailStepView.swift` — `PlanDetailDayHeader` + 일자 칩(`TabiChip`, 선택 전환) + `PlanDetailSpotRow` 타임라인(`isEditing: false`)
   - `OnboardingAgreementCheckBox.swift` — 결정사항 8
   - `OnboardingPolicyWebView.swift` — 결정사항 7. `import WebKit`, `makeUIView`에서 `WKWebView` 생성 + `navigationDelegate = context.coordinator` + 최초 `load`, `updateUIView`에서 `reloadTrigger` 변화 시 재로드, `makeCoordinator`로 `WKNavigationDelegate` Coordinator 반환. Coordinator는 `final class` + `[weak self]` 규칙 준수
   - `OnboardingAgreementStepView.swift` — 안내 문구 + `TabiButton(개인정보처리방침 보기, style: .secondary)` + `OnboardingAgreementCheckBox`
   - 각 파일 `body` 50줄 초과 시 파일 내 `private extension`의 `@ViewBuilder` 함수로 분리
4. `Onboarding/OnboardingFeature.swift`
   - `@Dependency(\.onboardingUseCase)`
   - `State`(선언 순서: 공개 → fileprivate → `@Presents` 없음): `currentStepIndex`, `reachedStepIndex`, `hasViewedPolicy`, `isAgreed`, `isPolicyWebViewPresented`, `isPolicyLoadFailed`, `policyReloadTrigger`, `homeSelectedCategory`, `planDetailSelectedDayIndex`
     - 계산 프로퍼티: `currentStep`, `isStartEnabled`(= `isAgreed`), `visibleSteps`
   - `Action`(선언 순서: 바인딩 → 생명주기 → 인터랙션 → 비동기 결과 → 하위/delegate): `binding`, `nextButtonTapped`, `policyViewButtonTapped`, `policyWebViewDismissed`, `policyRetryTapped`, `agreementCheckBoxTapped`, `startButtonTapped`, `homeCategoryTapped(CategoryType)`, `planDetailDayTapped(Int)`, `policyLoadFailed`, `delegate(Delegate)`
   - `body`: `BindingReducer()` → `Reduce { }` (하위 리듀서 없음)
   - `nextButtonTapped`: 마지막 스텝이면 `.none`, 아니면 `reachedStepIndex = max(reached, current+1)` + `currentStepIndex += 1`
   - `policyWebViewDismissed`: `isPolicyWebViewPresented = false`, `hasViewedPolicy = true`, `isPolicyLoadFailed = false`
   - `policyLoadFailed`: `isPolicyLoadFailed = true` + `AppLogger.network.log(.error, ...)` (이펙트 없이 즉시 로깅)
   - `agreementCheckBoxTapped` / `startButtonTapped`: 결정사항 8의 guard 이중 방어
   - `startButtonTapped`: `markAsCompleted()` 호출 후 `.send(.delegate(.completed))`
   - `delegate`: `.none`
5. `Onboarding/OnboardingView.swift`
   - `@Bindable private var store: StoreOf<OnboardingFeature>`
   - `VStack`: `TabView(selection: $store.currentStepIndex)` (도달 스텝까지만 `ForEach`) + `.tabViewStyle(.page(indexDisplayMode: .never))` + `.animation(.tabiStandard, value:)`
   - 하단 공용 바: `TabiPageIndicator(count:currentIndex:inactiveColor:)` + `TabiButton(다음/시작하기, style: .primary, isExpanded: true)`
     - 마지막 스텝에서는 `.disabled(store.isStartEnabled == false)`
   - `.sheet(isPresented: Binding(get:set:))` → `OnboardingPolicyWebView` + 상단 닫기 바 + 실패 시 `TabiRetryableEmptyState` 오버레이
   - `#Preview` 추가

### Phase 4. 연결 및 참조 교체
> 이 Phase 시작 전 `tuist install && tuist generate` 실행

1. `Root/RootFeature.swift`
   - `State`에 `var onboardingState: OnboardingFeature.State? = nil` 추가(`tabBarState` 다음)
   - `Action`: `testBtnTapped` 삭제, `case onboarding(OnboardingFeature.Action)` 추가(하위 액션이므로 `tabBar` 옆 마지막)
   - `onboardingChecking`: `isCompleted()`면 `tabBarState = .init()`, else `onboardingState = .init()`
   - `.onboarding(.delegate(.completed))`: 결정사항 2의 검증·로깅·전환
   - `case .onboarding: return .none` (그 외 자식 액션)
   - `body` 마지막에 `.ifLet(\.onboardingState, action: \.onboarding) { OnboardingFeature() }`
   - 기존 toast/widget/deepLink 로직은 **무변경**
2. `Root/RootView.swift`
   - `Group` 분기를 `tabBarStore` → `onboardingStore` → `EmptyView` 순으로 재작성, `#if DEBUG` 블록 제거
   - `import Resource`가 더 이상 필요 없으면 정리
   - `.onAppear` / `.onOpenURL` / `.tabiToast`는 **무변경**
3. `Setting/Entity/SettingEtcItem.swift`
   - `case .privacyPolicy: return .openURL(TabiURL.privacyPolicy)`
   - `// MARK: - Privacy Policy` extension 및 `privacyPolicyURLString` 삭제 (`import Resource`는 이미 존재)

### Phase 5. 생성 · 빌드 · 검증
1. `tuist install && tuist generate`
2. `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
3. 수동 시나리오
   - 시뮬레이터 앱 삭제 후 최초 실행 → 홈 체험 화면 표시(디버그 버튼 없음)
   - 각 스텝에서 **앞으로 스와이프가 막히는지** / 다음 버튼으로만 진행되는지 / 뒤로 스와이프는 되는지
   - 4개 체험 화면에서 로딩 인디케이터·위치 권한 팝업·네트워크 요청이 전혀 발생하지 않는지 (Xcode Network 계기판으로 확인)
   - 약관동의 화면: 체크박스가 회색·터치 불가 → "개인정보처리방침 보기" → 웹뷰 로드 → 닫기 → 체크박스 활성화
   - 체크 전 "시작하기" 비활성 → 체크 후 활성 → 탭 → TabBar 진입
   - 앱 강제 종료 후 재실행 → 온보딩 미표시, 바로 TabBar
   - **기내모드**로 앱 삭제 후 재실행 → 웹뷰 로드 실패 오버레이 표시 → 그래도 닫으면 체크박스 활성화(불변 조건)
   - 온보딩 도중 백그라운드 전환 후 복귀 → 진행 유지 / 강제 종료 후 재실행 → 홈 체험부터 다시
   - 설정 > 기타 > 개인정보처리방침 → 기존과 동일한 외부 브라우저 열림(URL 이동 회귀 확인)

---

## 완료 조건
- [ ] Spec Acceptance Criteria 8개 전부 충족
- [ ] `RootFeature.testBtnTapped` / `RootView`의 `#if DEBUG` 블록 / `Strings.Root` 완전 제거
- [ ] 개인정보처리방침 URL 문자열이 코드베이스에 **단 한 곳**(`Resource/Sources/Constant/TabiURL.swift`)에만 존재 (grep으로 확인)
- [ ] `Onboarding` 폴더가 `HomeFeature`/`MapFeature`/`PlanFeature`/`PlanDetailFeature` 및 관련 UseCase를 **import·참조하지 않음** (Store 비의존 순수 Sub 뷰 재사용만 허용)
- [ ] 체험 화면 전체에서 네트워크/위치/DB 의존성 호출 0건
- [ ] `hasViewedPolicy`가 `policyWebViewDismissed` 액션에서만 갱신되고, 리듀서에 체크박스/시작하기 이중 guard가 존재
- [ ] 신규 문자열 전부 `Strings.Onboarding`(또는 기존 네임스페이스 재사용)에 정의, 코드 하드코딩 문자열 0건
- [ ] 신규 UI 컴포넌트는 `Presentation/Onboarding/Sub/`에만 위치, DesignSystem 변경은 `TabiPageIndicator`의 기본값 파라미터 1건뿐이며 기존 3개 호출부 무변경
- [ ] 프로토콜 채택은 `extension` 분리, `private` 멤버는 하단 `extension`, 강제 언래핑 없음, `body` 50줄 규칙 준수
- [ ] `Domain`/`Data`/`App`/`DependencyInformation.swift` 무변경
- [ ] `.claude/rules/folder-structure.md`에 Resource `Constant/` 카테고리 반영
- [ ] `tuist generate` 및 `AppDebug` 빌드 성공
- [ ] 후속 과제 기록: 온보딩 Analytics 이벤트, 설정에서 온보딩 다시 보기

---

## 참고: 구현 중 확인이 필요한 지점
- `TabiChip` / `TabiNavigationBar` / `TabiCard`의 정확한 `init` 시그니처는 구현 시 파일에서 확인 후 사용 (추측 금지)
- `Coordinate.seoulCityHall` 외에 목업에 쓸 좌표 상수가 필요하면 새로 만들지 말고 기존 상수 재사용
- `PlanCardView` / `PlanDetailSpotRow` / `PlanDetailDayHeader`는 `internal`이므로 같은 Presentation 모듈 내에서만 접근 가능 — 접근 제어를 넓히지 말 것

---

### Critical Files for Implementation
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Root/RootFeature.swift` (온보딩 분기·완료 전환의 유일한 조립 지점)
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Root/RootView.swift` (`#if DEBUG` 버튼 제거 및 `OnboardingView` 연결)
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Setting/Entity/SettingEtcItem.swift` (`privacyPolicyURLString`이 현재 위치한 곳 — Resource로 이동)
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Resource/Sources/Strings/Strings.swift` (`Strings.Root` 제거 + `Strings.Onboarding` 신설)
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Setting/Sub/SettingMailComposeView.swift` (`OnboardingPolicyWebView`의 Representable + `.sheet` 직접 템플릿)

# Plan: setting

## 참조 Spec
- @specs/features/setting/spec.md

## 참조 Skill
신규 화면 생성 시
- @skills/create-feature/SKILL.md
  - (현재 레포에 `create-feature` 스킬은 존재하지 않음. 신규 Feature/View는 StackPath push 선례인 `FestivalFeature`/`FestivalView`, Alert 처리 선례인 `AddCustomPlaceFeature` 구조를 그대로 따른다)

---

## 현재 상태 파악

### 신규
- **Domain**
  - `Domain/Sources/UseCase/DataReset/DataResetUseCaseProtocol.swift` — `func resetAll() async throws`
  - `Domain/Sources/UseCase/DataReset/DataResetUseCase.swift` — Bookmark / TravelPlan / SearchHistory Repository 3종 주입, 삭제 오케스트레이션 + 부분 실패 정책 소유
  - `Domain/Sources/UseCase/DataReset/TestDataResetUseCase.swift` — `testValue`용 더블 (실패 주입용 `var` 프로퍼티 공개)
  - `Domain/Sources/Dependency/Keys/DataResetUseCaseDependencyKey.swift` — `TestDependencyKey` 채택, `testValue`만 정의
- **App**
  - `App/Sources/Dependency/DataResetUseCaseDependencyKey.swift` — `@retroactive DependencyKey` liveValue (Data Repository 3종 조립)
- **Presentation**
  - `Presentation/Sources/Setting/SettingFeature.swift`
  - `Presentation/Sources/Setting/SettingView.swift`
  - `Presentation/Sources/Setting/Sub/SettingSectionCard.swift` — 섹션 타이틀 + `TabiCard` 래핑
  - `Presentation/Sources/Setting/Sub/SettingRow.swift` — 아이콘 / 타이틀 / 보조값(권한 상태) / chevron 행
  - `Presentation/Sources/Setting/Entity/SettingEtcItem.swift` — 기타 섹션 5개 항목 정의(표시 타이틀, 동작 종류: 정적 텍스트 / 외부 링크 / mailto / 버전 표시)
  - `Presentation/Sources/SettingInfo/SettingInfoFeature.swift`, `SettingInfoView.swift` — 정적 텍스트(데이터 출처 / 오픈소스 라이선스) 공용 표시 화면 (결정 7)
- **Resource**
  - `Strings.swift`에 `Strings.Setting` 네임스페이스 신설 (기존 파일 수정)

### 재사용
- `TabiNavigationBar(subtitle:title:trailing:)` — 이미 `@ViewBuilder trailing` 파라미터를 기본값 `EmptyView`로 제공하므로 **DesignSystem 수정 불필요** (확인 완료)
- `TabiCircleIconButton(systemName:foregroundColor:action:)` — 설정 진입 아이콘으로 그대로 사용 (확인 완료)
- `TabiCard`, `TabiLabel`, `TabiPressStyle`, `TabiColor`, `TabiRadius`, `TabiEmptyState` — 신규 DesignSystem 컴포넌트 제작 없음 (AC 6)
- TCA `AlertState` / `@Presents var alert` / `.ifLet(\.$alert, action: \.alert)` — `AddCustomPlaceFeature`, `AddTravelPlanFeature` 선례 그대로 (별도 Alert 컴포넌트 불필요, 확인 완료)
- `locationUseCase.checkAuthorization()` → `LocationAuthorizationStatus` — 권한 상태 표시에 재사용, 신규 UseCase 불필요
- `HomeFeature.openSettingsButtonTapped`의 `UIApplication.openSettingsURLString` + `guard let` 조기 종료 패턴 — 동일 로직을 `SettingFeature`에 적용
- `FestivalView`의 스택 화면 구성 패턴 — `navigationTitle` + `navigationBarTitleDisplayMode(.inline)` + `ToolbarItem(.topBarLeading)` chevron.left + `navigationBarBackButtonHidden(true)` + `interactivePopGestureEnabled(true)`
- `TabBarFeature`의 `case .path(.element(id: _, action: .detail(.isBookmarkedResult))): return .send(.bookmark(.onAppear))` — 초기화 완료 후 탭 리로드에 동일 패턴 적용
- `SearchHistoryRepositoryProtocol.save(_:)` — 빈 배열 저장으로 최근 검색어 삭제 (프로토콜 무변경, 결정 3)
- `Strings.Plan.alertConfirm`("確認"), `Strings.Map.searchCancel`("キャンセル") — Alert 버튼 문구 재사용 후보 (신규 문자열 최소화)
- `TravelPlanRepository.remove(planId:)`의 3개 모델(`TravelPlanModel` / `TravelPlanDetailModel` / `TravelPlanDetailSpotModel`) 삭제 로직 — `removeAll()` 구현 시 동일 구조 차용

### 수정
- `Presentation/Sources/Navigation/StackPath.swift` — `case setting(SettingFeature)` 추가
- `Presentation/Sources/Tabbar/TabBarFeature.swift`
  - `.home(.settingButtonTapped)` → `state.path.append(.setting(SettingFeature.State()))`
  - `.path(.element(id: _, action: .setting(.resetCompleted)))` → Bookmark / Plan 탭 리로드
- `Presentation/Sources/Tabbar/TabBarView.swift` — `destination` switch에 `case .setting(let store): SettingView(store: store)` 추가
- `Presentation/Sources/Home/HomeFeature.swift` — `Action`에 `case settingButtonTapped` 추가(리듀서에서는 `.none`, 실제 push는 부모가 처리)
- `Presentation/Sources/Home/HomeView.swift` — `TabiNavigationBar` 호출에 `trailing:` 클로저 추가
- `Domain/Sources/Dependency/DependencyValues.swift` — `dataResetUseCase` 프로퍼티 추가
- `Domain/Sources/RepositoryProtocol/BookmarkRepositoryProtocol.swift` — `func removeAll() async throws` 추가
- `Domain/Sources/RepositoryProtocol/TravelPlanRepositoryProtocol.swift` — `func removeAll() async throws` 추가
- `Data/Sources/Repository/Bookmark/BookmarkRepository.swift` — `removeAll()` 구현
- `Data/Sources/Repository/TravelPlan/TravelPlanRepository.swift` — `removeAll()` 구현 (Plan / Detail / DetailSpot 3개 모델 모두 삭제)
- `Resource/Sources/Strings/Strings.swift` — `Strings.Setting` 네임스페이스 + 문구 추가
- `Tuist/ProjectDescriptionHelpers/Dependency/DependencyInformation.swift` — **수정 불필요** (신규 모듈·모듈 간 의존 없음. `.swift` 파일 추가만 있으므로 `tuist generate`만 필요)

### 삭제
- 없음
  - `HomeFeature.openSettingsButtonTapped`는 위치 권한 배너 전용으로 **그대로 유지**한다. Setting 화면의 GPS 항목과 동작이 같지만 진입 경로/문맥이 달라 통합하지 않는다(무관 코드 수정 금지).

---

## 미확정 사항 (Phase 0에서 사용자 확인 필요)

spec의 `(확인 필요)` 항목이 그대로 남아 있다. 아래 값이 확정되기 전에는 Phase 5(기타 섹션)를 완료할 수 없다.

| 항목 | 확인해야 할 것 | plan의 제안 (결정 7 참조) |
|------|----------------|---------------------------|
| 데이터 출처 | 인앱 텍스트 / 외부 링크 | 인앱 정적 텍스트 (한국관광공사 EngService2, 네이버 지도·Geocoding, 환율 소스 표기) |
| 개인정보처리방침 | 게시 URL 유무 | 외부 링크(`openURL`). **URL 미확보 시 항목 자체를 노출하지 않는다** (빈 화면 이동 방지) |
| 오픈소스 라이선스 | 인앱 텍스트 / 외부 링크 | 인앱 정적 텍스트 (Kingfisher, NMapsMap, swift-composable-architecture — `Tuist/Package.swift` 기준) |
| 문의하기 | mailto / 외부 폼 | `mailto:` (수신 주소 확정 필요) |
| "기타" | 구체적 의미 | 앱 버전 표시(`CFBundleShortVersionString` 1.0.0 / `CFBundleVersion` 1, 탭 동작 없음) |

---

## 기술적 결정사항

- **[결정 1] 진입 액션명은 `settingButtonTapped` — 기존 `openSettingsButtonTapped`와 분리한다**
  - `HomeFeature`에는 이미 `openSettingsButtonTapped`(iOS **설정 앱**으로 이동)가 있다. 신규 `settingButtonTapped`는 **앱 내 설정 화면**으로 진입하는 액션이라 의미가 전혀 다르다.
  - 이름이 비슷해 혼동 위험이 크므로 두 액션 모두 유지하되, 리듀서 case에 용도 주석을 남긴다. 통합/개명은 스코프 밖.
  - `settingButtonTapped`는 `HomeFeature`에서 `.none`을 반환하고, 실제 push는 `TabBarFeature`가 수행한다 — `festivalMoreButtonTapped` → `.festival` push와 정확히 동일한 구조(확인 완료).

- **[결정 2] Setting은 `StackPath`에 케이스를 추가해 push (sheet 아님)**
  - 이유: spec이 "전체 설정 화면"을 요구하며 하위 이동(정보 화면)이 뒤따른다. `AddCustomPlace`처럼 일회성 입력 폼이면 sheet가 맞지만, 설정은 목록형 화면이라 스택 push가 앱 내 일관성에 부합한다(`festival`, `region` 선례).
  - `StackState`는 `TabBarFeature.State.path` 하나뿐이고 탭별 상태(`homeState` 등)와 분리되어 있으므로, Setting push/pop이 다른 탭 상태를 건드리지 않는다 → spec 불변 조건 "다른 탭 상태에 영향 없음"이 구조적으로 보장된다(확인 완료).
  - `StackPath.State`/`Action`은 `Equatable` 채택이 강제되므로 `SettingFeature.State`/`Action`도 `Equatable`이어야 한다.

- **[결정 3] 데이터 초기화는 신규 `DataResetUseCase` 하나로 캡슐화한다**
  - 대안 A(기각): `SettingFeature`가 `bookmarkUseCase` / `travelPlanUseCase` / `searchHistoryUseCase` 3개를 직접 주입받아 각각 호출 → "onboardingCompleted는 제외한 전체 삭제"라는 **도메인 규칙이 Presentation에 흩어진다.** 이후 삭제 대상이 늘 때마다 화면 코드를 고쳐야 한다.
  - 채택 B: `DataResetUseCase`가 `BookmarkRepositoryProtocol` / `TravelPlanRepositoryProtocol` / `SearchHistoryRepositoryProtocol`을 주입받아 `resetAll()` 하나를 노출. Presentation은 삭제 대상이 무엇인지 모른다.
  - **Repository를 직접 주입**하는 이유: 기존 UseCase들이 모두 Repository 주입 패턴(`BookmarkUseCase(repository:)`)이고, UseCase가 UseCase를 의존하는 선례가 레포에 없다.
  - `onboardingCompleted`는 `OnboardingRepository`를 아예 주입하지 않으므로 **접근 경로 자체가 없어** 삭제될 수 없다 → spec 제약이 타입 레벨에서 보장된다.

- **[결정 4] 삭제 프리미티브 — Bookmark/TravelPlan은 `removeAll()` 신설, SearchHistory는 `save([])` 재사용**
  - `BookmarkRepositoryProtocol` / `TravelPlanRepositoryProtocol`에는 전체 삭제 API가 없어 `removeAll()`을 추가한다. 기존 구현체의 `remove(...)` 패턴(ModelContext 생성 → fetch → delete → save → 실패 시 `AppLogger.core` + `TabiError.persistenceFailed` 매핑)을 그대로 따른다.
  - `TravelPlanRepository.removeAll()`은 `TravelPlanModel` / `TravelPlanDetailModel` / `TravelPlanDetailSpotModel` **3개 스키마를 모두** 지운다. 셋 다 `TravelPlanModelContainer` 하나에 들어 있고, 기존 `remove(planId:)`도 세 모델을 함께 지운다(확인 완료). 따라서 `TravelPlanDetailRepositoryProtocol`에는 `removeAll()`을 추가하지 않는다 — 중복 책임이 된다.
  - 최근 검색어는 `SearchHistoryRepositoryProtocol.save([])`로 충분하다. `TabiUserDefaultProtocol`에는 `remove(forKey:)`가 없는데(확인 완료), 이를 추가하면 App Group UserDefaults 전역 API가 넓어지는 대신 얻는 게 없다 — `fetch()`가 빈 배열을 반환하는 결과는 동일하므로 **프로토콜을 건드리지 않는다.**

- **[결정 5] 부분 실패 정책 — 중단하지 않고 끝까지 시도한 뒤, 하나라도 실패하면 실패 알림**
  - spec의 미해결 항목("일부만 성공 시 처리")에 대한 답이다.
  - 3개 삭제는 서로 다른 저장소(SwiftData 컨테이너 2개 + UserDefaults)라 **전역 트랜잭션/롤백이 불가능**하다. 첫 실패에서 즉시 throw하면, 사용자가 재시도해도 늘 같은 항목에서 막혀 나머지가 영영 삭제되지 않는다.
  - 따라서 각 삭제를 개별적으로 시도해 실패 항목을 수집하고, 전부 끝난 뒤 실패가 있으면 `TabiError.persistenceFailed(message:)`에 실패 항목을 담아 throw한다. 성공한 삭제는 되돌리지 않는다(재시도 시 이미 지워진 것은 no-op).
  - 로깅은 `AppLogger.core`(Repository) + `AppLogger.view`(Feature) 이중으로 남긴다.
  - 실패 알림 문구는 "일부 데이터가 남아 있을 수 있으니 다시 시도해 달라"는 취지로 작성한다.
  - 신규 결과 Entity는 만들지 않는다 — 성공/실패 이분법이면 화면에서 필요한 정보는 다 표현된다.

- **[결정 6] 초기화 확정 Alert — TCA `AlertState` + `Action.Alert.resetConfirmed`**
  - `AddCustomPlaceFeature`의 `@Presents var alert: AlertState<Action.Alert>?` + `.ifLet(\.$alert, action: \.alert)` 구조를 그대로 사용한다(해당 선례의 `Alert` enum은 비어 있었지만 여기서는 `case resetConfirmed`를 갖는다).
  - Alert에는 취소 버튼(`role: .cancel`)과 삭제 버튼(`role: .destructive`)을 둔다. **`resetConfirmed`를 받기 전에는 어떤 삭제 Effect도 발행하지 않는다** → spec 불변 조건 충족.
  - `isResetting` 플래그 + `CancelID.reset`으로 중복 실행을 막는다.
  - 결과 알림도 같은 `alert` 슬롯을 재사용한다(성공/실패 문구만 다름). 별도 토스트 컴포넌트는 만들지 않는다(AC 6).

- **[결정 7] 기타 섹션 — 동작 종류를 항목 데이터로 표현하고, 정적 텍스트는 공용 화면 하나로 처리**
  - `SettingEtcItem`(Presentation 화면 전용 Entity)이 각 항목의 타이틀과 동작 종류(정적 텍스트 / 외부 링크 / mailto / 표시 전용)를 갖는다. 화면 코드에 5개 분기를 하드코딩하지 않는다.
  - 정적 텍스트 2종(데이터 출처, 오픈소스 라이선스)은 **`SettingInfoFeature` 하나**를 sheet로 띄우고 종류만 파라미터로 넘긴다. `StackPath`에 케이스를 2개 더 추가하면 앱 전역 네비게이션 enum이 정보성 화면으로 오염된다.
  - 외부 링크/mailto는 `openURL`(HomeView가 이미 `@Environment(\.openURL)` 사용 중) 또는 Feature 쪽 `UIApplication.shared.open`을 쓴다. **URL 생성 실패 시 조용히 종료**(GPS 항목과 동일 정책).
  - URL/이메일 상수는 `Setting/Entity/SettingEtcItem.swift`에 둔다. `Strings`는 사용자 노출 문구용이고, `Core/Config/AppConfig.swift`는 로그 플래그 전용(확인 완료)이라 둘 다 적합하지 않다.
  - **Phase 0에서 확정되지 않은 항목은 노출하지 않는다.** 눌러도 아무 일도 없는 행을 만드는 것보다 낫다.

- **[결정 8] GPS 권한 상태는 화면 진입 시점과 앱 포그라운드 복귀 시점에 모두 갱신한다**
  - `locationUseCase.checkAuthorization()`은 동기 함수라 `onAppear`에서 즉시 state에 반영할 수 있다(`HomeFeature.onAppear`와 동일).
  - **핵심 함정**: 사용자가 iOS 설정 앱에서 권한을 바꾸고 돌아와도, Setting 화면은 계속 화면에 떠 있었으므로 `onAppear`가 다시 호출되지 않아 상태가 낡은 채로 남는다.
  - 따라서 `SettingView`에서 `@Environment(\.scenePhase)`가 `.active`로 바뀔 때 권한 재조회 액션을 보낸다.
  - `LocationAuthorizationStatus`는 `undetermined` / `allowed` / `denied` 3종이며, 여기서는 **권한 요청을 하지 않고 표시만 한다**(요청은 Home/Map의 책임).

- **[결정 9] 초기화 완료 후 화면 반영은 `TabBarFeature`가 자식 액션을 가로채 리로드**
  - `SettingFeature`가 `resetCompleted` 액션을 방출하면, `TabBarFeature`가 `.path(.element(id: _, action: .setting(.resetCompleted)))`로 수신해 `.merge(.send(.bookmark(.onAppear)), .send(.plan(.onAppear)))`를 반환한다.
  - 기존 `.detail(.isBookmarkedResult)` → `.bookmark(.onAppear)` 선례와 동일한 구조라 새 개념이 없다.
  - `MapFeature`의 최근 검색어는 `searchFieldTapped` 시점에 `searchHistoryUseCase.fetch()`를 호출하므로 **별도 조치 불필요**(확인 완료).
  - `HomeFeature`는 북마크/일정 데이터를 사용하지 않으므로 **조치 불필요**(확인 완료).
  - `PlanDetail` 화면이 스택에 열려 있는 상태에서 초기화가 일어날 수는 없다(Setting이 스택 최상단). 스택 정리 로직은 불필요.

- **[결정 10] Setting 화면은 DesignSystem 신규 컴포넌트 없이 `Sub/`로만 구성한다**
  - AC 6("신규 컴포넌트를 임의로 만들지 않는다")에 따라, 설정 행/섹션은 `Presentation/Setting/Sub/`에 둔다. 현재 설정 화면 외에는 쓰이지 않으므로 `DesignSystem` 승격 조건(다화면 재사용)을 만족하지 않는다(`folder-structure.md` 배치 규칙 2번).
  - 행 내부는 `TabiCard` + `TabiLabel` + `TabiPressStyle` + SF Symbol 조합으로 구성한다. SwiftUI `List`/`Form`은 앱 전체 톤(카드 기반)과 어긋나 쓰지 않는다.
  - `SettingView.body`가 50줄을 넘으면 `swift-style.md` 6번 규칙대로 즉시 서브뷰로 분리한다.

---

## 구현 순서

### Phase 0. 미확정 사항 확인
- 위 "미확정 사항" 표의 5개 항목(개인정보처리방침 URL, 문의 이메일, 데이터 출처/라이선스 표기 방식, "기타"의 의미)을 사용자에게 확인한다.
- 확정 전이라도 Phase 1~4, 6~7은 병행 가능하다. 기타 섹션(Phase 5 일부)만 블로킹된다.

### Phase 1. Domain — 삭제 프로토콜 확장 + DataReset UseCase
- `BookmarkRepositoryProtocol` / `TravelPlanRepositoryProtocol`에 `removeAll()` 추가.
- `DataResetUseCaseProtocol`(`resetAll() async throws`) + `DataResetUseCase` 구현 — Repository 3종 주입, 결정 5의 부분 실패 정책 적용.
- `TestDataResetUseCase` 작성 (실패 시나리오 주입용 `var` 프로퍼티 공개, `test-style.md` 3번 규칙).
- `Dependency/Keys/DataResetUseCaseDependencyKey.swift`(testValue) + `DependencyValues.swift`에 `dataResetUseCase` 추가.

### Phase 2. Data — removeAll 구현
- `BookmarkRepository.removeAll()` — `BookmarkModel` 전량 삭제.
- `TravelPlanRepository.removeAll()` — `TravelPlanModel` / `TravelPlanDetailModel` / `TravelPlanDetailSpotModel` 전량 삭제.
- 두 구현 모두 실패 시 `AppLogger.core` 로깅 + `TabiError.persistenceFailed` 매핑(기존 메서드와 동일 형태).
- 최근 검색어는 신규 코드 없음 — UseCase가 `save([])` 호출.

### Phase 3. App — DI 조립
- `App/Sources/Dependency/DataResetUseCaseDependencyKey.swift`에 `@retroactive DependencyKey` liveValue 정의 (`BookmarkRepository()`, `TravelPlanRepository()`, `SearchHistoryRepository()` 주입).
- `tuist install && tuist generate` 후 빌드 — 신규 `.swift` 파일 반영 필수(미실행 시 stale 프로젝트 오탐).

### Phase 4. Resource — 문자열
- `Strings.Setting` 네임스페이스 신설: 화면 타이틀, 섹션 타이틀 3종, GPS 권한 상태 라벨 3종(허용/거부/미결정), 초기화 행 타이틀·설명, 확인 Alert 타이틀/메시지/삭제 버튼, 성공/실패 Alert 문구, 기타 항목 5종 타이틀.
- 기존 파일 컨벤션대로 **일본어 값 + 한국어 doc 주석(`///`)** 형식을 지킨다.
- 확인/취소 버튼은 `Strings.Plan.alertConfirm`, `Strings.Map.searchCancel` 재사용 가능 여부를 먼저 확인하고, 문맥상 부적절할 때만 신규 정의한다(`swift-style.md` 8번 규칙).

### Phase 5. Presentation — Setting 화면
- `SettingFeature` State: `locationStatus`, `isResetting`, `@Presents var alert`, (필요 시) `@Presents var infoState`.
- Action 선언 순서는 `swift-style.md` 5번(바인딩 → 생명주기 → 인터랙션 → 비동기 결과 → 하위)을 따른다: `onAppear` / `scenePhaseBecameActive` / `gpsRowTapped` / `resetRowTapped` / `etcRowTapped(SettingEtcItem)` / `resetResult(Bool)` / `resetCompleted` / `alert(PresentationAction<Alert>)`.
- 리듀서: `resetRowTapped` → Alert만 세팅(삭제 Effect 없음) → `alert(.presented(.resetConfirmed))` → `isResetting = true` + `resetAll()` Effect(`CancelID.reset`) → 성공 시 `resetCompleted` 방출 후 성공 Alert / 실패 시 실패 Alert.
- `SettingView`: `FestivalView` 패턴의 스택 화면 구성 + `ScrollView` 안에 섹션 3개. `scenePhase` 변화 감지 추가.
- `Sub/SettingSectionCard`, `Sub/SettingRow` 분리. 기타 섹션은 `SettingEtcItem` 배열 순회로 렌더링.
- (Phase 0 확정 후) `SettingInfoFeature` / `SettingInfoView` 추가 + sheet 연결.

### Phase 6. 진입점 연결
- `HomeFeature.Action`에 `settingButtonTapped` 추가(`.none` 반환, 용도 주석 필수 — 결정 1).
- `HomeView`의 `TabiNavigationBar`에 `trailing:`으로 `TabiCircleIconButton(systemName: "gearshape")` 추가.
- `StackPath`에 `case setting(SettingFeature)` 추가.
- `TabBarFeature`에 `.home(.settingButtonTapped)` → push 분기 추가.
- `TabBarView`의 `destination` switch에 `case .setting` 추가 (**enum 케이스 추가 시 컴파일 에러로 강제되므로 누락 불가**).

### Phase 7. 초기화 후 화면 반영
- `TabBarFeature`에 `.path(.element(id: _, action: .setting(.resetCompleted)))` 분기 추가 → `.merge(.send(.bookmark(.onAppear)), .send(.plan(.onAppear)))`.
- Map/Home은 조치 불필요(결정 9의 확인 결과)임을 실제 동작으로 재확인.

### Phase 8. 빌드 / 검증
- `tuist generate` 후 빌드 (시뮬레이터는 실제 설치된 기기명으로 확인 후 지정 — 레포 문서의 iPhone 16 Pro가 없을 수 있음).
- 수동 검증 시나리오:
  1. Home 우상단 아이콘 탭 → Setting push, 백 버튼/스와이프 pop 정상
  2. Setting 진입/이탈 후 Home 데이터(주변 관광지·환율)가 재조회되지 않고 유지되는지
  3. GPS 행 → 설정 앱 이동 → 권한 변경 후 복귀 시 표시 상태 갱신(결정 8)
  4. 초기화 → 취소 시 데이터 그대로 / 확인 시 삭제 후 Bookmark·Plan 탭 즉시 비어 있음
  5. Map 검색창 진입 시 최근 검색어 비어 있음
  6. 앱 재실행 시 온보딩이 다시 뜨지 않음(`onboardingCompleted` 유지)
  7. 초기화 직후 재차 초기화 실행 시 크래시/에러 없음(no-op)

---

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
  - [ ] HomeView 우측 상단 설정 아이콘 노출 및 탭 시 Setting 화면 진입
  - [ ] GPS 권한 설정 / 데이터 초기화 / 기타(5개 항목) 섹션 노출
  - [ ] GPS 권한 행 탭 시 iOS 설정 앱 이동
  - [ ] 초기화는 확인 Alert 이후에만 실행, 북마크·여행 일정·최근 검색어 삭제, `onboardingCompleted` 유지
  - [ ] 초기화 완료 후 Bookmark / Plan 화면 즉시 반영
  - [ ] 신규 DesignSystem 컴포넌트를 만들지 않고 기존 컴포넌트만 재사용
- [ ] 부분 실패 시 실패 알림 노출 + `AppLogger.core` / `AppLogger.view` 로깅(결정 5)
- [ ] iOS 설정 앱에서 권한 변경 후 복귀 시 Setting 화면 권한 표시가 갱신됨(결정 8)
- [ ] Setting push/pop이 다른 탭 상태에 영향을 주지 않음(불변 조건)
- [ ] Phase 0 미확정 항목이 모두 확정되었고, 미확정 항목은 노출되지 않음
- [ ] `DependencyInformation` 의존성 방향 위반 없음 (Domain은 Data 미참조, liveValue 조립은 App에서만)
- [ ] 문자열은 `Strings.Setting`에 정의, 재사용 가능한 기존 문자열은 재사용

# Tasks: setting

## 참조
- spec: `.claude/specs/features/setting/spec.md`
- plan: `.claude/specs/features/setting/plan.md`

## Task 목록

### Phase 0. 미확정 사항 확인

#### [x] Task 1 — 사용자 확인 (Phase 5 일부를 블로킹)
**파일**: 없음 (사용자 확인 전용, Phase 1~4·6~7은 병행 가능)
- 아래 5개 항목 확정 완료 (plan.md "미확정 사항" 표에 대한 사용자 답변)
  1. **데이터 출처** — 인앱 정적 텍스트 (한국관광공사 EngService2·네이버 지도/Geocoding·환율 소스 표기)
  2. **개인정보처리방침** — 행은 노출하되 탭 비활성화(TODO placeholder). URL이 없으므로 외부 링크 연결 없음. 향후 URL 확정 시 활성화
  3. **오픈소스 라이선스** — 인앱 정적 텍스트 (`Tuist/Package.swift` 기준 Kingfisher, NMapsMap, swift-composable-architecture 등 사용 라이브러리명 나열)
  4. **문의하기** — 행은 노출하되 탭 비활성화(TODO placeholder). 수신 이메일 주소가 없으므로 mailto 연결 없음. 향후 주소 확정 시 활성화
  5. **"기타"** — 앱 버전 정보 표시 (`CFBundleShortVersionString`/`CFBundleVersion`), 탭 동작 없음
- `SettingEtcItem`의 동작 종류는 "정적 텍스트 / 표시 전용(버전) / 비활성화(TODO)" 3종으로 확정 (외부 링크·mailto 종류는 이번 구현 범위에서 사용하지 않음, 향후 URL/이메일 확정 시 추가)

---

### Phase 1. Domain — 삭제 프로토콜 확장 + DataReset UseCase

#### [x] Task 2 — `BookmarkRepositoryProtocol.swift`
**파일**: `Projects/Domain/Sources/RepositoryProtocol/BookmarkRepositoryProtocol.swift`
- `func removeAll() async throws` 프로토콜 메서드 추가 (결정 4)

---

#### [x] Task 3 — `TravelPlanRepositoryProtocol.swift`
**파일**: `Projects/Domain/Sources/RepositoryProtocol/TravelPlanRepositoryProtocol.swift`
- `func removeAll() async throws` 프로토콜 메서드 추가 (결정 4)
- `TravelPlanDetailRepositoryProtocol`에는 `removeAll()`을 추가하지 않는다 — `TravelPlanRepository.removeAll()`이 3개 스키마(`TravelPlanModel`/`TravelPlanDetailModel`/`TravelPlanDetailSpotModel`)를 모두 지우므로 중복 책임 방지(결정 4)

---

#### [x] Task 4 — `DataResetUseCaseProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/DataReset/DataResetUseCaseProtocol.swift`
- `func resetAll() async throws` 프로토콜 선언 (plan "현재 상태 파악 > 신규")

---

#### [x] Task 5 — `DataResetUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/DataReset/DataResetUseCase.swift`
- `BookmarkRepositoryProtocol` / `TravelPlanRepositoryProtocol` / `SearchHistoryRepositoryProtocol` 3종을 `init`으로 주입받는 생성자 패턴 (결정 3: UseCase가 UseCase를 의존하지 않고 Repository를 직접 주입)
- `resetAll()` 구현: `bookmarkRepository.removeAll()`, `travelPlanRepository.removeAll()`, `searchHistoryRepository.save([])` 3개를 **개별 시도**하여 실패 항목을 수집하고, 첫 실패에서 즉시 throw하지 않는다 (결정 5 부분 실패 정책 — 전역 트랜잭션/롤백 불가능, 성공한 삭제는 되돌리지 않음)
- 전부 시도한 뒤 하나라도 실패하면 `TabiError.persistenceFailed(message:)`에 실패 항목을 담아 throw
- `onboardingCompleted`는 `OnboardingRepository`를 아예 주입하지 않으므로 접근 경로 자체가 없다 — 삭제 대상에 절대 포함하지 않는다 (결정 3)
- 실패 시 `AppLogger.core` 로깅 (결정 5)

---

#### [x] Task 6 — `TestDataResetUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/DataReset/TestDataResetUseCase.swift`
- `test-style.md` 3번 규칙에 따라 `Test` 접두사, `DataResetUseCaseProtocol` 채택
- 실패 시나리오 주입용 `var` 프로퍼티(예: 에러를 던질지 여부) 공개

---

#### [x] Task 7 — `DataResetUseCaseDependencyKey.swift` (신규)
**파일**: `Projects/Domain/Sources/Dependency/Keys/DataResetUseCaseDependencyKey.swift`
- `TestDependencyKey` 채택, `testValue`만 정의 (`TestDataResetUseCase()` 반환) — `liveValue`는 App 레이어에서 별도 정의(결정 3, CLAUDE.md TCA 의존성 등록 패턴)

---

#### [x] Task 8 — `DependencyValues.swift`
**파일**: `Projects/Domain/Sources/Dependency/DependencyValues.swift`
- 기존 프로퍼티들과 동일한 형태로 `dataResetUseCase: DataResetUseCaseProtocol` computed property 추가 (get/set으로 `DataResetUseCaseDependencyKey.self` 참조)

---

### Phase 2. Data — removeAll 구현

#### [x] Task 9 — `BookmarkRepository.swift`
**파일**: `Projects/Data/Sources/Repository/Bookmark/BookmarkRepository.swift`
- `BookmarkRepositoryProtocol` extension에 `removeAll()` 구현 — `BookmarkModel` 전량 fetch 후 delete, `try context.save()`
- 실패 시 기존 메서드와 동일한 패턴으로 `AppLogger.core.log(.error, ...)` + `TabiError.persistenceFailed(message:)` 매핑 (결정 4)

---

#### [x] Task 10 — `TravelPlanRepository.swift`
**파일**: `Projects/Data/Sources/Repository/TravelPlan/TravelPlanRepository.swift`
- `removeAll()` 구현 — `TravelPlanModel` / `TravelPlanDetailModel` / `TravelPlanDetailSpotModel` 3개 스키마 전량 삭제 (기존 `remove(planId:)`가 세 모델을 함께 지우는 구조를 그대로 차용, 결정 4)
- 실패 시 `AppLogger.core.log(.error, ...)` + `TabiError.persistenceFailed(message:)` 매핑

---

### Phase 3. App — DI 조립

#### [x] Task 11 — `DataResetUseCaseDependencyKey.swift` (신규)
**파일**: `Projects/App/Sources/Dependency/DataResetUseCaseDependencyKey.swift`
- 같은 타입에 `@retroactive DependencyKey` extension으로 `liveValue` 정의
- `DataResetUseCase(bookmarkRepository: BookmarkRepository(), travelPlanRepository: TravelPlanRepository(), searchHistoryRepository: SearchHistoryRepository())` 형태로 Data Repository 3종 조립 (CLAUDE.md TCA 의존성 등록 패턴, `BookmarkUseCaseDependencyKey.swift` 선례와 동일 구조)

---

#### [x] Task 12 — `tuist install && tuist generate`
**파일**: 없음 (빌드 설정 반영)
- Phase 1~3에서 추가한 신규 `.swift` 파일들을 프로젝트에 반영하기 위해 `tuist install && tuist generate` 실행 (CLAUDE.md IMPORTANT: 새 파일 추가 후 미실행 시 stale 프로젝트로 오탐 에러)
- `Tuist/ProjectDescriptionHelpers/Dependency/DependencyInformation.swift`는 수정 불필요(신규 모듈 간 의존 없음, plan "수정" 섹션 확인 완료)

---

### Phase 4. Resource — 문자열

#### [x] Task 13 — `Strings.swift`
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- `public enum Strings` 본문에 `public enum Setting {}` 네임스페이스 추가
- `public extension Strings.Setting`에 아래 문구 정의 (기존 파일 컨벤션대로 일본어 값 + 한국어 doc 주석(`///`))
  - 화면 타이틀
  - 섹션 타이틀 3종(GPS 권한 설정 / 데이터 초기화 / 기타)
  - GPS 권한 상태 라벨 3종(허용/거부/미결정 — `LocationAuthorizationStatus`의 `allowed`/`denied`/`undetermined`에 대응)
  - 데이터 초기화 행 타이틀·설명
  - 초기화 확인 Alert 타이틀/메시지/삭제 버튼 문구
  - 초기화 성공/실패 Alert 문구
  - 기타 항목 5종 타이틀(데이터 출처/개인정보처리방침/오픈소스 라이선스/문의하기/기타) — 개인정보처리방침·문의하기는 비활성화 상태이므로 "준비 중" 보조 라벨 포함
- 확인/취소 버튼은 신규 정의 전에 `Strings.Plan.alertConfirm`("確認"), `Strings.Map.searchCancel`("キャンセル") 재사용 가능 여부 먼저 확인 (`swift-style.md` 8번 규칙, plan 결정 없음 — 기존 재사용 원칙 그대로 적용)

---

### Phase 5. Presentation — Setting 화면

#### [x] Task 14 — `SettingFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/Setting/SettingFeature.swift`
- State: `locationStatus: LocationAuthorizationStatus`, `isResetting: Bool`, `@Presents var alert: AlertState<Action.Alert>?` (필요 시 `@Presents var infoState: SettingInfoFeature.State?`) — `swift-style.md` State 선언 순서 준수
- `StackPath.State`가 `Equatable`을 강제하므로 `State`/`Action` 모두 `Equatable` 채택 (결정 2)
- Action 선언 순서(`swift-style.md` 5번: 바인딩→생명주기→인터랙션→비동기 결과→하위): `onAppear` / `scenePhaseBecameActive` / `gpsRowTapped` / `resetRowTapped` / `etcRowTapped(SettingEtcItem)` / `resetResult(Bool)` / `resetCompleted` / `alert(PresentationAction<Alert>)`
- `Action.Alert` enum에 `case resetConfirmed` (결정 6 — `AddCustomPlaceFeature`의 `@Presents var alert` + `.ifLet(\.$alert, action: \.alert)` 구조 그대로 사용)
- 리듀서 로직
  - `onAppear` / `scenePhaseBecameActive`: `locationUseCase.checkAuthorization()` 결과를 `locationStatus`에 반영 (결정 8 — 동기 함수, `HomeFeature.onAppear`와 동일 패턴). 권한 요청은 하지 않고 표시만 함
  - `gpsRowTapped`: `HomeFeature.openSettingsButtonTapped`와 동일한 `UIApplication.openSettingsURLString` + `guard let` 조기 종료 패턴 적용 (URL 생성 실패 시 조용히 종료)
  - `resetRowTapped`: 삭제 Effect를 발행하지 않고 `state.alert`에 확인 Alert만 세팅 (취소 버튼 `role: .cancel`, 삭제 버튼 `role: .destructive`) — `resetConfirmed`를 받기 전에는 어떤 삭제 Effect도 발행하지 않는다(spec 불변 조건, 결정 6)
  - `alert(.presented(.resetConfirmed))`: `isResetting = true` + `dataResetUseCase.resetAll()` 호출 Effect(`CancelID.reset`으로 중복 실행 방지) → 성공 시 `resetResult(true)` → `resetCompleted` 방출 + 성공 Alert, 실패 시 `resetResult(false)` → 실패 Alert("일부 데이터가 남아 있을 수 있으니 다시 시도해 달라" 취지 문구, 결정 5)
  - `etcRowTapped(let item)`: `item`의 동작 종류(정적 텍스트/외부 링크/mailto/표시 전용)에 따라 분기 — 정적 텍스트 2종은 `infoState` 세팅(sheet), 외부 링크/mailto는 `openURL` 또는 `UIApplication.shared.open` 호출 후 URL 생성 실패 시 조용히 종료 (결정 7)
  - 로깅은 `AppLogger.view` (결정 5 — Feature 레이어)
- `body`에 `.ifLet(\.$alert, action: \.alert)` 마지막 위치 (`swift-style.md` 5번 body 선언 순서)
- `CancelID.reset` private enum 정의 (`FestivalFeature`/`AddCustomPlaceFeature`의 `CancelID` 패턴)

---

#### [x] Task 15 — `SettingView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Setting/SettingView.swift`
- `FestivalView` 패턴을 따르는 스택 화면 구성: `navigationTitle` + `navigationBarTitleDisplayMode(.inline)` + `ToolbarItem(.topBarLeading)` chevron.left 백 버튼 + `navigationBarBackButtonHidden(true)` + `interactivePopGestureEnabled(true)`
- `ScrollView` 안에 섹션 3개(GPS 권한 설정 / 데이터 초기화 / 기타) 배치, 각 섹션은 `Sub/SettingSectionCard`로 래핑
- `@Environment(\.scenePhase)`를 관찰해 `.active`로 전환될 때 `scenePhaseBecameActive` 액션 전송 (결정 8 — iOS 설정 앱에서 권한을 바꾸고 돌아와도 `onAppear`가 재호출되지 않는 함정 대응)
- `onAppear`에서 `store.send(.onAppear)`
- `body`가 50줄을 넘으면 즉시 서브뷰로 분리 (`swift-style.md` 6번, 결정 10)
- 신규 DesignSystem 컴포넌트 제작 금지 — `TabiCard`/`TabiLabel`/`TabiPressStyle`/`TabiColor`/`TabiRadius`/`TabiEmptyState` 및 SF Symbol 조합만 사용 (AC 6, 결정 10). `List`/`Form`은 카드 기반 톤과 어긋나 사용하지 않음

---

#### [x] Task 16 — `Sub/SettingSectionCard.swift` (신규)
**파일**: `Projects/Presentation/Sources/Setting/Sub/SettingSectionCard.swift`
- 섹션 타이틀 + `TabiCard` 래핑 컴포넌트 (plan "현재 상태 파악 > 신규")
- `Presentation/{FeatureName}/Sub/` 배치 규칙 준수 (`folder-structure.md`), 현재 Setting 화면 전용이므로 DesignSystem 승격 대상 아님(결정 10)

---

#### [x] Task 17 — `Sub/SettingRow.swift` (신규)
**파일**: `Projects/Presentation/Sources/Setting/Sub/SettingRow.swift`
- 아이콘 / 타이틀 / 보조값(예: GPS 권한 상태 텍스트) / chevron으로 구성된 행 컴포넌트
- `TabiCard` + `TabiLabel` + `TabiPressStyle` + SF Symbol 조합으로 구성 (결정 10)

---

#### [x] Task 18 — `Entity/SettingEtcItem.swift` (신규)
**파일**: `Projects/Presentation/Sources/Setting/Entity/SettingEtcItem.swift`
- Presentation 화면 전용 Entity — 기타 섹션 5개 항목(데이터 출처/개인정보처리방침/오픈소스 라이선스/문의하기/기타)을 배열 데이터로 표현
- 각 항목은 표시 타이틀 + 동작 종류 보유 — 화면 코드에 5개 분기를 하드코딩하지 않고 배열 순회로 렌더링 (결정 7)
  - 정적 텍스트(sheet 표시): 데이터 출처, 오픈소스 라이선스
  - 표시 전용(탭 동작 없음, 값 표시): 기타(앱 버전)
  - 비활성화(TODO placeholder, 탭 무시 + "준비 중" 보조 텍스트): 개인정보처리방침, 문의하기 (Task 1 확정 — URL/이메일 미확정으로 이번 범위에서 비활성화)
- URL/이메일 상수는 이번 범위에 없음(비활성화 상태) — 향후 확정 시 이 파일에 추가하고 종류를 외부 링크/mailto로 변경

---

#### [x] Task 19 — `SettingInfoFeature.swift` (신규, Phase 0 확정 후)
**파일**: `Projects/Presentation/Sources/SettingInfo/SettingInfoFeature.swift`
- 정적 텍스트 2종(데이터 출처, 오픈소스 라이선스) 공용 표시 화면의 Reducer — 표시할 텍스트 종류를 State 파라미터로 받는다 (결정 7 — `StackPath`에 케이스 2개를 추가하지 않고 화면 하나로 공용 처리)
- `Presentation/SettingInfo/` 폴더로 분리 (`Presentation/Setting/`이 아닌 별도 Feature — plan "현재 상태 파악 > 신규" 경로 그대로)

---

#### [x] Task 20 — `SettingInfoView.swift` (신규, Phase 0 확정 후)
**파일**: `Projects/Presentation/Sources/SettingInfo/SettingInfoView.swift`
- `SettingFeature`가 sheet로 띄우는 정적 텍스트 표시 뷰 (결정 7)
- 신규 DesignSystem 컴포넌트 없이 기존 컴포넌트로 구성 (AC 6)

---

### Phase 6. 진입점 연결

#### [x] Task 21 — `HomeFeature.swift`
**파일**: `Projects/Presentation/Sources/Home/HomeFeature.swift`
- `Action`에 `case settingButtonTapped` 추가 — 리듀서에서는 `.none` 반환, 실제 push는 `TabBarFeature`가 수행 (`festivalMoreButtonTapped` → `.festival` push와 동일 구조)
- 기존 `openSettingsButtonTapped`(iOS 설정 앱 이동)와 이름이 비슷해 혼동 위험이 있으므로, 두 액션 모두 유지하되 리듀서 case에 용도를 구분하는 주석을 남긴다 — 통합/개명은 스코프 밖 (결정 1)

---

#### [x] Task 22 — `HomeView.swift`
**파일**: `Projects/Presentation/Sources/Home/HomeView.swift`
- `TabiNavigationBar(subtitle:title:)` 호출에 `trailing:` 클로저 추가 — `TabiCircleIconButton(systemName: "gearshape")`로 설정 아이콘 노출, 탭 시 `store.send(.settingButtonTapped)`
- `TabiNavigationBar`는 이미 `trailing` 파라미터를 기본값 `EmptyView`로 제공하므로 DesignSystem 수정 불필요 (plan 확인 완료)

---

#### [x] Task 23 — `StackPath.swift`
**파일**: `Projects/Presentation/Sources/Navigation/StackPath.swift`
- `@Reducer public enum StackPath`에 `case setting(SettingFeature)` 추가 (결정 2 — sheet가 아닌 push, `festival`/`region` 선례와 동일)

---

#### [x] Task 24 — `TabBarFeature.swift`
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
- `case .home(.settingButtonTapped): state.path.append(.setting(SettingFeature.State())); return .none` 분기 추가 (`.home(.festivalMoreButtonTapped)` 선례와 동일 위치·구조)
- 기존 `case .home:` catch-all보다 먼저 위치해야 함 (Swift switch 순서 규칙)

---

#### [x] Task 25 — `TabBarView.swift`
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarView.swift`
- `destination` switch에 `case .setting(let store): SettingView(store: store)` 추가 — `StackPath`에 enum 케이스가 추가되면 컴파일 에러로 강제되므로 누락 불가

---

### Phase 7. 초기화 후 화면 반영

#### [x] Task 26 — `TabBarFeature.swift` (초기화 완료 리로드 분기)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
- `case .path(.element(id: _, action: .setting(.resetCompleted))): return .merge(.send(.bookmark(.onAppear)), .send(.plan(.onAppear)))` 분기 추가 — 기존 `.path(.element(id: _, action: .detail(.isBookmarkedResult))) → .bookmark(.onAppear)` 선례와 동일 구조 (결정 9)
- Map/Home은 조치 불필요 — `MapFeature`는 `searchFieldTapped` 시점에 `searchHistoryUseCase.fetch()`를 호출하고, `HomeFeature`는 북마크/일정 데이터를 사용하지 않음 (결정 9, plan 확인 완료). `PlanDetail` 화면이 열려 있는 상태에서 초기화가 발생할 수 없으므로(Setting이 스택 최상단) 스택 정리 로직 불필요

---

### Phase 8. 빌드 / 검증

#### [ ] Task 27 — 빌드 및 수동 검증
**파일**: 없음
- `tuist generate` 후 빌드 (시뮬레이터는 실제 설치된 기기명으로 확인 후 지정 — CLAUDE.md의 iPhone 16 Pro가 없을 수 있음, 실제 설치 기기 확인 필요)
- 수동 검증 시나리오
  1. Home 우상단 아이콘 탭 → Setting push, 백 버튼/스와이프 pop 정상
  2. Setting 진입/이탈 후 Home 데이터(주변 관광지·환율)가 재조회되지 않고 유지되는지 (불변 조건: 다른 탭 상태에 영향 없음)
  3. GPS 행 → 설정 앱 이동 → 권한 변경 후 복귀 시 표시 상태 갱신(결정 8)
  4. 초기화 → 취소 시 데이터 그대로 / 확인 시 삭제 후 Bookmark·Plan 탭 즉시 비어 있음
  5. Map 검색창 진입 시 최근 검색어 비어 있음
  6. 앱 재실행 시 온보딩이 다시 뜨지 않음(`onboardingCompleted` 유지)
  7. 초기화 직후 재차 초기화 실행 시 크래시/에러 없음(no-op)

---

## 체크리스트

### 품질 (DoD)
- [ ] 빌드 성공 (`tuist generate` 후 `xcodebuild build`)
- [ ] 테스트 통과 (테스트 타겟 미구성 상태 — 해당 없음, `.claude/CLAUDE.md` 참조)
- [ ] `DependencyInformation` 의존성 방향 위반 없음 (Domain은 Data 미참조, liveValue 조립은 App에서만)
- [ ] 문자열은 `Strings.Setting`에 정의, 재사용 가능한 기존 문자열(`Strings.Plan.alertConfirm`, `Strings.Map.searchCancel` 등)은 재사용
- [ ] 부분 실패 시 실패 알림 노출 + `AppLogger.core` / `AppLogger.view` 로깅(결정 5)
- [ ] 신규 DesignSystem 컴포넌트를 만들지 않고 기존 컴포넌트만 재사용(결정 10)

### 기능 (AC)
- [ ] HomeView 우측 상단에 설정 아이콘이 노출되고, 탭 시 Setting 화면으로 진입한다
- [ ] Setting 화면에 GPS 권한 설정, 데이터 초기화, 기타(데이터 출처/개인정보처리방침/오픈소스 라이선스/문의하기/기타) 섹션이 노출된다
- [ ] GPS 권한 설정 탭 시 iOS 설정 앱으로 이동한다
- [ ] 데이터 초기화는 확인 Alert 이후에만 실행되며, 북마크·여행 일정·최근 검색어가 삭제되고 온보딩 완료 상태는 유지된다
- [ ] 데이터 초기화 완료 후 관련 화면(Home/Bookmark/Plan 등)에 즉시 반영된다
- [ ] Setting 화면의 모든 UI는 기존 DesignSystem 컴포넌트를 재사용하며 신규 컴포넌트를 임의로 만들지 않는다
- [ ] Phase 0 미확정 항목이 모두 확정되었고, 확정되지 않은 항목은 화면에 노출되지 않는다

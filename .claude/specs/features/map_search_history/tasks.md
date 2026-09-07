# Tasks: map_search_history

## 참조
- spec: `.claude/specs/features/map_search_history/spec.md`
- plan: `.claude/specs/features/map_search_history/plan.md`

## Task 목록

### Phase 1. Domain — 엔티티 & 계약

#### [x] Task 1 — `SearchHistory.swift` (신규)
**파일**: `Projects/Domain/Sources/Entity/SearchHistory.swift`
- `Coordinate.swift`(같은 폴더) 스타일을 참고해 `public struct SearchHistory: Codable, Equatable, Sendable` 정의
- 프로퍼티: `public let keyword: String`, `public let searchedAt: Date`
- `public init(keyword: String, searchedAt: Date)` 명시적 정의 (다른 모듈에서 생성 가능하도록)

---

#### [x] Task 2 — `SearchHistoryRepositoryProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/RepositoryProtocol/SearchHistoryRepositoryProtocol.swift`
- `OnboardingRepositoryProtocol.swift` 패턴 참고
- `public protocol SearchHistoryRepositoryProtocol: Sendable` 정의
- 메서드: `func fetch() -> [SearchHistory]` (저장된 목록 전체 조회), `func save(_ histories: [SearchHistory])` (목록 통째 저장 — 정렬/cap 로직은 UseCase 책임이므로 Repository는 저장/조회만 담당)

---

#### [x] Task 3 — `SearchHistoryUseCaseProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/SearchHistory/SearchHistoryUseCaseProtocol.swift`
- `OnboardingUseCaseProtocol.swift` 패턴 참고
- `public protocol SearchHistoryUseCaseProtocol: Sendable` 정의
- 메서드: `func fetch() -> [SearchHistory]`, `func add(keyword: String)`

---

### Phase 2. Domain — UseCase 구현 & 의존성 등록(test)

#### [x] Task 4 — `SearchHistoryUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/SearchHistory/SearchHistoryUseCase.swift`
- `OnboardingUseCase.swift` 패턴 참고 (`public final class`, `private let repository: SearchHistoryRepositoryProtocol`, `public init(repository:)`)
- `fetch()`: `self.repository.fetch()`를 그대로 반환 (Repository가 이미 최신순 정렬된 상태로 저장하므로 재정렬 불필요)
- `add(keyword:)` 로직 (spec "동작 명세"/"무엇이 잘못될 수 있는가" 반영):
  1. `keyword`가 빈 문자열이면 조기 반환 (저장하지 않음)
  2. `self.repository.fetch()`로 기존 목록 조회
  3. 기존 목록에서 동일 `keyword`를 가진 항목 제거 (중복 방지)
  4. 새 `SearchHistory(keyword: keyword, searchedAt: Date())`를 맨 앞에 삽입
  5. 최대 개수(20개) 초과 시 뒤쪽(오래된 항목)부터 제거 — `private let maxHistoryCount = 20` 상수로 정의
  6. `self.repository.save(_:)` 호출로 영속화
- 불변 조건 준수: 저장 목록은 항상 20개 이하, 항상 최신순(내림차순)

---

#### [x] Task 5 — `TestSearchHistoryUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/SearchHistory/TestSearchHistoryUseCase.swift`
- `TestOnboardingUseCase.swift` 패턴(미주입 `reportIssue` 더블) 참고해 `SearchHistoryUseCaseProtocol` 채택
- `test-style.md` 3번 규칙(TCA 의존성 더블은 데이터 주입용 `public var` 프로퍼티 공개)에 따라 `public var histories: [SearchHistory] = []` 프로퍼티를 두어 `fetch()`가 이를 반환하도록 구성 (TestTouristSpotUseCase/TestLocationUseCase 등 기존 더블과 형태 통일)
- `add(keyword:)`는 사이드이펙트 확인용으로 `self.histories`에 반영하거나, `reportIssue("SearchHistoryUseCase.add 미주입")` 중 프로젝트의 기존 다수 패턴(데이터 주입형)에 맞춰 구현 — `public final class`, `@unchecked Sendable`, `public init() {}` 형태

---

#### [x] Task 6 — `SearchHistoryUseCaseDependencyKey.swift` (신규, Domain)
**파일**: `Projects/Domain/Sources/Dependency/Keys/SearchHistoryUseCaseDependencyKey.swift`
- `OnboardingUseCaseDependencyKey.swift`(Domain) 패턴 그대로 따름
- `public enum SearchHistoryUseCaseDependencyKey: TestDependencyKey, Sendable`
- `public static var testValue: SearchHistoryUseCaseProtocol { TestSearchHistoryUseCase() }`
- `liveValue`는 정의하지 않음 (App 레이어에서 별도 extension으로 추가)

---

#### [x] Task 7 — `DependencyValues.swift` 수정
**파일**: `Projects/Domain/Sources/Dependency/DependencyValues.swift`
- 기존 `onboardingUseCase`/`locationUseCase` 등과 동일한 형태로 `searchHistoryUseCase` 프로퍼티 추가
```swift
public var searchHistoryUseCase: SearchHistoryUseCaseProtocol {
    get { self[SearchHistoryUseCaseDependencyKey.self] }
    set { self[SearchHistoryUseCaseDependencyKey.self] = newValue }
}
```

---

### Phase 3. Data — 영속화

#### [x] Task 8 — `TabiUserDefaultKey.swift` 수정
**파일**: `Projects/Data/Sources/UserDefault/TabiUserDefaultKey.swift`
- 기존 `case onboardingCompleted` 옆에 `case recentSearchHistory` 추가

---

#### [x] Task 9 — `SearchHistoryRepository.swift` (신규)
**파일**: `Projects/Data/Sources/Repository/SearchHistory/SearchHistoryRepository.swift`
- `OnboardingRepository.swift` 패턴 참고 (`public final class`, `private let userDefault: TabiUserDefaultProtocol`, `public init(userDefault: TabiUserDefaultProtocol = TabiUserDefault.shared)`)
- `Domain` import, `SearchHistoryRepositoryProtocol` 채택 (별도 `extension`으로 분리 — swift-style.md 3번 규칙)
- `fetch() -> [SearchHistory]`:
  - `self.userDefault.get(forKey: .recentSearchHistory)`로 `Data?` 조회
  - `JSONDecoder().decode([SearchHistory].self, from:)`를 `try?`로 디코딩, 실패 시 `[]` 반환 (spec "무엇이 잘못될 수 있는가": 디코딩 실패 → 빈 배열 폴백, 크래시 없이 무시)
- `save(_ histories: [SearchHistory])`:
  - `JSONEncoder().encode(histories)`를 `try?`로 인코딩
  - 성공 시 `self.userDefault.set(data, forKey: .recentSearchHistory)` 호출

---

### Phase 4. App — liveValue 조립

#### [x] Task 10 — `SearchHistoryUseCaseDependencyKey.swift` (신규, App)
**파일**: `Projects/App/Sources/Dependency/SearchHistoryUseCaseDependencyKey.swift`
- `OnboardingUseCaseDependencyKey.swift`(App) 패턴 그대로 따름
- `import Domain`, `import Data`, `import ComposableArchitecture`
```swift
extension SearchHistoryUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: SearchHistoryUseCaseProtocol {
        SearchHistoryUseCase(repository: SearchHistoryRepository())
    }
}
```

---

### Phase 5. Presentation — Feature

#### [x] Task 11 — `MapFeature.swift` 수정
**파일**: `Projects/Presentation/Sources/Map/MapFeature.swift`
- `@Dependency(\.locationUseCase)`/`@Dependency(\.touristSpotUseCase)` 옆에 `@Dependency(\.searchHistoryUseCase) var searchHistoryUseCase` 추가
- `State`에 `var recentSearches: [SearchHistory] = []` 추가 (swift-style.md State 선언 순서 1번: 공개 프로퍼티, 초기값과 함께)
- `Action`에 셀 탭 액션 추가: `case recentSearchTapped(SearchHistory)` — swift-style.md Action 선언 순서(사용자 인터랙션 그룹)에 맞춰 `searchResultTapped` 근처에 배치
- `body`의 `Reduce` 내부 수정:
  - `.searchFieldTapped` 케이스: `state.mode = .typing` 설정 직후 `state.recentSearches = self.searchHistoryUseCase.fetch()` 동기 호출 추가 (LocationUseCase.checkAuthorization()과 동일하게 reducer 내 동기 호출 — UserDefaults 접근이라 별도 `.run` effect 불필요, plan.md "기술적 결정사항" 참고)
  - `.searchSubmitted` 케이스: `guard state.searchQuery.isEmpty == false else { return .none }` 통과 직후(또는 성공 경로에서) `self.searchHistoryUseCase.add(keyword: state.searchQuery)` 호출 추가
  - `.recentSearchTapped(let history)` 케이스 신규 추가: `state.searchQuery = history.keyword` 설정 후 `.searchSubmitted` 액션 재사용을 위해 `return .send(.searchSubmitted)` (재검색 흐름 재사용, plan.md "최근 검색어 Cell 탭 → 즉시 재검색")
- `private extension MapFeature`(Method 섹션)의 `resetSearchState(_:)`에 `state.recentSearches = []` 추가 여부 검토 (검색 취소 시 목록 유지할지 초기화할지 — 유지가 자연스러우므로 추가하지 않음, 단 팀 컨벤션상 필요 시 조정)

---

### Phase 6. Presentation — View & 포맷터

#### [x] Task 12 — `Date+.swift` 수정
**파일**: `Projects/Presentation/Sources/Extension/Date+.swift`
- 기존 `homeDateTitle`/`exchangeRateUpdatedAtTitle` computed var 패턴을 따라 신규 var 추가 (예: `recentSearchDateTitle`)
- 로직 (spec "Cell UI 명세" > 날짜 포맷):
  - `Calendar.current.component(.year, from: self)`와 `Calendar.current.component(.year, from: Date())` 비교
  - 올해면 `DateFormatter.dateFormat = "MM.dd (HH:mm)"` → 예: `07.27 (14:30)`
  - 올해가 아니면 `DateFormatter.dateFormat = "yyyy.MM.dd (HH:mm)"` → 예: `2025.12.03 (09:15)`
  - `Resource` import는 기존 파일에 이미 존재하므로 유지, `Locale`은 기존 코드 스타일(`ja_JP`) 여부 확인 후 날짜 숫자 포맷이므로 로케일 영향 적음 — 필요 시 `Locale(identifier: "ja_JP")` 유지

---

#### [x] Task 13 — `MapRecentSearchListView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Map/Sub/MapRecentSearchListView.swift`
- `MapRecentSearchPlaceholderView.swift`(같은 `Sub/` 폴더)와 `MapView.searchResultRow(_:)`(MapView.swift:292-332), `searchResultList()`(MapView.swift:268-290)의 레이아웃 톤 참고
- `import SwiftUI`, `import DesignSystem`, `import Domain`(`SearchHistory` 참조), `import Resource`
- `struct MapRecentSearchListView: View` — internal 접근 제어 (MapView와 같은 모듈 내 사용)
- 프로퍼티: `var histories: [SearchHistory]`, 셀 탭 콜백 `var onTapped: (SearchHistory) -> Void` (또는 TCA 액션 직접 전달 대신 클로저로 분리해 View 재사용성 확보 — swift-style.md 6번 규칙: 반복 UI 패턴은 별도 View로 추출)
- `body`: `ScrollView` + `LazyVStack(spacing: 0)` + `ForEach(histories)` (id는 `keyword` 또는 `\.self`가 `Equatable`이므로 가능, 단 동일 keyword 중복 없음이 불변조건이라 `\.keyword` 사용 가능) — 항목 사이 `Divider().padding(.horizontal, 16)` (`searchResultList()` 패턴 그대로)
- Cell 레이아웃 (spec "Cell UI 명세" 반영):
  - 썸네일 없음 (KFImage 미사용)
  - `HStack`으로 제목(좌측)/날짜(우측) 한 줄 배치
  - 타이틀: `TabiLabel(title: history.keyword, style: .bodyLBold, color: .tabiTextPrimary, lineLimit: 1)`
  - 날짜: `TabiLabel(title: history.searchedAt.recentSearchDateTitle, style: .captionM, color: .tabiTextTertiary)` (Task 12에서 추가한 computed var 사용)
  - `Button { self.onTapped(history) } label: { ... }.buttonStyle(TabiPressStyle())`로 `searchResultRow`와 동일하게 탭 가능하게 구성, `.padding(16)`, `.contentShape(Rectangle())`

---

#### [x] Task 14 — `MapView.swift` 수정
**파일**: `Projects/Presentation/Sources/Map/MapView.swift`
- `recentSearchPlaceholder()`(MapView.swift:143-150)를 `self.store.recentSearches` 유무로 분기하도록 수정:
  - `recentSearches`가 비어있지 않으면 `MapRecentSearchListView(histories: self.store.recentSearches) { history in self.store.send(.recentSearchTapped(history)) }` 렌더링
  - 비어있으면 기존 `MapRecentSearchPlaceholderView(keyboardHeight: self.keyboardHeight)` 유지
  - 배경/클립셰이프/패딩(`.background(TabiColor.tabiBackground)`, `.clipShape(.rect(cornerRadius: .tabiRadiusXl))`, `.padding(.top, self.topBarHeight)`, `.ignoresSafeArea(.container, edges: .bottom)`)은 두 분기 공통으로 감싸는 컨테이너에 적용해 기존 톤 유지
- 리스트 케이스에서도 키보드 높이 대응 필요 여부 확인 (`MapRecentSearchPlaceholderView`는 `keyboardHeight`만큼 하단 패딩 적용 중 — 리스트 뷰도 스크롤 가능하므로 필수는 아니나 시트 겹침 방지 위해 `.safeAreaInset` 또는 하단 패딩 검토)

---

### Phase 7. 빌드 검증

#### [x] Task 15 — Tuist 재생성 및 빌드 확인
**파일**: 없음 (프로젝트 설정/빌드 명령)
- `Projects/Domain/Sources/Entity/SearchHistory.swift`, `SearchHistoryRepositoryProtocol.swift`, `SearchHistoryUseCase*.swift`, `Projects/Data/Sources/Repository/SearchHistory/SearchHistoryRepository.swift`, `Projects/App/Sources/Dependency/SearchHistoryUseCaseDependencyKey.swift`, `Projects/Presentation/Sources/Map/Sub/MapRecentSearchListView.swift` 등 신규 `.swift` 파일이 다수 추가되므로 `tuist install && tuist generate` 실행 (CLAUDE.md IMPORTANT: 새 파일 추가 후 generate 없이 빌드하면 stale 프로젝트 오탐 에러)
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`로 컴파일 확인 (설치된 시뮬레이터가 다르면 실제 설치본에 맞춰 destination 조정 — 메모리 기록상 iPhone 17 사용 가능성 있음, 실제 환경 확인 후 진행)
- 빌드 실패 시 에러 로그를 직접 추적해 원인 수정 (CLAUDE.md: 에러 로그가 있으면 추론하지 말고 데이터에서 직접 추적)

---

## 체크리스트

### 품질 (DoD)
- [ ] 빌드 성공 (`tuist generate` 후 `xcodebuild build`)
- [ ] 테스트 통과 (현재 테스트 타겟 미구성 — 해당 없음, 추가 시 `.claude/rules/test-style.md` 규칙 준수)
- [ ] `Domain`이 `Data`를 참조하지 않음 (실제 Repository 조립은 `App`의 `liveValue`에서만 수행)
- [ ] swift-style.md 준수: State/Action 선언 순서, `private extension` Method 분리, `self` 명시적 사용, `guard let`/`if let` 구분

### 기능 (AC)
- [ ] typing 모드 진입 시 저장된 최근 검색어가 최신순으로 노출된다
- [ ] 검색어를 검색 실행하면 해당 검색어가 최근 검색어 목록 맨 앞에 저장된다
- [ ] 이미 존재하는 검색어를 다시 검색하면 중복 없이 맨 앞으로 이동한다
- [ ] 저장된 검색어가 20개를 초과하면 가장 오래된 항목이 삭제된다
- [ ] 앱을 재실행해도 저장된 검색 기록이 유지된다
- [ ] 최근 검색어 Cell은 썸네일 없이 한 줄로 표시된다
- [ ] 최근 검색어 Cell의 타이틀은 검색 결과 Cell 타이틀보다 크고 강한 스타일로, 날짜는 약한 스타일로 표시된다
- [ ] 검색일이 올해면 `mm.dd (hh:mm)`, 올해가 아니면 `yyyy.mm.dd (hh:mm)` 형식으로 날짜가 표시된다
- [ ] 저장된 Data 디코딩 실패 시 크래시 없이 빈 배열로 폴백된다
- [ ] 빈 문자열 검색어는 저장되지 않는다

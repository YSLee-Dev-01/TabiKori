# Plan: map_search_history (지도 최근 검색어)

## 참조 Spec
- @specs/features/map_search_history/spec.md

## 참조 Skill
- 신규 화면(Feature) 생성이 아닌 기존 `Map` Feature 확장이므로 create-feature 스킬 대상 아님
- 신규 UseCase/Repository 추가는 기존 `Onboarding` 체인(UserDefault 기반 동기 저장) 패턴을 그대로 따른다

## 현재 상태 파악

### 신규
- `Projects/Domain/Sources/Entity/SearchHistory.swift` — 검색어(String) + 검색일(Date) `Codable`/`Equatable`/`Sendable` 도메인 모델
- `Projects/Domain/Sources/RepositoryProtocol/SearchHistoryRepositoryProtocol.swift` — 목록 조회/저장 프로토콜
- `Projects/Domain/Sources/UseCase/SearchHistory/SearchHistoryUseCase.swift` — 중복 제거·최신순 정렬·20개 cap 비즈니스 로직 담당
- `Projects/Domain/Sources/UseCase/SearchHistory/SearchHistoryUseCaseProtocol.swift`
- `Projects/Domain/Sources/UseCase/SearchHistory/TestSearchHistoryUseCase.swift` — `testValue`용 더블(`reportIssue` 미주입 경고 패턴)
- `Projects/Domain/Sources/Dependency/Keys/SearchHistoryUseCaseDependencyKey.swift` — `TestDependencyKey`, `testValue`만 정의
- `Projects/Data/Sources/Repository/SearchHistory/SearchHistoryRepository.swift` — `TabiUserDefault`에 JSON 인코딩/디코딩(디코딩 실패 시 빈 배열 폴백)
- `Projects/App/Sources/Dependency/SearchHistoryUseCaseDependencyKey.swift` — `@retroactive DependencyKey`, `liveValue`(Repository 주입)
- `Projects/Presentation/Sources/Map/Sub/MapRecentSearchListView.swift` — 최근 검색어 리스트 + Cell(썸네일 없는 한 줄 레이아웃)

### 재사용
- `TabiUserDefault.set<T>/get<T>` — `Data`(JSON 인코딩 결과)를 그대로 저장/조회 (제네릭 API 변경 없음)
- `Onboarding` 4계층 조립 패턴(Repository → UseCase → testValue(Domain) / liveValue(App) → DependencyValues 프로퍼티)
- `MapView.searchResultRow`의 레이아웃 톤 / `TabiLabel` / `TabiPressStyle` / `Divider` 구성
- `TypographyStyle.bodyLBold`(18pt, bold), `.captionM`/`.captionS`, `TabiColor.tabiTextPrimary` / `.tabiTextTertiary` — 신규 토큰 불필요
- `MapRecentSearchPlaceholderView` — 빈 상태(플레이스홀더) 전용으로 존치
- `Date+.swift`의 computed var 포맷터 패턴

### 수정
- `Projects/Data/Sources/UserDefault/TabiUserDefaultKey.swift` — `recentSearchHistory` case 추가
- `Projects/Domain/Sources/Dependency/DependencyValues.swift` — `searchHistoryUseCase` 프로퍼티 추가
- `Projects/Presentation/Sources/Map/MapFeature.swift` — `@Dependency(\.searchHistoryUseCase)`, `recentSearches` 상태, 조회/저장/셀 탭 액션 추가
- `Projects/Presentation/Sources/Map/MapView.swift` — `recentSearchPlaceholder()`를 목록 유무 분기로 확장(있으면 리스트, 없으면 기존 placeholder)
- `Projects/Presentation/Sources/Extension/Date+.swift` — 최근 검색 날짜 포맷 computed var 추가

### 삭제
- 없음

## 기술적 결정사항
- **저장소로 UserDefaults 사용 (CoreData 미사용)**: spec 제약에 따름. 건수가 적고(≤20) 관계/쿼리 요구가 없어 기존 `TabiUserDefault` 제네릭 API로 충분. 대안(CoreData)은 오버엔지니어링.
- **JSON 인코딩/디코딩 위치는 Repository**: `TabiUserDefault.set<T>/get<T>`는 그대로 두고 Repository에서 `[SearchHistory]`↔`Data` 변환. `TabiUserDefault`는 범용 유틸이므로 도메인 모델 인코딩 책임을 넣지 않음. 디코딩 실패 시 `try?`로 빈 배열 폴백(크래시 방지, spec "무엇이 잘못될 수 있는가").
- **중복 제거·20개 cap·최신순 프리펜드 로직은 UseCase**: Repository는 목록 조회/저장만 하는 얇은 영속화 계층으로 유지하고, 불변 조건(20개 이하 / 내림차순) 보장은 UseCase가 담당 → 규칙이 한 곳에 모여 추후 테스트(TestStore) 용이.
- **모듈 의존성 준수**: `SearchHistory` 엔티티/프로토콜은 `Domain`에 위치. `Presentation → Domain`(엔티티 참조), 실제 `Repository` 조립은 `App`의 `liveValue`에서만 수행하여 `Domain → Data` 역참조 금지 원칙 유지.
- **UseCase 호출은 reducer 내 동기 호출**: `LocationUseCase.checkAuthorization()`이 이미 reducer 본문에서 동기 호출되는 선례를 따름. `fetch()`/`add()`는 UserDefaults 동기 접근이라 별도 `.run` effect 없이 `searchFieldTapped`/`searchSubmitted`에서 직접 호출·상태 대입. (TestStore 도입 시 재검토)
- **빈 문자열 가드 이중화**: `searchSubmitted`가 이미 `searchQuery.isEmpty == false` 가드를 가지므로 저장 진입점이 보호됨. UseCase `add`에도 방어적 empty 가드를 둬 저장 규칙을 자기완결적으로 만든다.
- **최근 검색어 Cell 탭 → 즉시 재검색**: 셀 탭 시 `searchQuery`를 해당 키워드로 채우고 검색 실행 흐름(`searchSubmitted`)을 재사용하여 "재검색을 빠르게" 목적 달성. (한 줄 레이아웃, 썸네일 없음)
- **날짜 포맷은 Date+.swift computed var**: `homeDateTitle`/`exchangeRateUpdatedAtTitle` 패턴을 따라 신규 var 추가. 올해 여부는 `Calendar.current`의 저장 검색일 `year`와 `Date()` `year` 비교로 `mm.dd (HH:mm)` / `yyyy.mm.dd (HH:mm)` 분기.

## 구현 순서

### Phase 1. Domain — 엔티티 & 계약
- `SearchHistory` 엔티티 정의 (`keyword: String`, `searchedAt: Date`, `Codable`/`Equatable`/`Sendable`)
- `SearchHistoryRepositoryProtocol` 정의 (목록 조회 / 목록 저장)
- `SearchHistoryUseCaseProtocol` 정의 (`fetch()` 조회 / `add(keyword:)` 추가)

### Phase 2. Domain — UseCase 구현 & 의존성 등록(test)
- `SearchHistoryUseCase` — `add`에서 빈 문자열 가드 → 동일 키워드 제거 → 맨 앞 삽입 → 20개 초과분 후단 제거 → 저장, `fetch`는 저장 목록 반환
- `TestSearchHistoryUseCase` — 미주입 `reportIssue` 더블
- `SearchHistoryUseCaseDependencyKey`(testValue) + `DependencyValues.searchHistoryUseCase` 프로퍼티 추가

### Phase 3. Data — 영속화
- `TabiUserDefaultKey`에 `recentSearchHistory` case 추가
- `SearchHistoryRepository` — `[SearchHistory]` ↔ `Data` JSON 인코딩/디코딩, 디코딩 실패 시 빈 배열 폴백, `TabiUserDefault.shared` 기본 주입(Onboarding과 동일 시그니처)

### Phase 4. App — liveValue 조립
- `SearchHistoryUseCaseDependencyKey`에 `@retroactive DependencyKey` liveValue 추가 (`SearchHistoryUseCase(repository: SearchHistoryRepository())`)

### Phase 5. Presentation — Feature
- `MapFeature`에 `@Dependency(\.searchHistoryUseCase)` 및 상태 `recentSearches: [SearchHistory] = []` 추가
- `searchFieldTapped`(및 result→typing 재진입 경로)에서 `recentSearches` 로드
- `searchSubmitted` 성공 경로에서 `add(keyword:)` 저장
- 셀 탭 액션(예: `recentSearchTapped(SearchHistory)`) 추가 → `searchQuery` 채우고 검색 실행 재사용
- Action 선언 순서/`self` 참조/`private extension` Method 분리 등 swift-style 규칙 준수

### Phase 6. Presentation — View & 포맷터
- `Date+.swift`에 최근 검색 날짜 포맷 computed var 추가 (올해/비올해 분기)
- `MapRecentSearchListView` 신규 작성: 썸네일 없는 한 줄 Cell(타이틀 `.bodyLBold`/`.tabiTextPrimary`, 날짜 `.captionM`|`.captionS`/`.tabiTextTertiary`, `Divider` 구분), 리스트 스크롤
- `MapView.recentSearchPlaceholder()`를 `recentSearches` 유무로 분기 — 있으면 리스트, 없으면 기존 `MapRecentSearchPlaceholderView`

### Phase 7. 빌드 검증
- 신규 `.swift` 파일 추가로 인해 `tuist install && tuist generate` 후 빌드 (stale 프로젝트 오탐 방지)
- `xcodebuild build`로 컴파일 확인 (destination은 설치된 시뮬레이터에 맞춰 사용)

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
  - [ ] typing 모드 진입 시 저장된 최근 검색어가 최신순 노출
  - [ ] 검색 실행 시 해당 검색어가 목록 맨 앞에 저장
  - [ ] 동일 검색어 재검색 시 중복 없이 맨 앞으로 이동
  - [ ] 20개 초과 시 가장 오래된 항목 삭제
  - [ ] 앱 재실행 후에도 기록 유지 (UserDefaults 영속)
  - [ ] Cell은 썸네일 없이 한 줄로 표시
  - [ ] 타이틀은 검색 결과 Cell보다 크고 강하게(`.bodyLBold`), 날짜는 약하게(`.captionM`/`.captionS`)
  - [ ] 올해면 `mm.dd (HH:mm)`, 비올해면 `yyyy.mm.dd (HH:mm)` 포맷
- [ ] 디코딩 실패 시 크래시 없이 빈 배열 폴백
- [ ] 빈 문자열 검색어는 저장되지 않음
- [ ] 모듈 의존성 규칙 준수 (Domain은 Data 미참조, 조립은 App에서만)
- [ ] `tuist generate` 후 빌드 성공

# Plan: bookmark

## 참조 Spec
- @specs/features/bookmark/spec.md

## 참조 Skill
신규 화면 생성 시
- @skills/create-feature/SKILL.md

## 현재 상태 파악

### 신규
- **Domain**
  - `Entity/Bookmark.swift` — 북마크 도메인 모델 (TouristSpot + savedAt)
  - `RepositoryProtocol/BookmarkRepositoryProtocol.swift`
  - `UseCase/Bookmark/BookmarkUseCase.swift`, `BookmarkUseCaseProtocol.swift`, `TestBookmarkUseCase.swift`
  - `Dependency/Keys/BookmarkUseCaseDependencyKey.swift` (testValue)
  - `Dependency/DependencyValues.swift`에 `bookmarkUseCase` 프로퍼티 추가 (기존 파일 수정)
- **Data**
  - `SwiftData/` 스택: `BookmarkModelContainer`(`ModelContainer` 생성/보관), `BookmarkModel.swift`(`@Model` 클래스)
  - `Repository/Bookmark/BookmarkRepository.swift` — SwiftData(`ModelContext`) 기반 구현체
  - (선택) `Extension/BookmarkModel+.swift` — `@Model` ↔ Domain 매핑
- **App**
  - `Dependency/BookmarkUseCaseDependencyKey.swift` (liveValue)
- **Presentation**
  - `Bookmark/BookmarkFeature.swift`, `BookmarkView.swift`
  - `Bookmark/Sub/` — 카테고리 필터 바, 빈 상태 뷰 등 서브 뷰
- **DesignSystem**
  - `Card/TabiSpotRow.swift` — Map 검색 결과 셀 레이아웃을 primitive 파라미터로 승격한 공용 셀 (기술 결정 1 참조)
- **Resource**
  - `Strings.swift`에 북마크 문자열 추가 (`保存済み`, `N件のスポットを保存中` 포맷) — 기존 파일 수정

### 재사용
- `TabiChip`(isSelected 지원) — 카테고리 필터 칩
- `TabiTag`, `TabiLabel`, `TabiColor`, `TabiPressStyle`, `TabiRadius` — 셀/필터 구성
- `TabiNavigationBar` — 상단 타이틀
- `CategoryType`(Domain), `CategoryType+`(Presentation, color/label/icon/allItems), `TouristSpot`(Domain)
- `Strings.Common.contentTypeAll`("すべて") — 필터 "전체" 칩 라벨 (기존 존재, 신규 문자열 불필요)
- SearchHistory 전체 스택(UseCase/Protocol/TestDouble/DependencyKey live·test/Repository/DependencyValues) — 신규 Bookmark 스택의 참조 패턴
- Map의 인라인 빈 상태 뷰(`searchResultEmptyState()`) 패턴 — Bookmark 빈 상태 뷰 작성 시 동일 구조 참조 (DesignSystem 전용 Empty 컴포넌트는 없음)

### 수정
- `Presentation/Tabbar/TabBarFeature.swift` — placeholder `BookmarkState` 제거, `BookmarkFeature.State` 스코프 연결, 관련 액션 처리
- `Presentation/Tabbar/TabBarView.swift` — `Text(AppTab.bookmark.title)` placeholder를 `BookmarkView`로 교체
- `Presentation/Detail/DetailFeature.swift` — `saveButtonTapped`의 메모리 토글을 `BookmarkUseCase` 연동으로 교체, `onAppear`에서 저장 여부 조회, 결과 수신 액션 추가
- `Presentation/Map/MapView.swift` — `searchResultRow`를 `TabiSpotRow` 위임으로 최소 변경 (기술 결정 1의 대안 채택 시)
- `Domain/Error/TabiError.swift` — 영속성 실패 케이스 추가 (기술 결정 4 참조)

### 삭제
- `TabBarFeature.State.BookmarkState`(placeholder 빈 구조체) — 실제 `BookmarkFeature.State`로 대체되므로 제거

---

## 기술적 결정사항

- **[결정 1] Map 검색 결과 셀 재사용 방식 → DesignSystem `TabiSpotRow`로 승격(primitive 파라미터)**
  - 이유: `searchResultRow`는 현재 `MapView`의 private 뷰. 중복 복제는 swift-style 8번(재사용) 위반. DesignSystem은 Domain을 import할 수 없으므로(`DependencyInformation`: designSystem → core, resource만) `TouristSpot`/`CategoryType`을 직접 받을 수 없음. 따라서 `thumbnailURL: URL?`, `japaneseTitle`, `koreanTitle`, `tagTitle`, `tagColor: TabiColor`, `distance: String?`, `onTap` 등 primitive 파라미터를 받는 컴포넌트로 정의하고, 각 Feature가 자신의 엔티티를 매핑해 주입.
  - 대안: (a) Bookmark 화면에 셀을 복제 → 중복. (b) Presentation 내부 공용 뷰로 추출(Domain 타입 그대로 사용 가능) → DesignSystem 승격 규칙(폴더 구조 1번)과 어긋남. primitive 승격이 규칙과 레이어 제약을 모두 만족.
  - **확정**: `MapView.searchResultRow`도 `TabiSpotRow` 위임으로 함께 교체한다(사용자 확인 완료). spec 제약("MapView는 이번 스코프에서 수정하지 않음")은 필터 칩 맥락으로 한정 해석하고, 셀 부분은 내부 구현을 `TabiSpotRow` 호출로 대체하는 작은 diff만 반영 — 동작/레이아웃은 기존과 동일하게 유지하며 진짜 중복 제거를 달성한다.

- **[결정 2] SwiftData 최초 도입 → `Data` 모듈에 `ModelContainer` 스택 신설 (CoreData 대신 채택)**
  - 이유: 배포 타겟 iOS 26.0(레거시 OS 지원 불필요) + Swift 6 strict concurrency 채택 상태. CoreData의 `NSManagedObjectContext`/`NSManagedObject`는 Sendable이 아니라 strict concurrency 하에서 `perform{}`/`@unchecked Sendable` 우회가 필요한 반면, SwiftData의 `@Model`/`ModelContainer`는 최신 동시성 모델에 맞춰 설계됨. 프로젝트에 CoreData 선례가 전혀 없어 완전 신규 도입이라는 점도 동일하므로, 레거시 호환 이점이 없는 CoreData를 택할 이유가 없음.
  - `.xcdatamodeld`/번들 리소스가 불필요 — `@Model` 클래스는 순수 Swift 코드로 스키마를 정의하므로 `Data/Project.swift`의 `hasResource` 변경이 필요 없음(CoreData 대비 Tuist 설정 부담 감소).
  - 스택은 `BookmarkModelContainer`(싱글턴, `ModelContainer` 로드)로 캡슐화. `SearchHistoryRepository`가 `TabiUserDefault.shared`를 주입받는 패턴과 동일하게 `BookmarkRepository(modelContext:)`로 주입 가능하게 설계. `ModelContext`는 메인 액터 바운드가 기본이므로, Repository의 async 메서드 내부에서 컨텍스트 접근을 일관되게 캡슐화.
  - `BookmarkModel`(`@Model`) 속성(안): `contentId: String`(유니크 키), `title: String`, `thumbnailURLString: String?`, `contentTypeRaw: String`, `latitude: Double`, `longitude: Double`, `savedAt: Date`(정렬용). 향후 플래닝 기능 연동 시 `@Relationship`으로 Plan과의 관계 추가 가능.

- **[결정 3] 중복 저장 방지(불변 조건) → 저장 전 `contentId` 조회 후 없을 때만 insert**
  - 이유: spec 불변 조건 "특정 관광지 최대 1개 레코드". SwiftData의 `#Unique` 매크로(iOS 18+) 대신 Repository 레벨에서 `#Predicate`로 fetch-by-id 후 분기(선례인 SearchHistory의 `removeAll { }` 중복 제거와 동일한 애플리케이션 레벨 보장 방식으로 통일).

- **[결정 4] SwiftData 에러 처리 → `TabiError`에 영속성 실패 케이스 추가 + `AppLogger.core` 로깅**
  - 이유: spec "SwiftData 저장/조회 실패 → 에러 타입 정의 필요". 기존 `TabiError`를 확장(예: `.persistenceFailed`)해 도메인 계층에서 일관된 에러 표현. 스와이프 삭제 시 이미 삭제된 레코드는 에러 없이 no-op(불변 조건 대응).

- **[결정 5] UseCase/Repository 인터페이스 → 비동기 throwing**
  - `fetch() async throws -> [Bookmark]`, `add(_ spot: TouristSpot) async throws`, `remove(contentId: String) async throws`, `isBookmarked(contentId: String) async throws -> Bool`.
  - 이유: SwiftData read/write 사이드이펙트이며 TCA `.run` effect에서 호출. SearchHistory(UserDefault, 동기)와 달리 실패 가능성이 있어 throwing으로 명시.

- **[결정 6] 스와이프 삭제 UI → `List` + `.swipeActions(edge: .trailing)`**
  - 이유: spec 제약 "List+.swipeActions 또는 커스텀 제스처 여부 plan에서 결정". 프로젝트에 선례는 없으나 표준 iOS 삭제 제스처(trailing swipe)가 접근성/일관성에서 유리. `List` 사용 시 `.listStyle(.plain)` + separator/배경 숨김으로 기존 셀 디자인 유지. `TabiSpotRow`를 `List` row로 배치.

- **[결정 7] 필터/총 개수 상태 → 필터는 뷰 상태, 총 개수는 원본 배열 기준**
  - `State`에 전체 `bookmarks: [Bookmark]`와 `selectedCategory: CategoryType?` 보유. 표시 목록은 `selectedCategory`로 필터링한 computed. 저장 개수 타이틀("N件")은 필터와 무관하게 `bookmarks.count` 사용(불변 조건: "필터 선택 여부와 무관하게 전체 개수 반영").

---

## 구현 순서

### Phase 1. Resource / Domain 모델
- `Strings.swift`에 북마크 문자열 추가: 화면 타이틀("保存済み"), 저장 개수 포맷("N件のスポットを保存中" — 개수 삽입용 함수/포맷). "すべて"는 기존 `Strings.Common.contentTypeAll` 재사용.
- `Domain/Entity/Bookmark.swift` 정의 (TouristSpot + savedAt).
- `Domain/Error/TabiError.swift`에 영속성 실패 케이스 추가.

### Phase 2. Domain UseCase 계층
- `BookmarkRepositoryProtocol` 정의 (fetch/add/remove/isBookmarked, async throws).
- `BookmarkUseCaseProtocol` + `BookmarkUseCase` 구현 (Repository 위임, 중복 방지 로직 포함).
- `TestBookmarkUseCase` 테스트 더블 (var 프로퍼티로 데이터 주입).
- `Dependency/Keys/BookmarkUseCaseDependencyKey.swift`(testValue) + `DependencyValues.swift`에 프로퍼티 추가.

### Phase 3. Data SwiftData 스택
- `BookmarkModel.swift`(`@Model` 클래스) 정의.
- `BookmarkModelContainer`(`ModelContainer`) 작성.
- `BookmarkRepository` 구현 (`@Model` ↔ Domain 매핑, `ModelContext` 조회/저장/삭제, 에러 로깅 `AppLogger.core`).
- `tuist generate`로 신규 파일 반영 (리소스 변경 없음).

### Phase 4. App DI 조립
- `App/Dependency/BookmarkUseCaseDependencyKey.swift`에 liveValue 정의 (`BookmarkUseCase(repository: BookmarkRepository(...))`).

### Phase 5. DesignSystem 공용 셀
- `TabiSpotRow` 작성 (primitive 파라미터, `TabiTag`/`TabiLabel`/`TabiPressStyle`/Kingfisher 썸네일 재사용).
- `MapView.searchResultRow`를 `TabiSpotRow` 위임으로 리팩터링 (동작/레이아웃 동일 유지, 내부 구현만 교체).

### Phase 6. Presentation BookmarkFeature
- `BookmarkFeature` State/Action/body 작성: onAppear 목록 로드, 카테고리 필터 선택, 스와이프 삭제, 결과 수신 액션.
- `BookmarkView` 구성: 타이틀 → 카테고리 필터(`TabiChip`) → 총 개수 타이틀 → `List`+`TabiSpotRow`+`.swipeActions`. 빈 상태 뷰(Map 패턴 참조)를 `Sub/`에 분리.
- `TabBarFeature`/`TabBarView`에 `BookmarkFeature` 스코프 연결, placeholder 제거.

### Phase 7. Detail 영속화 연동
- `DetailFeature`에 `@Dependency(\.bookmarkUseCase)` 추가.
- `onAppear`에서 `isBookmarked` 조회 → `isSaved` 세팅 (결과 수신 액션 신설).
- `saveButtonTapped`을 add/remove effect로 교체, 성공 시 `isSaved` 갱신. 실패 시 `AppLogger.view`/`core` 로깅.

### Phase 8. 빌드/검증
- `tuist generate` 후 빌드. 저장 → 앱 재실행 → 상태 유지, 필터/개수/스와이프 삭제 동작 확인.

---

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
  - [ ] BookmarkView 진입 시 타이틀/필터/총 개수/Cell 리스트가 순서대로 표시
  - [ ] 카테고리 필터 칩 탭 시 필터링 + 선택 칩 강조(`TabiChip.isSelected`)
  - [ ] 셀 스와이프 삭제 시 SwiftData·목록 동시 제거
  - [ ] 하트 버튼 저장/삭제가 SwiftData에 영속화, 재실행 후 상태 유지
  - [ ] 저장 개수 타이틀이 필터와 무관하게 전체 북마크 개수와 일치
- [ ] SwiftData 저장/조회 실패 시 `TabiError` + `AppLogger` 처리
- [ ] 빈 목록 시 빈 상태 UI 표시
- [ ] `DependencyInformation` 의존성 방향 위반 없음 (DesignSystem은 Domain 미참조)

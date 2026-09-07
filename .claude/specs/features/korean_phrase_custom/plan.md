# Plan: korean_phrase_custom

## 참조 Spec
- `@.claude/specs/features/korean_phrase_custom/spec.md`

## 참조 Skill
- `@.claude/skills/feature/SKILL.md` (spec → plan → tasks → 구현 흐름)
- 신규 화면(`AddKoreanPhrase`) 생성 시 기존 `AddTravelPlan` / `AddCustomPlace` 폴더 구성을 레퍼런스로 삼는다

## 현재 상태 파악

### 신규
| 경로 | 내용 |
|------|------|
| `Projects/Domain/Sources/RepositoryProtocol/CustomKoreanPhraseRepositoryProtocol.swift` | 로컬 커스텀 문구 CRUD 프로토콜 (`fetch` / `add` / `delete`) |
| `Projects/Data/Sources/SwiftData/CustomKoreanPhraseModel.swift` | `@Model final class`, `@Attribute(.unique) var id: String` |
| `Projects/Data/Sources/SwiftData/KoreanPhraseModelContainer.swift` | `ModelConfiguration("KoreanPhrase", schema:)` 싱글턴 + in-memory 폴백 |
| `Projects/Data/Sources/Extension/CustomKoreanPhraseModel+.swift` | `toDomain` / `convenience init(phrase:)` 매핑 |
| `Projects/Data/Sources/Repository/CustomKoreanPhrase/CustomKoreanPhraseRepository.swift` | SwiftData 구현체 |
| `Projects/Presentation/Sources/AddKoreanPhrase/AddKoreanPhraseFeature.swift` | 입력 폼 Reducer |
| `Projects/Presentation/Sources/AddKoreanPhrase/AddKoreanPhraseView.swift` | 입력 폼 시트 View |

### 재사용
- `TabiTextField`, `TabiButton`, `TabiLabel`, `TabiCard`, `TabiNavigationBar`, `TabiCircleIconButton`, `TabiEmptyState`, `TabiRetryableEmptyState`, `TabiPressStyle`
- `TranslateSearchTaskModifier`(`translateSearchTask(pendingQuery:onResult:onFailure:)`) — 일본어→한국어 방향이 이미 정확히 일치하므로 신규 Modifier 없이 그대로 재사용
- `ToastCenter`(`@Dependency(\.toastCenter)`) — 번역 실패/입력 안내
- `AlertState` + `Strings.Plan.alertConfirm` — 저장 실패 (AddCustomPlace가 이미 교차 사용 중인 선례)
- `FirebaseListCache` 기반 `KoreanPhraseRepository.fetchPhrases()` — 그대로 유지
- `KoreanPhraseDetailFeature` / `KoreanPhraseDetailView` — 변경 없음 (커스텀 문구도 동일 Entity라 자동 동작)
- `Sub/KoreanPhraseRow.swift` — 변경 없음 (구분은 Section 헤더가 담당)

### 수정
| 경로 | 내용 |
|------|------|
| `Projects/Domain/Sources/Entity/KoreanPhrase.swift` | `isCustom: Bool` 추가, init 마지막 파라미터에 `= false` 기본값 |
| `Projects/Domain/Sources/UseCase/KoreanPhrase/KoreanPhraseUseCaseProtocol.swift` | 커스텀 문구 3개 메서드 추가 |
| `Projects/Domain/Sources/UseCase/KoreanPhrase/KoreanPhraseUseCase.swift` | `CustomKoreanPhraseRepositoryProtocol` 추가 주입, 신규 메서드 구현 |
| `Projects/Domain/Sources/UseCase/KoreanPhrase/TestKoreanPhraseUseCase.swift` | 인메모리 커스텀 문구 배열 + 신규 메서드 |
| `Projects/App/Sources/Dependency/KoreanPhraseUseCaseDependencyKey.swift` | `liveValue`에 `CustomKoreanPhraseRepository()` 조립 |
| `Projects/Resource/Sources/Strings/Strings.swift` | `Strings.KoreanPhrase` 확장에 신규 문자열 |
| `Projects/Presentation/Sources/KoreanPhraseList/KoreanPhraseListFeature.swift` | 커스텀 문구 상태/로드/추가/삭제, `@Presents addPhraseState` |
| `Projects/Presentation/Sources/KoreanPhraseList/KoreanPhraseListView.swift` | "+" 툴바 버튼, 2-Section List, 스와이프 삭제, `.sheet` |

### 삭제
- 없음

### 변경 불필요 (확인 완료)
- `Tuist/ProjectDescriptionHelpers/Dependency/DependencyInformation.swift` — 신규 모듈 간 의존 없음. `Translation`은 시스템 프레임워크로 `TranslateSearchTaskModifier`가 이미 Presentation에서 import 중, `SwiftData`도 Data에서 이미 사용 중
- `Projects/Presentation/Sources/Navigation/StackPath.swift` — `case koreanPhraseList` 그대로
- deployment target iOS 26.0 → Translation 프레임워크 사용 제약 없음

---

## 기술적 결정사항

### 1. 로컬 CRUD는 `KoreanPhraseRepository`에 통합하지 않고 `CustomKoreanPhraseRepository`로 분리한다
- **이유**: `KoreanPhraseRepository`는 `FirebaseListCache<KoreanPhrase>`를 내부에 들고 있는 순수 원격 소스다. 여기에 `ModelContainer`를 얹으면 한 클래스가 두 개의 저장소·두 개의 실패 모드(`NetworkError` vs `TabiError.persistenceFailed`)·두 개의 캐시 수명주기를 갖게 된다.
- **선례**: 이 코드베이스는 이미 "Firebase 마스터 목록 = `ToolBarItemRepository` / 로컬 인스턴스 = `ToolBarPlanItemRepository`"로 같은 도메인을 두 Repository로 쪼개는 패턴을 쓰고 있다. `ShoppingItem` / `ShoppingPlanItem`도 동일.
- **조립 지점**: UseCase가 두 Repository를 합성한다. `DataResetUseCase`가 이미 3개 Repository를 주입받는 선례가 있어 새 패턴이 아니다. Domain은 프로토콜만 알고, 구현체 조립은 `App/Sources/Dependency/`에서만 수행 → Domain→Data 역방향 의존 없음.
- **대안(기각)**: 프로토콜에 `addPhrase`/`deletePhrase`를 추가하고 `KoreanPhraseRepository`가 둘 다 구현 — 파일 수는 줄지만 Firebase 캐시 무효화와 SwiftData 트랜잭션이 한 타입에 섞여 이후 캐시 정책 변경 시 로컬 데이터까지 영향 범위에 들어간다.

### 2. `KoreanPhraseUseCase.fetchPhrases()`는 병합하지 않고, 원격/로컬을 별도 메서드로 노출한다
- UseCase 시그니처: `fetchPhrases()`(원격, 기존 유지) / `fetchCustomPhrases()` / `addCustomPhrase(korean:japanese:pronunciation:)` / `deleteCustomPhrase(id:)`
- **이유**: UseCase에서 합쳐 하나의 배열로 반환하면 "Firebase 실패 시 커스텀 문구만이라도 보여줄지"를 표현할 수 없다(전부 성공 또는 전부 실패). 두 소스를 분리해 반환해야 Feature가 부분 실패를 상태로 모델링할 수 있다.
- **부분 실패 정책 결정**: 원격 실패는 **커스텀 문구 표시를 막지 않는다**.
  - 원격 실패 + 커스텀 0건 → 기존과 동일하게 전체 화면 `TabiRetryableEmptyState`
  - 원격 실패 + 커스텀 1건 이상 → 커스텀 Section은 정상 표시하고, Firebase Section 자리에만 `TabiRetryableEmptyState`를 카드로 렌더
  - 커스텀(SwiftData) 조회 실패는 별도 화면 전환 없이 `AppLogger.view` 로깅 후 빈 배열로 폴백 (로컬 조회 실패는 사실상 컨테이너 생성 실패뿐이고, 이미 in-memory 폴백이 있음)

### 3. 병합/정렬: "내가 추가한 문구" Section을 항상 최상단에 두는 2-Section List
- `State`에 `customPhrases: [KoreanPhrase]`와 기존 `phrases: [KoreanPhrase]`를 **분리 보관**하고, View에서 두 개의 `Section`으로 렌더한다.
- 커스텀 Section 정렬: `createdAt` 내림차순(최신 추가가 맨 위). 방금 추가한 문구가 스크롤 없이 바로 보이는 것이 이 기능의 핵심 피드백이기 때문.
- Firebase Section 정렬: 기존 `order` 오름차순 유지(Repository가 이미 정렬해서 반환).
- **`order` 의미 충돌 해소**: 커스텀 문구의 `order`는 Firebase의 "관리자 지정 노출 순서"와 의미가 다르므로, 병합 키로 쓰지 않는다. `CustomKoreanPhraseRepository`가 `createdAt` 정렬 후 배열 인덱스를 `order`로 채워 반환한다(Entity의 `order`는 non-optional이라 값은 필요하되, 정렬 판단에는 쓰이지 않음).
- **헤더 노출 규칙**: 커스텀 문구가 0건이면 Section 헤더를 둘 다 숨겨 기존 화면과 완전히 동일하게 보이게 한다. 1건 이상일 때만 두 헤더를 노출한다.
- **대안(기각)**: 단일 배열에 커스텀을 prepend하고 `isCustom`으로 스와이프만 분기 — View는 단순해지지만 사용자가 "삭제되는 줄/안 되는 줄"을 예측할 수 없어 Acceptance Criteria의 "Firebase 문구는 삭제 옵션이 보이지 않는다"가 우연처럼 보인다.

### 4. `FirebaseListCache`는 건드리지 않고, 커스텀 목록만 로컬에서 갱신한다
- 커스텀 추가/삭제는 Firebase 캐시와 무관하므로 `fetchPhrases()`를 재호출하지 않는다.
- 추가 성공 시 자식 Feature가 저장된 `KoreanPhrase`를 액션 payload로 돌려주고, 부모가 `state.customPhrases`에 **prepend**한다 → 재조회 없이 즉시 반영(불필요한 SwiftData 왕복 제거).
- 삭제는 낙관적 갱신: 먼저 `state.customPhrases`에서 제거하고 이펙트로 삭제 요청, 실패 시 `AppLogger.view` 로깅만 하고 목록은 되돌리지 않는다(`ShoppingPlanListFeature.deleteItemsEffect`와 동일한 정책·주석 근거).

### 5. 커스텀 문구 `id`는 `"custom_" + UUID().uuidString`
- Firebase 키는 `"hello"`, `"thanks"` 같은 관리자 지정 슬러그라 prefix + UUID와 절대 충돌하지 않는다.
- `AddCustomPlaceFeature`가 커스텀 `TouristSpot`에 쓰는 `"custom_" + UUID().uuidString`과 동일한 규칙 → 코드베이스 일관성.
- `id` / `createdAt` 생성 위치는 **UseCase**(`KoreanPhraseUseCase.addCustomPhrase`). 이 프로젝트는 `@Dependency(\.uuid)` / `@Dependency(\.date)`를 어디에서도 쓰지 않으므로(grep 확인 완료) 관례대로 `UUID()` / `Date()`를 직접 사용한다. Presentation은 문자열 3개만 넘긴다.

### 6. SwiftData 컨테이너는 `KoreanPhraseModelContainer`를 새로 만든다
- **이유**: `TravelPlanModelContainer`의 `Schema`에 `CustomKoreanPhraseModel`을 끼워 넣으면 여행 플랜/준비물/쇼핑 데이터가 들어있는 기존 스토어의 스키마 버전이 바뀌어, 이 기능과 무관한 사용자 데이터에 마이그레이션 리스크가 생긴다.
- `BookmarkModelContainer`가 이미 "도메인 영역 하나당 컨테이너 하나"(`ModelConfiguration("Bookmark", ...)`)를 쓰는 선례.
- `isFallbackToMemory` 플래그는 `BookmarkModelContainer`처럼 노출하되, 이번 스펙에서는 소비하지 않는다(불필요한 UX 분기 추가 방지).

### 7. 번역 방향은 일본어→한국어이므로 `TranslateSearchTaskModifier`를 그대로 재사용하고 신규 Modifier는 만들지 않는다
- 이 기능의 목표는 "일본어를 적으면 한국어로 표시"이므로 번역 방향이 `source: .japanese, target: .korean`이다. `TranslateSearchTaskModifier`(Map/PlanDetailAddSpot/AddCustomPlace가 이미 사용 중)가 정확히 이 방향의 공용 `.translationTask` 연결부(`translateSearchTask(pendingQuery:onResult:onFailure:)`)를 이미 제공한다.
- **초기 설계(한국어→일본어)에서는 별도 Modifier가 필요했으나, 방향을 뒤집으면서 그 필요성 자체가 사라졌다** — 새 파일을 만드는 대신 기존 공용 Modifier를 재사용하는 것이 `swift-style.md` 9번(재사용 우선)과 CLAUDE.md(우회책 대신 근본 원인) 원칙에 맞다. `AddKoreanPhraseTranslateTaskModifier.swift`는 삭제한다.
- `TranslateSearchTaskModifier`는 `Map`/`PlanDetailAddSpot`/`AddCustomPlace` 3개 화면이 이미 의존 중인 파일이므로 시그니처는 건드리지 않는다(CLAUDE.md "현재 태스크와 무관한 코드는 절대 수정하지 마라") — `AddKoreanPhraseView`는 호출부만 추가한다.
- `TranslationSession.Configuration`의 `invalidate()` 처리("번역 버튼 2번째 탭부터 무반응" 방지)는 `TranslateSearchTaskModifier`에 이미 구현되어 있으므로 별도로 신경 쓸 필요 없다.

### 8. 유효성 검사 UX: 저장 버튼 비활성 (얼럿 아님)
- `State.isSaveEnabled` = `trimmedKorean.isEmpty == false && trimmedJapanese.isEmpty == false && isSaving == false`
- `AddCustomPlaceFeature.isConfirmEnabled` / `AddTravelPlanFeature`와 동일한 패턴. Reducer의 `saveButtonTapped`에도 동일 guard를 둬 이중 방어.
- 발음(`pronunciation`)은 선택 → trim 후 빈 문자열이면 `nil`로 저장(`ShoppingPlanListFeature.newItemSubmitted`의 `note` 처리와 동일).

### 9. 에러 채널 분리
- **번역 실패 / 일본어 미입력 상태의 번역 시도** → `toastCenter.show(ToastItem(..., type: .error / .info))` + `AppLogger.view.log(.error, ...)` (`TranslateSearchFeature`와 동일 채널)
- **SwiftData 저장 실패** → `AlertState` + 폼 유지(입력값 보존, `state.isSaving = false`만 되돌림). Repository 계층에서 `AppLogger.core.log(.error, ...)` + `TabiError.persistenceFailed` throw, Feature 계층에서 `AppLogger.view.log(.error, ...)`. `ToolBarPlanItemRepository`의 로깅/throw 규약을 그대로 따른다.

### 10. 범위 밖으로 명시하는 것
- **편집(수정)** — spec에서 이미 범위 외.
- **`DataResetUseCase`에 커스텀 문구 초기화 추가** — 현재 `resetAll()`은 bookmark/travelPlan/searchHistory만 다루고 spec에 요구사항이 없다. 다만 "설정 > 데이터 초기화"를 해도 커스텀 문구가 남는 비일관이 생기므로 **후속 과제로 기록**한다.
- **Analytics 이벤트 추가**(`koreanPhraseCustomAdded` 등) — Domain `AnalyticsEvent` + App `AnalyticsCenterDependencyKey` 양쪽을 건드려야 하고 spec 요구가 없어 제외. 기존 `koreanPhraseViewed`는 커스텀 문구에도 그대로 적용된다(`phraseRowTapped`에서 이미 로깅).

---

## 구현 순서

> 각 Phase는 앞 Phase에 컴파일 의존한다. Phase 2 완료 후 `tuist install && tuist generate` 1회 실행(신규 `.swift` 파일 추가 반영). Phase 5 완료 후 다시 `tuist generate`.

### Phase 1. Domain
1. `Entity/KoreanPhrase.swift`
   - `public let isCustom: Bool` 추가
   - `init`의 **마지막** 파라미터로 `isCustom: Bool = false` — 기본값을 줘야 `KoreanPhraseRepository`, `KoreanPhraseListView` Preview, `KoreanPhraseDetailView` Preview의 기존 호출부가 무변경으로 컴파일된다
   - `Equatable / Sendable / Identifiable` 유지
2. `RepositoryProtocol/CustomKoreanPhraseRepositoryProtocol.swift` 신규
   - `Sendable` 채택, `fetchCustomPhrases()` / `addCustomPhrase(_:)` / `deleteCustomPhrase(id:)` 3개 async throws 메서드
   - `add`는 `KoreanPhrase`를 통째로 받는다(id/createdAt 생성 책임은 UseCase). 저장 시각은 파라미터로 함께 받는다
3. `UseCase/KoreanPhrase/KoreanPhraseUseCaseProtocol.swift`
   - `fetchCustomPhrases()` / `addCustomPhrase(korean:japanese:pronunciation:) -> KoreanPhrase` / `deleteCustomPhrase(id:)` 추가
4. `UseCase/KoreanPhrase/KoreanPhraseUseCase.swift`
   - `init(repository:customRepository:)`로 확장. 기존 `repository` 프로퍼티명 유지, `customRepository` 추가
   - `addCustomPhrase`: id 생성(`"custom_" + UUID().uuidString`), `isCustom: true`, `order`는 임시로 0, `createdAt = Date()` → Repository에 위임 후 저장된 Entity 반환
   - `MARK: - Properties / Init / Method` 순서 준수
5. `UseCase/KoreanPhrase/TestKoreanPhraseUseCase.swift`
   - `public var customPhrases: [KoreanPhrase] = []` 추가, 신규 3개 메서드를 인메모리 배열 조작으로 구현(`@unchecked Sendable` 유지)
   - Preview에서 커스텀 Section을 눈으로 확인할 수 있게 됨

### Phase 2. Data
1. `SwiftData/CustomKoreanPhraseModel.swift` 신규
   - `@Model final class`(internal). `@Attribute(.unique) var id: String`, `korean`, `japanese`, `pronunciation: String?`, `createdAt: Date`
   - `order`는 저장하지 않는다 — 정렬 기준이 `createdAt`이므로 중복 진실 원천을 만들지 않는다
2. `SwiftData/KoreanPhraseModelContainer.swift` 신규
   - `BookmarkModelContainer`를 그대로 본뜬 `public final class ... Sendable` + `static let shared` + in-memory 폴백 + `AppLogger.core` 로깅
3. `Extension/CustomKoreanPhraseModel+.swift` 신규
   - `var toDomain: KoreanPhrase`(`isCustom: true`, `order`는 호출측에서 덮어씀) / `convenience init(phrase:createdAt:)`
   - `ToolBarPlanItemModel+.swift`와 동일 구성
4. `Repository/CustomKoreanPhrase/CustomKoreanPhraseRepository.swift` 신규
   - `public init(modelContainer: ModelContainer = KoreanPhraseModelContainer.shared.modelContainer)`
   - 본문은 프로퍼티/init만, 프로토콜 채택은 `// MARK: - CustomKoreanPhraseRepositoryProtocol` extension으로 분리
   - `fetch`: `FetchDescriptor(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])` → `enumerated()`로 `order` 부여
   - `add`: `context.insert` → `save()`
   - `delete`: `#Predicate { $0.id == id }` + `fetchLimit = 1` → 없으면 `AppLogger.core` 경고 후 return
   - 모든 catch에서 `AppLogger.core.log(.error, ...)` + `TabiError.persistenceFailed(message:)` throw
5. `tuist install && tuist generate`

### Phase 3. App (DI 조립)
1. `App/Sources/Dependency/KoreanPhraseUseCaseDependencyKey.swift`
   - `liveValue`를 `KoreanPhraseUseCase(repository: KoreanPhraseRepository(), customRepository: CustomKoreanPhraseRepository())`로 변경
2. `Domain/Sources/Dependency/Keys/KoreanPhraseUseCaseDependencyKey.swift` / `DependencyValues.swift` — **변경 없음**(키·프로퍼티 이미 존재, `testValue`는 `TestKoreanPhraseUseCase()` 그대로)

### Phase 4. Resource
`Resource/Sources/Strings/Strings.swift`의 `public extension Strings.KoreanPhrase`에 일본어 문자열 추가(기존 항목과 동일하게 각 항목 위에 한국어 주석):
- 목록: 커스텀 Section 헤더 / Firebase Section 헤더 / "+" 버튼 accessibilityLabel
- 입력 폼: 화면 타이틀, 한국어 라벨·플레이스홀더, 일본어 라벨·플레이스홀더, 발음 라벨·플레이스홀더(선택 표기), 번역 버튼 타이틀, 저장 버튼 타이틀
- 안내/에러: 번역 실패 토스트, 일본어 미입력 상태 번역 시도 안내 토스트, 저장 실패 얼럿 타이틀/메시지
- 삭제 스와이프 라벨은 기존 `Strings.Common.delete` 재사용, 얼럿 확인 버튼은 기존 `Strings.Plan.alertConfirm` 재사용

### Phase 5. Presentation
1. `AddKoreanPhrase/AddKoreanPhraseFeature.swift` 신규
   - State(선언 순서: 공개 → fileprivate → `@Presents`): `korean` / `japanese` / `pronunciation` / `pendingTranslationJapanese: String?` / `isTranslating` / `isSaving`, `@Presents var alert: AlertState<Action.Alert>?`
   - 계산 프로퍼티: `trimmedKorean` / `trimmedJapanese` / `trimmedPronunciation` / `isSaveEnabled`
   - Action(선언 순서: 바인딩 → 생명주기 → 인터랙션 → 비동기 결과 → 하위): `binding` / `closeTapped` / `translateButtonTapped` / `saveButtonTapped` / `translationResultReceived(String)` / `translationFailed` / `saveResult(KoreanPhrase?)` / `alert(PresentationAction<Alert>)`
   - body: `BindingReducer()` → `Reduce` → `.ifLet(\.$alert, action: \.alert)`
   - `translateButtonTapped`: `trimmedJapanese` 비었으면 안내 토스트 이펙트만 반환, 아니면 `pendingTranslationJapanese` 세팅 + `isTranslating = true`
   - `translationResultReceived`: `pendingTranslationJapanese = nil`, `isTranslating = false`, 결과가 비어있지 않으면 `korean`에 대입(사용자가 이후 수정 가능)
   - `translationFailed`: 상태 정리 + 실패 토스트 이펙트
   - `saveResult(nil)`: `isSaving = false` + 저장 실패 얼럿(입력값 보존)
   - `saveResult(.some)`: 부모가 소비하므로 여기선 `.none`
   - 이펙트는 하단 `private extension`에 `saveEffect(...)` 등으로 분리, `CancelID`는 `private enum`
2. `AddKoreanPhrase/AddKoreanPhraseView.swift` 신규
   - `ScrollView` + `safeAreaBar(edge: .top) { TabiNavigationBar(...) { TabiCircleIconButton("xmark") } }` + `safeAreaBar(edge: .bottom) { TabiButton(저장, style: .primary, isExpanded: true, isLoading:) }` — `AddTravelPlanView` 레이아웃 그대로
   - 필드 순서는 일본어 → 한국어 → 발음(사용자가 입력하는 순서와 일치)
   - 일본어 필드: `TabiTextField` + 우측 `TabiButton(번역, style: .ghost, isLoading: store.isTranslating)`를 `HStack`으로
   - 한국어 필드 / 발음 필드: `TabiTextField`
   - `.presentationDetents([.medium, .large])` + `.presentationDragIndicator(.visible)`
   - `.alert($store.scope(state: \.alert, action: \.alert))`
   - `.translateSearchTask(pendingQuery: store.pendingTranslationJapanese, onResult:, onFailure:)` — 기존 공용 Modifier 재사용(결정사항 7)
   - `body`가 50줄을 넘으면 필드 묶음을 `private extension`의 `@ViewBuilder` 함수로 분리(파일 내 분리로 충분, `Sub/` 불필요)
   - `#Preview` — `TestKoreanPhraseUseCase` 주입
3. `KoreanPhraseList/KoreanPhraseListFeature.swift` 수정
   - State에 `customPhrases: [KoreanPhrase] = []`, `@Presents var addPhraseState: AddKoreanPhraseFeature.State?` 추가 (`phraseDetailState` 위에 선언 — `@Presents`끼리 묶음)
   - Action 추가: `addButtonTapped` / `customPhraseDeleted(id: String)` / `customPhrasesResult([KoreanPhrase])` / `addPhrase(PresentationAction<AddKoreanPhraseFeature.Action>)`
   - `onAppear` / `retryButtonTapped`: 원격 fetch 이펙트와 커스텀 fetch 이펙트를 `.merge`. 단, `retryButtonTapped`는 원격만 재시도
   - `addPhrase(.presented(.saveResult(.some(phrase))))`: `state.customPhrases.insert(phrase, at: 0)`, `state.addPhraseState = nil` (`PlanFeature`의 `addPlan(.presented(.saveResult(true)))` 패턴)
   - `customPhraseDeleted`: 낙관적 제거 후 삭제 이펙트
   - body 끝에 `.ifLet(\.$addPhraseState, action: \.addPhrase) { AddKoreanPhraseFeature() }` 추가 (기존 `.ifLet(\.$phraseDetailState, ...)` 뒤)
   - `CancelID`에 `fetchCustomPhrases` 추가
4. `KoreanPhraseList/KoreanPhraseListView.swift` 수정
   - `.toolbar { ToolbarItem(placement: .topBarTrailing) { Button { store.send(.addButtonTapped) } label: { Image(systemName: "plus") } .tint(Color.getTabiColor(.tabiPrimary)).accessibilityLabel(...) } }` — `ShoppingPlanListView`의 툴바 패턴 그대로
   - `.sheet(item: self.$store.scope(state: \.addPhraseState, action: \.addPhrase)) { AddKoreanPhraseView(store: $0) }`
   - `content()` 분기 재작성:
     - 로딩 중 → `ProgressView`
     - 원격 실패 **and** 커스텀 0건 → 기존 `TabiRetryableEmptyState`(전체 화면)
     - 원격 0건 **and** 커스텀 0건 → 기존 `TabiEmptyState`
     - 그 외 → 2-Section `List`
   - 커스텀 Section의 각 행에만 `.swipeActions(edge: .trailing) { Button(role: .destructive) ... }` — Firebase Section에는 부착하지 않음
   - Section 헤더는 `customPhrases.isEmpty == false`일 때만 노출(결정사항 3). 헤더는 `TabiLabel(style: .captionMBold, color: .tabiTextSecondary)` + `.listRowInsets(EdgeInsets())` — `ShoppingPlanListView`의 헤더 inset 처리 주석 근거를 그대로 따름
   - `listRowSeparator(.hidden)` / `listRowBackground(Color.clear)` / `listRowInsets(top:6, leading:20, bottom:6, trailing:20)` 기존 값 유지
   - `#Preview`에 `useCase.customPhrases` 세팅 추가
5. `tuist install && tuist generate` → 빌드

### Phase 6. 검증
1. `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
2. 수동 시나리오
   - ToolBar 허브 → "간단한 한국어" → "+" → 폼 진입
   - 일본어만 입력 → 저장 버튼 비활성 확인
   - "번역" 탭 → 한국어 자동 채움 → **다시 한 번 더 탭해 재번역이 되는지 확인**(`TranslateSearchTaskModifier`의 Configuration `invalidate()` 검증 포인트)
   - 저장 → 커스텀 Section 최상단에 즉시 노출
   - 커스텀 행 스와이프 → 삭제됨 / Firebase 행 스와이프 → 삭제 액션 미노출
   - 커스텀 행 탭 → 가로모드 상세 진입, 롱프레스 복사 메뉴 동작
   - 앱 강제종료 후 재실행 → 커스텀 문구 유지
   - 기내모드로 재실행(Firebase 실패) → 커스텀 Section은 보이고 Firebase Section 자리에만 재시도 UI

---

## 완료 조건
- [ ] Spec Acceptance Criteria 8개 전부 충족
- [ ] `Domain`이 `Data`를 import하지 않음 — `CustomKoreanPhraseRepository` 조립은 `App/Sources/Dependency/KoreanPhraseUseCaseDependencyKey.swift`에서만 발생
- [ ] `testValue`(Domain) / `liveValue`(App) 계층 분리 유지, `DependencyValues.swift`는 무변경
- [ ] 신규/수정 파일이 `folder-structure.md`의 모듈별 경로 규칙을 벗어나지 않음
- [ ] 모든 신규 문자열이 `Resource/Sources/Strings/Strings.swift`의 `Strings.KoreanPhrase`에 정의되고, 코드에 하드코딩된 문자열 없음
- [ ] 신규 UI 컴포넌트를 만들지 않고 DesignSystem 기존 컴포넌트만 사용
- [ ] 프로토콜 채택은 `extension` 분리, `private` 멤버는 하단 `extension`에 모음, 강제 언래핑 없음
- [ ] `TranslateSearchTaskModifier.swift` 및 Map / PlanDetailAddSpot / AddCustomPlace 3개 화면 무변경
- [ ] 후속 과제 기록: `DataResetUseCase.resetAll()`에 커스텀 문구 초기화 포함 여부 논의

---

### Critical Files for Implementation
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Domain/Sources/UseCase/KoreanPhrase/KoreanPhraseUseCase.swift`
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/KoreanPhraseList/KoreanPhraseListFeature.swift`
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/KoreanPhraseList/KoreanPhraseListView.swift`
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Data/Sources/Repository/ToolBarPlanItem/ToolBarPlanItemRepository.swift` (신규 `CustomKoreanPhraseRepository`의 직접 템플릿)
- `/Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/TranslateSearch/TranslateSearchTaskModifier.swift` (`AddKoreanPhraseView`가 직접 재사용하는 공용 Modifier, 수정 금지)

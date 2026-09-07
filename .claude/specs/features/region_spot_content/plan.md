# Plan: region_spot_content

## 참조 Spec
- @specs/features/region_spot_content/spec.md

## 참조 Skill
- 신규 화면 생성이 아니라 **기존 `RegionSpotFeature`/`RegionSpotView` 확장**이므로 `create-feature` 스킬은 사용하지 않는다
- 준수 규칙: `.claude/rules/swift-style.md`, `.claude/rules/folder-structure.md`, `.claude/CLAUDE.md`

---

## 현재 상태 파악

### 신규
| 파일 | 모듈/폴더 |
|------|----------|
| `Sources/Extension/KoreanRegion+.swift` | `Data` — `areaCode` / `sigunguCode` / `lDongRegnCd` 매핑 |
| `Sources/RegionSpot/Sub/RegionSpotCategoryTabBar.swift` | `Presentation` |
| `Sources/RegionSpot/Sub/RegionSpotSpotSection.swift` | `Presentation` |
| `Sources/RegionSpot/Sub/RegionSpotFestivalSection.swift` | `Presentation` |

### 재사용 (신규 제작 금지)
- `DesignSystem`: `TabiChip`(카테고리 탭), `TabiSpotRow`(관광지 행), `TabiFestivalRow`(축제 행), `TabiEmptyState`(빈/에러 상태, `.fill`/`.card`), `TabiLabel`, `TabiCard`, `TabiButton`(재시도), `TabiAnimation`
- `Data`: `TouristSpotResponseDTO` — `dist`가 `String?`이라 `areaBasedList2`(거리 필드 없음) 응답에 그대로 재사용 가능. **DTO 신규 제작 불필요**
- `Domain`: `FestivalResponseDTO`/`Festival` Entity, `FestivalRepository.fetchRegions()`가 사용하는 `ldongCode2` 연동 로직 — 신규 제작 불필요, 파라미터만 추가(아래 "수정" 참조)
- `Presentation`: `Home/Model/CategoryType+.swift`의 `label` / `allItems`, `Home/Model/KoreanRegion+.swift`의 `jaTitle` / `koTitle` / `image`
- `Presentation`: `FestivalFeature`의 `.cancellable(id:cancelInFlight:)` + `AppLogger.view` 에러 처리 패턴

### 수정
| 파일 | 모듈 | 내용 |
|------|------|------|
| `Sources/Network/EndPoint/TouristSpotEndpoint.swift` | `Data` | `case areaBasedSpots(...)` 추가 |
| `Sources/Repository/TouristSpot/TouristSpotRepository.swift` | `Data` | 신규 메서드 구현 |
| `Sources/RepositoryProtocol/TouristSpotRepositoryProtocol.swift` | `Domain` | 신규 메서드 시그니처 |
| `Sources/UseCase/TouristSpot/TouristSpotUseCaseProtocol.swift` | `Domain` | 신규 메서드 시그니처 |
| `Sources/UseCase/TouristSpot/TouristSpotUseCase.swift` | `Domain` | 위임 구현 |
| `Sources/UseCase/TouristSpot/TestTouristSpotUseCase.swift` | `Domain` | `var regionSpots: [TouristSpot]` 주입 프로퍼티 + 구현 |
| `Sources/Network/EndPoint/FestivalEndpoint.swift` | `Data` | `searchFestival`에 `sigunguCode: String?` 파라미터 추가, `lDongSignguCd` 조건부 append (결정사항 5, 재검증 결과) |
| `Sources/Repository/Festival/FestivalRepository.swift` | `Data` | 신규 파라미터 전달 |
| `Sources/RepositoryProtocol/FestivalRepositoryProtocol.swift` | `Domain` | `fetchFestivals`에 `sigunguCode: String?` 파라미터 추가 |
| `Sources/UseCase/Festival/FestivalUseCaseProtocol.swift` | `Domain` | 동일 파라미터 추가 |
| `Sources/UseCase/Festival/FestivalUseCase.swift` | `Domain` | 위임 시 파라미터 전달 |
| `Sources/UseCase/Festival/TestFestivalUseCase.swift` | `Domain` | 시그니처 대응 갱신 |
| `Sources/Strings/Strings.swift` | `Resource` | `Strings.RegionSpot` 문자열 추가/교체 |
| `Sources/RegionSpot/RegionSpotFeature.swift` | `Presentation` | State/Action/Effect 전면 확장 |
| `Sources/RegionSpot/RegionSpotView.swift` | `Presentation` | Coming Soon → 실제 콘텐츠 |
| `Sources/Tabbar/TabBarFeature.swift` | `Presentation` | `path.element(.region(.spotTapped/.festivalTapped))` → `.detail` push |

### 변경 불필요 (spec 기재와 다름 — 확인 결과)
- `Domain/Sources/Dependency/Keys/TouristSpotUseCaseDependencyKey.swift`, `App/Sources/Dependency/TouristSpotUseCaseDependencyKey.swift`
  → 두 파일 모두 프로토콜 타입만 노출하고 구체 메서드를 나열하지 않으므로, 프로토콜에 메서드를 추가해도 **파일 수정이 필요 없다**. 구현체(`TouristSpotUseCase`, `TestTouristSpotUseCase`, `TouristSpotRepository`)만 채우면 컴파일된다.
- `Presentation/Sources/Home/Model/KoreanRegion+.swift` — areaCode를 여기 두면 Presentation이 API 파라미터를 알게 되므로 두지 않는다 (아래 결정사항 2 참조)
- 홈 → RegionSpot 라우팅(`HomeFeature.regionCardTapped` / `TabBarFeature` push) — 기존 유지

### 삭제
- `Strings.RegionSpot.comingSoonTitle` / `comingSoonDescription`, `RegionSpotView.comingSoonState()`
  → **존재 이유**: 화면이 비어 있는 동안 "준비 중" 안내를 표시하기 위한 임시 플레이스홀더. 본 기능이 그 자리를 실제 콘텐츠로 대체하므로 역할이 끝난다. 다른 참조가 없는지 `grep` 확인 후 삭제.

---

## 기술적 결정사항

### 1. API 서비스 경로는 `JpnService2`
spec 본문/`CLAUDE.md`는 `EngService2`로 적혀 있으나, 실제 코드(`TouristSpotEndpoint`, `FestivalEndpoint`)는 모두 `/B551011/JpnService2/...`를 사용한다. 신규 엔드포인트도 `/B551011/JpnService2/areaBasedList2`로 맞춘다. (앱 UI 언어가 일본어이므로 일관성 유지)

### 2. `areaCode` 매핑은 `Data` 모듈에 둔다
- 선택: `Data/Sources/Extension/KoreanRegion+.swift` (신규)
- 이유: `CategoryType.apiCode`가 이미 `Data/Sources/Extension/CategoryType+.swift`에 있는 기존 선례를 따른다. API 파라미터 코드값은 Data 레이어 관심사다.
- 결과: UseCase / Repository 프로토콜 시그니처는 `areaCode: String`이 아니라 **`region: KoreanRegion`**을 받는다. Presentation은 `Data`를 import할 수 없으므로(의존성 방향 위반) 이 형태가 유일하게 규칙에 맞는다.
- 대안(기각): `Domain/Entity`에 `TourAreaCode` 신규 Entity 도입 → 도메인 모델에 특정 외부 API 코드체계가 새어 들어감

### 3. `KoreanRegion`은 시도(市道) 단위가 아니다 — `areaCode` + `sigunguCode` 조합 필요
현재 케이스: `seoul, busan, jeju, gyeongju, yeosu, gangneung, jeonju, etc`

| KoreanRegion | 행정 단위 | areaCode | sigunguCode |
|---|---|---|---|
| `.seoul` | 광역시도 | 1 | 없음 |
| `.busan` | 광역시도 | 6 | 없음 |
| `.jeju` | 광역시도 | 39 | 없음 |
| `.gyeongju` | 경북 시군구 | 35 | **2** (慶州市) |
| `.yeosu` | 전남 시군구 | 38 | **13** (麗水市) |
| `.gangneung` | 강원 시군구 | 32 | **1** (江陵市) |
| `.jeonju` | 전북 시군구 | 37 | **12** (全州市) |
| `.etc` | 지역 아님 | 해당 없음 | 해당 없음 |

- **검증 완료 (Phase 0, `JpnService2/areaCode2` 실호출, 2026-08-10)**: 위 표의 모든 값을 실제 API 응답으로 확인했다. 시도 단위 목록(파라미터 없음)과 시군구 단위 목록(`areaCode` 파라미터 지정)을 각각 호출해 명칭(한자 표기)으로 대조했다. 추측값 없음.
- 응답 지역명 표기가 KorService와 다르다는 점도 확인: 전북은 `チョンブク特別自治道`(전북특별자치도), 강원은 `江原道`로 표기되나 코드값(37, 32)은 KorService 통용값과 동일했다.

### 4. `.etc` 케이스 처리 — **확정: 옵셔널 areaCode + 빈 상태**
- spec 불변조건: "모든 `KoreanRegion` 케이스가 유효한 `areaCode`로 매핑되어야 한다"
- 그러나 `.etc`는 지역이 아니라 "일정 추가 화면에서 직접 입력"을 유도하는 sentinel이다(`KoreanRegion+.swift` 주석: `image`/`emoji`가 `nil`, `allItems`에 미포함). 유효한 areaCode가 존재할 수 없다.
- 결정: `var areaCode: String?`를 `switch`로 전 케이스 열거(exhaustiveness로 누락은 컴파일 타임에 드러남) + `.etc`만 `nil`. `RegionSpotFeature`는 `nil`이면 API 호출 없이 빈 상태로 종료. 강제 언래핑 없음.
- 홈 지역 카드는 `allItems`(= `.etc` 제외)만 노출하므로 실사용 경로에서는 `nil`이 발생하지 않는다.

### 5. 축제 지역 필터는 `lDongRegnCd` + `lDongSignguCd`(법정동 시도/시군구코드)로 별도 매핑 — **확정: 시군구 단위 정밀 필터링**
- `searchFestival2`는 `areaCode`가 아니라 `lDongRegnCd`를 받는다(기존 `FestivalEndpoint` 확인). areaCode와 **다른 코드체계**이므로 areaCode를 그대로 넘기면 안 된다.
- **[재검증 결과 — plan 최초 작성 시 가정이 틀렸음]** 최초 계획에서는 `searchFestival2`가 시군구 파라미터를 지원하지 않는다고 가정해 "시도 전체 노출"로 결정했으나, Phase 0 실호출로 `lDongSignguCd` 파라미터가 실제로 지원되며 정확히 필터링됨을 확인했다(예: `lDongRegnCd=12&lDongSignguCd=130` → 여수 축제 1건만 정확히 반환, `lDongRegnCd=12`만 넘겼을 때는 11건). 이에 따라 사용자 재확인 후 **시군구 단위 정밀 필터링**으로 최종 확정.
- **중대 발견**: `ldongCode2` 응답 기준으로 **전라남도와 광주광역시가 하나의 코드(`12`, 표시명 "全南光州統合特別市")로 통합**되어 있다(2026-08-10 기준 응답). 즉 시도 단위 코드는 areaCode 체계(전남=38, 광주=5가 분리)와 lDongRegnCd 체계(전남+광주=12로 통합)가 **일치하지 않는다**. 여수는 `lDongRegnCd=12` 산하 `lDongSignguCd=130`으로 정확히 특정되므로 시군구 단위 필터링에서는 문제되지 않지만, 향후 다른 지역에서 시도 단위 코드를 재사용할 경우 이 불일치를 반드시 재확인해야 한다.
- **검증된 최종 값 (Phase 0, `ldongCode2` 실호출, 2026-08-10)**:

| KoreanRegion | lDongRegnCd | lDongSignguCd |
|---|---|---|
| `.seoul` | 11 | 없음(시도 단위) |
| `.busan` | 26 | 없음(시도 단위) |
| `.jeju` | 50 | 없음(시도 단위) |
| `.gyeongju` | 47 (경북) | 130 (慶州市) |
| `.yeosu` | 12 (전남·광주 통합) | 130 (麗水市) |
| `.gangneung` | 51 (강원) | 150 (江陵市) |
| `.jeonju` | 52 (전북) | 110 (全州市, 완산구/덕진구 상위 시 코드) |
| `.etc` | 없음 | 없음 |

- `FestivalEndpoint.searchFestival`에 `lDongSignguCd: String?` 파라미터를 신규 추가해야 한다(기존 시그니처는 `regionCode`만 받음) — plan.md "수정 필요 파일" 목록에 반영.
- **[구현 중 발견 — 모듈 경계 수정]** `Presentation`은 `Data`를 import할 수 없으므로 `RegionSpotFeature`가 `KoreanRegion.lDongRegnCd`/`lDongSignguCd`(둘 다 `Data` 확장)를 직접 읽을 수 없다. 이에 따라 `FestivalRepositoryProtocol`/`FestivalUseCaseProtocol`/`FestivalUseCase`/`TestFestivalUseCase`에 `fetchRegionFestivals(startDate:endDate:region: KoreanRegion:pageNo:)`를 추가하고, `Data`의 `FestivalRepository`가 내부적으로 `region.lDongRegnCd`/`lDongSignguCd`로 변환해 기존 `fetchFestivals(...)`에 위임하도록 구현했다(`fetchRegionSpots`와 동일한 결정사항 2 패턴). `RegionSpotFeature`는 `region: KoreanRegion`을 그대로 넘긴다.

### 6. 레이스 컨디션 방어는 이중 장치
1. `.cancellable(id: CancelID.regionSpots, cancelInFlight: true)` — 이전 in-flight 요청 취소 (`FestivalFeature` 선례)
2. 결과 액션에 요청 카테고리를 동봉: `case spotsResult(CategoryType, Result<[TouristSpot], ...>)` → reducer에서 `state.selectedCategory != category`면 무시
   - 취소 신호가 늦게 전달되는 경계 케이스까지 막기 위해 두 장치를 모두 둔다.

### 7. 로딩/빈/에러 3-상태를 명시적으로 구분
- `FestivalFeature`는 에러를 빈 배열로 흡수해 빈 상태와 에러가 구분되지 않는다. 본 화면은 AC에 "에러 표시 + 재시도"가 있으므로 그 패턴을 따르지 않는다.
- State에 로딩/성공/빈/에러를 표현하는 열거형(예: `RegionSpotLoadState`)을 두고 View에서 분기. 관광지 섹션과 축제 섹션은 **독립된 상태**를 가진다(한쪽 실패가 다른 쪽을 가리지 않도록).

---

## 구현 순서

### Phase 0. API 파라미터 검증 — **완료** (2026-08-10, 실호출로 검증)
- `areaCode2`(JpnService2) 실호출로 시도 단위 `areaCode` 목록 확인 → 결정사항 3의 표와 일치 확인
- `areaCode2`에 `areaCode=35/38/32/37`을 각각 넘겨 경주·여수·강릉·전주의 `sigunguCode` 확인 완료(2/13/1/12)
- `areaBasedList2` 1회 호출로 응답 스키마가 `TouristSpotResponseDTO`와 필드 단위 호환됨을 확인(`dist` 없음 → 옵셔널이라 문제없음). `arrange=Q`(대표이미지 우선)로 확정 — 리스트 UI에서 썸네일 없는 항목이 앞에 오지 않도록
- `ldongCode2` 응답에서 서울·부산·제주·경북·전남·강원·전북의 `lDongRegnCd` 확인 완료(11/26/50/47/12/51/52) — **전남과 광주가 코드 `12`로 통합되어 있음을 발견** (결정사항 5 참조)
- 추가 검증: `searchFestival2`가 `lDongSignguCd`(시군구) 파라미터를 실제로 지원함을 확인 → 사용자 재확인 후 시군구 단위 정밀 필터링으로 결정사항 5 변경
- 모든 값을 결정사항 3·5 표에 반영 완료, 추측값 없음

### Phase 1. Data 레이어
1. `Data/Sources/Extension/KoreanRegion+.swift` (신규)
   - `var areaCode: String?`, `var sigunguCode: String?`, `var lDongRegnCd: String?`, `var lDongSignguCd: String?` — 모두 전 케이스 `switch`, 값은 결정사항 3·5 표 그대로 하드코딩(검증 완료)
2. `Data/Sources/Network/EndPoint/TouristSpotEndpoint.swift` (수정)
   - `case areaBasedSpots(region: KoreanRegion, contentType: CategoryType, pageNo: Int)`
   - `path`: `/B551011/JpnService2/areaBasedList2`
   - `queryItems`: 기존 공통 파라미터(`MobileOS`, `MobileApp`, `serviceKey`, `_type`, `numOfRows=50`, `pageNo`) + `arrange=Q` + `contentTypeId` + `areaCode` + (있을 때만) `sigunguCode`
   - `sigunguCode`는 `FestivalEndpoint.searchFestival`의 `if let` 조건부 append 패턴을 따른다
3. `Data/Sources/Repository/TouristSpot/TouristSpotRepository.swift` (수정)
   - `fetchRegionSpots(region:contentType:pageNo:)` — `TouristSpotResponseDTO` 재사용, `toEntities()` 반환
4. `Data/Sources/Network/EndPoint/FestivalEndpoint.swift` (수정)
   - `searchFestival`에 `sigunguCode: String?` 파라미터 추가, `lDongSignguCd` 조건부 append (`regionCode`/`lDongRegnCd`와 동일한 `if let` 패턴)
5. `Data/Sources/Repository/Festival/FestivalRepository.swift` (수정) — 신규 파라미터를 Endpoint 호출부까지 전달

### Phase 2. Domain 레이어
1. `Domain/Sources/RepositoryProtocol/TouristSpotRepositoryProtocol.swift` — 시그니처 추가
2. `Domain/Sources/UseCase/TouristSpot/TouristSpotUseCaseProtocol.swift` — 시그니처 추가
3. `Domain/Sources/UseCase/TouristSpot/TouristSpotUseCase.swift` — repository 위임
4. `Domain/Sources/UseCase/TouristSpot/TestTouristSpotUseCase.swift` — `public var regionSpots: [TouristSpot] = []` 추가 + 반환
5. `Domain/Sources/RepositoryProtocol/FestivalRepositoryProtocol.swift` — `fetchFestivals`에 `sigunguCode: String?` 파라미터 추가
6. `Domain/Sources/UseCase/Festival/FestivalUseCaseProtocol.swift` — 동일 파라미터 추가
7. `Domain/Sources/UseCase/Festival/FestivalUseCase.swift` — repository 위임 시 파라미터 전달
8. `Domain/Sources/UseCase/Festival/TestFestivalUseCase.swift` — 시그니처 대응 갱신
9. 기존 호출부 `Presentation/Sources/Festival/FestivalFeature.swift:131`(`fetchFestivals(...)`) — 신규 파라미터에 `sigunguCode: nil` 전달 (지역 필터 없는 기존 축제 목록 화면 동작 불변)
- DependencyKey 파일(Domain `testValue` / App `liveValue`)은 **수정 없음**(현재 상태 파악 참조)

### Phase 3. Resource 레이어
`Resource/Sources/Strings/Strings.swift`의 `Strings.RegionSpot` 확장 갱신 (모두 일본어, 기존 톤 유지)
- 관광지 섹션 제목 / 축제 섹션 제목
- 관광지 빈 상태 제목·설명 / 축제 빈 상태 설명
- 에러 상태 제목·설명 / 재시도 버튼 라벨
- `comingSoonTitle`, `comingSoonDescription` 삭제
- "전체" 등 이미 있는 문자열은 `Strings.Common`(예: `contentTypeAll`) 재사용 여부 먼저 확인

### Phase 4. Presentation — Feature
`Presentation/Sources/RegionSpot/RegionSpotFeature.swift`
- `@Dependency(\.touristSpotUseCase)`, `@Dependency(\.festivalUseCase)`
- State (선언 순서: 공개 → fileprivate → @Presents)
  - `let region: KoreanRegion`
  - `var selectedCategory: CategoryType = .sightseeing`
  - `var spots: [TouristSpot] = []`, `var spotLoadState: RegionSpotLoadState = .idle`
  - `var festivals: [Festival] = []`, `var festivalLoadState: RegionSpotLoadState = .idle`
  - `fileprivate var hasLoadedInitialContent: Bool = false` (`FestivalFeature` 선례, `onAppear` 재진입 시 중복 호출 방지)
- Action (선언 순서: 생명주기 → 인터랙션 → 비동기 결과)
  - `onAppear`, `categoryTabTapped(CategoryType)`, `retryButtonTapped`, `spotTapped(TouristSpot)`, `festivalTapped(Festival)`, `spotsResult(CategoryType, [TouristSpot])`, `spotsFailed(CategoryType)`, `festivalsResult([Festival])`, `festivalsFailed`
- `private enum CancelID { case regionSpots, regionFestivals }` (파일 하단, `FestivalFeature` 배치 규칙)
- `private extension RegionSpotFeature`에 `fetchSpotsEffect(state:)` / `fetchFestivalsEffect(state:)` 분리
- Effect 내부는 `.run { [touristSpotUseCase = self.touristSpotUseCase] send in ... }` 값 캡처 (`swift-style.md` TCA 예외 규칙)
- 에러 시 `AppLogger.view.log(.error, ...)`, `Task.isCancelled`는 `.debug`로 분기 (`FestivalFeature` 선례)
- 축제 조회 기간: `startDate = 오늘`, `endDate = nil` → "진행 중/예정" 축제. `FestivalSearchPeriod` 상수 재사용 여부 확인

### Phase 5. Presentation — View / Sub
1. `RegionSpotView.swift` (수정)
   - 헤더 이미지 + 지역명 유지, `comingSoonState()` 제거
   - `ScrollView` 안에 `헤더 → 카테고리 탭 → 관광지 섹션 → 축제 섹션` 배치
   - `body` 50줄 초과 금지 — 서브뷰 호출만 남긴다
2. `Sub/RegionSpotCategoryTabBar.swift` (신규) — `CategoryType.allItems` 가로 스크롤 `TabiChip`. `FestivalRegionFilterBar`의 `ScrollViewReader` + `scrollTo(anchor: .center)` 패턴 참고
3. `Sub/RegionSpotSpotSection.swift` (신규) — 로딩 `ProgressView` / 빈 `TabiEmptyState(.fill)` / 에러 `TabiEmptyState` + `TabiButton` 재시도 / 성공 `LazyVStack` + `TabiSpotRow`
   - `TabiSpotRow`의 `distance`는 `areaBasedList2`에 거리 개념이 없으므로 `nil` 전달
4. `Sub/RegionSpotFestivalSection.swift` (신규) — `TabiFestivalRow` 재사용, 결과 없으면 섹션 전체 숨김 대신 `TabiEmptyState(.card)`로 인라인 표시
- 애니메이션은 `.tabiStandard` / `.tabiFast` 재사용

### Phase 6. 라우팅
`Presentation/Sources/Tabbar/TabBarFeature.swift`
- `case .path(.element(id: _, action: .region(.spotTapped(let spot)))):` → `state.path.append(.detail(DetailFeature.State(touristSpot: spot)))`
- `case .path(.element(id: _, action: .region(.festivalTapped(let festival)))):` → `festival.touristSpot`으로 `.detail` push (`FestivalView`/`planDetail` 선례 확인 후 동일 방식)
- 홈 → RegionSpot push 로직은 손대지 않는다

### Phase 7. 프로젝트 생성 및 빌드
```bash
tuist install && tuist generate
xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
- 신규 `.swift` 4개를 추가했으므로 `tuist generate` 없이 빌드하면 stale 프로젝트 오탐이 발생한다
- 시뮬레이터는 `iPhone 17` 사용(`iPhone 16 Pro` 미설치)

---

## 완료 조건
- [ ] Spec Acceptance Criteria 6개 충족
- [x] Phase 0에서 `areaCode` / `sigunguCode` / `lDongRegnCd` / `lDongSignguCd` 값을 실호출로 검증하고 plan에 반영 (추측값 하드코딩 없음)
- [ ] 모듈 의존성 방향 준수 — Presentation이 `Data`를 import하지 않고, areaCode는 Data 레이어 밖으로 노출되지 않음
- [ ] `KoreanRegion` 매핑이 `switch` 전 케이스 열거이며 강제 언래핑(`!`)이 없음
- [ ] 카테고리 탭 연타 시 이전 응답이 현재 선택을 덮어쓰지 않음 (`cancellable` + 결과 카테고리 대조)
- [ ] 관광지/축제 섹션 각각 로딩·성공·빈·에러 4상태가 UI에서 구분됨
- [ ] 신규 DesignSystem 컴포넌트를 만들지 않고 기존 컴포넌트로 구성됨
- [ ] 신규 문자열이 모두 `Strings.RegionSpot` / `Strings.Common`에 정의되고 뷰에 리터럴 없음
- [ ] `tuist generate` 후 빌드 성공

## 미해결 / 확인 필요
1. ~~`.etc` 케이스 정책~~ — **확정**: 옵셔널 `areaCode: String?` + `.etc`는 `nil` → 빈 상태 (결정사항 4)
2. ~~축제 섹션 범위~~ — **확정(재검증 후 변경)**: 경주/여수/강릉/전주는 `lDongSignguCd`로 시군구 단위 정밀 필터링(결정사항 5). 최초 "시도 전체 노출" 결정은 `searchFestival2`가 시군구 필터를 지원하지 않는다는 잘못된 가정에 기반했음이 Phase 0에서 드러나 재확인 후 변경됨.
3. ~~`arrange` 정렬 기준~~ — **확정**: `Q`(대표이미지 우선순, Phase 0 응답으로 확인)
4. **페이지네이션** — 이번 범위는 `pageNo: 1` 고정(50건). 무한스크롤은 spec 범위 밖이며 시그니처에 `pageNo`만 열어둔다.

모든 미해결 항목이 해소되어 Phase 1부터 순차 구현 가능.

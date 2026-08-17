# Plan: subway

## 참조 Spec
- @specs/features/subway/spec.md

## 참조 Skill
신규 화면 생성 시
- @skills/create-feature/SKILL.md
  - (현재 레포에 `create-feature` 스킬은 존재하지 않음. 이번 기능은 **신규 화면이 0개**이며 기존 3개 Feature에 검색 결과를 병합하는 작업이므로 스킬 불필요)

---

## 현재 상태 파악

### 신규
- **Resource**
  - `Resources/Subway/seoul_subway_station.json` — 서울교통공사 노선별 지하철역 정보 로컬 번들 (프로젝트 최초의 로컬 JSON 리소스)
  - `Sources/Data/SubwayStationResource.swift` — `Bundle.module` 기반으로 위 JSON의 `Data`(또는 `URL`)를 반환하는 public 접근자
  - `Sources/Strings/Strings.swift` — `Strings.Common.categorySubway` 추가 (기존 파일 수정)
  - `Sources/Image/TabiImage.swift` — `TabiIcon`에 `case subway = "tram.fill"` 추가 (기존 파일 수정)
- **Domain**
  - `Entity/SubwayStation.swift` — 로컬 JSON 매칭 + 그룹핑 결과를 표현하는 도메인 모델 (역명 한/일, 대표 `station_cd`, `fr_code`, `lineNumbers: [String]`)
  - `RepositoryProtocol/SubwayStationRepositoryProtocol.swift` — 로컬 JSON 검색 + 서울 열린데이터 API 조회 두 가지 책임
  - `UseCase/SubwayStation/SubwayStationUseCase.swift`, `SubwayStationUseCaseProtocol.swift`, `TestSubwayStationUseCase.swift`
  - `Dependency/Keys/SubwayStationUseCaseDependencyKey.swift` (testValue)
- **Data**
  - `DTO/SubwayStation/SubwayStationLocalDTO.swift` — 로컬 JSON 로우 (`station_nm`, `station_nm_jpn`, `line_num`, `station_cd`, `fr_code`) + 그룹핑/매칭 매핑
  - `DTO/SubwayStation/SubwayStationSearchResponseDTO.swift` — 서울 열린데이터 `SearchInfoBySubwayNameService` 응답 (`STATION_CD`, `STATION_NM`, `LINE_NUM`, `FR_CODE`) + `RESULT.CODE` 검증
  - `Network/EndPoint/SubwayStationEndpoint.swift`
  - `Repository/SubwayStation/SubwayStationRepository.swift`
  - `Extension/SubwayStationSearchNormalizer.swift`(가칭) — 가타카나/히라가나, 전각/반각, `駅`/`역` 접미사 정규화 헬퍼
- **App**
  - `Dependency/SubwayStationUseCaseDependencyKey.swift` (liveValue)

### 재사용
- `TouristSpot` / `Coordinate` / `Bookmark`(Domain) — 지하철역도 동일 엔티티로 표현 (`isCustom` 편입 패턴과 동일)
- `NaverGeocodingUseCase.geocode(address:)` — AddCustomPlace에서 이미 검증된 UseCase를 그대로 주입해 재사용 (수정 없음)
- `NetworkService` / `Endpoint`(+`headers` 기본 구현) / `NetworkError` / `AppLogger.network` — 서울 열린데이터 호출에 그대로 사용
- `BookmarkUseCase.add/remove/isBookmarked/fetch` — 수정 없이 지하철역에도 그대로 적용
- `TabiSpotRow` — 태그 제목/색상이 파라미터라 카테고리만 추가하면 "지하철" 뱃지가 자동 표시됨. 썸네일 `nil`이면 `KFImage.placeholder`(mappin)로 폴백 (확인 완료)
- `TabiColor.tabiAccentCoral` — 기존 토큰 재사용, 신규 colorset 없음 (확인 완료)
- `CategoryType.allItems`(Presentation) — Home/Map/RegionSpot/Bookmark 4개 카테고리 탭이 **모두** 이 배열만 순회하므로(확인 완료), `allItems`에 `.subway`를 넣지 않는 것만으로 "필터 탭 미노출" AC가 충족됨
- `DetailFeature`의 `isCustom` 분기 구조 (`onAppear`에서 API effect 스킵, `State.init`에서 저장값으로 `detail` 구성, `hasReceivedAllResults` 우회) — `isStation`에 동일 패턴 적용
- `Task.withMinimumDuration`(Core) — 로딩 스피너 깜빡임 방지, MapFeature 기존 호출부와 동일
- `TabiError.dataNotFound` — 지오코딩 0건 표현에 재사용, 신규 에러 케이스 불필요

### 수정
- **Tuist**
  - `Tuist/ProjectDescriptionHelpers/Dependency/DependencyInformation.swift` — `.data`의 내부 의존에 `.resource` 추가 (결정 2)
- **Domain**
  - `Entity/CategoryType.swift` — `case subway` 추가
  - `Entity/TouristSpot.swift` — `isStation: Bool = false` 저장 프로퍼티 + init 파라미터 추가 (기본값 부여로 기존 호출부 무영향)
  - `Entity/TravelPlanDetailSpot.swift` — `isStation: Bool = false` 추가 (결정 8)
  - `UseCase/TravelPlanShare/TravelPlanShareUseCase.swift` — `SpotPayload`에 `isStation` 추가 (결정 8)
  - `Dependency/DependencyValues.swift` — `subwayStationUseCase` 프로퍼티 추가
- **Data**
  - `Project.swift` — 수정 불필요 (JSON은 Resource 모듈에 둠, 결정 2)
  - `Extension/CategoryType+.swift` — `apiCode` / `init?(apiCode:)` switch에 `.subway` 처리 추가 (관광공사 코드 매핑 제외, 결정 4)
  - `Network/Secret/Secret.swift` — 서울 열린데이터 인증키 프로퍼티 추가
  - `Sources/Secret.xcconfig.sample` — 신규 키 항목 추가 (실제 값은 gitignored `Secret.xcconfig`에 사용자가 직접 기입, 커밋 금지)
  - `SwiftData/BookmarkModel.swift` + `Extension/BookmarkModel+.swift` — `isStation: Bool = false` 컬럼 + 양방향 매핑
  - `SwiftData/TravelPlanDetailSpotModel.swift` + `Extension/TravelPlanDetailSpotModel+.swift` — `isStation: Bool = false` 컬럼 + 양방향 매핑 (결정 8)
- **App**
  - `Info.plist` — 서울 열린데이터 키 `$(...)` 주입 항목 추가
- **Presentation**
  - `Home/Model/CategoryType+.swift` — `icon`/`color`/`label` switch에 `.subway` 추가, `allItems`에는 **미포함**
  - `Detail/DetailFeature.swift` — `TouristSpotIntro.empty(for:)` switch에 `.subway` 케이스 추가, `onAppear`/`State.init`/`hasReceivedAllResults`/`loadFailed`의 `isCustom` 분기를 "원격 상세 스킵" 조건으로 확장
  - `Detail/DetailView.swift` — 커스텀 뱃지 조건이 `isCustom`이므로 지하철역에는 뱃지가 붙지 않음(확인 완료). 실제 화면 확인 후 최소 수정
  - `Map/MapFeature.swift` — 지하철 검색 effect/액션 추가, `subwayResults` 상태 분리 + 병합 표시 (결정 5)
  - `Map/MapView.swift` — 결과 리스트/마커가 병합 배열을 보도록 변경, 페이징 트리거는 관광지 결과 기준 유지
  - `Map/Sub/MapSearchResultRowView.swift` — `TabiSpotRow(address:)` 전달 (관광지는 `nil`이라 무영향, 결정 7)
  - `PlanDetailAddSpot/PlanDetailAddSpotFeature.swift` — 동일하게 지하철 effect/상태 추가
  - `PlanDetailAddSpot/Sub/PlanDetailAddSpotSpotRow.swift` — `address` 전달
  - `AddCustomPlace/AddCustomPlaceFeature.swift`, `AddCustomPlaceView.swift` — "지하철" 모드 토글 추가, 모드에 따라 주소 TF 숨김/타이틀 TF 용도 전환, 지하철역 매칭 파이프라인 연결 (결정 1 확정)

### 삭제
- 없음

---

## 기술적 결정사항

- **[결정 1] AddCustomPlace 화면 구성 — "지하철" 모드 토글 (사용자 확정)**
  - 기존 `AddCustomPlaceView` 폼 순서는 ① 타이틀 입력 → ② 주소 입력(`onSubmit` → `addressSubmitted` → Naver Geocoding → 지도 미리보기) → ③ 카테고리 선택(`CategoryType.allItems` 기반 칩)이다 (확인 완료).
  - 여기에 **"지하철" 모드 토글을 카테고리 선택 섹션 바로 앞(주소 섹션 다음)에 추가**한다. 이 토글은 `CategoryType.allItems`를 건드리지 않는 **AddCustomPlace 전용 UI 요소**이므로, 결정 4의 "Home/Map/RegionSpot/Bookmark 카테고리 필터 탭에는 지하철 미노출" 방침과 충돌하지 않는다.
  - 토글 ON(지하철 모드):
    - 주소 TF를 숨긴다 (`addressSubmitted` 관련 UI/상태 비활성화).
    - 타이틀 TF의 용도를 지하철역명 입력 전용으로 전환한다(placeholder만 교체, 별도 TF 신설 아님).
    - 카테고리 칩 섹션은 숨기거나 비활성화하고, 카테고리는 내부적으로 `.subway`로 고정한다(사용자가 다른 카테고리를 고를 수 없음 — `isStation`과 `isCustom`이 동시에 true가 될 수 없다는 불변 조건과도 일치, 결정 12).
    - 타이틀 TF `onSubmit` 시 `SubwayStationUseCase`로 매칭 파이프라인을 실행한다: 로컬 JSON 매칭(한국어/일본어, 결정 6) → 환승역 그룹핑(결정 7) → 서울 열린데이터 API로 실재 여부 확인 → Naver Geocoding으로 좌표 획득(결정 11).
    - **매칭 성공**: 기존 주소 매칭 성공 시의 지도 미리보기 로직을 재사용해 좌표를 지도에 표시하고, 저장 버튼(`isConfirmEnabled`)을 활성화한다.
    - **매칭 실패/없음**: 지도 미리보기를 표시하지 않고 저장 버튼은 비활성 상태를 유지한다(에러 얼럿은 필요 없음 — spec의 "매칭 0건은 에러가 아니다" 정책과 동일하게 조용히 비활성 유지).
  - 토글 OFF(기본 모드): 기존 흐름(타이틀+주소+카테고리 선택) 그대로 유지, 무회귀.
  - 저장 시 `TouristSpot(isStation: true, isCustom: false, contentType: .subway, ...)`로 생성해 `bookmarkUseCase.add`에 전달 (기존 `bookmark_custom_place` 파이프라인 재사용, 결정 12와 일치).

- **[결정 2] 로컬 JSON은 Resource 모듈에 두고, Data가 Resource에 의존하도록 `DependencyInformation` 수정**
  - spec이 "Resource 모듈에 추가"를 명시. Resource는 `hasResource: true`라 `Bundle.module` 접근자가 이미 생성돼 있고(`Projects/Resource/Derived/Sources/TuistBundle+Resource.swift` 확인 완료), 그 `Bundle.module`은 Resource 모듈 내부 전용이므로 **Resource가 public 접근자를 노출**하고 Data는 그것만 호출한다.
  - `DependencyInformation.internalDependencyInfo`의 `.data`를 `[.domain, .core]` → `[.domain, .core, .resource]`로 수정. Resource는 최하위(의존 없음)이므로 순환 없음. 규칙대로 코드에서 직접 import하기 전에 이 파일부터 고친다.
  - **대안(기각)**: `Projects/Data/Project.swift`의 `hasResource`를 `true`로 바꾸고 `Projects/Data/Resources/`를 신설 → spec의 "Resource 모듈에 추가"와 어긋나고, Data는 `.staticFramework`라 리소스 번들 생성 방식이 Resource(`.framework`)와 달라져 검증 비용이 커짐.
  - 파싱(`Decodable` DTO)은 Data에 유지하고 Resource는 **바이트 전달만** 한다 — Resource가 도메인 지식을 갖지 않게 한다.

- **[결정 3] 로컬 JSON 검색 인덱스는 앱 수명주기 1회만 파싱해 메모리 캐시**
  - 서울 지하철역 데이터는 수백~1천 로우 수준이며 검색마다 재파싱하면 낭비. `SubwayStationRepository` 내부에 `actor` 또는 lazy 프로퍼티로 파싱 결과를 보관한다.
  - 매칭 정규화(결정 6) 결과도 로우별로 미리 계산해 캐시에 함께 저장한다.
  - 파일 누락/디코딩 실패 → `AppLogger.core`(리소스 문제) + `AppLogger.network`(호출 경로) 로깅 후 빈 배열 반환 → 지하철 결과만 스킵, 관광지 검색은 정상 진행(spec의 실패 정책과 동일).

- **[결정 4] `CategoryType.subway` 추가 시 exhaustive switch 5곳 처리 방침**
  - `.subway` 추가로 컴파일 에러가 나는 지점은 다음 5곳(전수 확인 완료):
    1. `Data/Extension/CategoryType+.swift`의 `apiCode` — `case .subway`에서 빈 문자열 반환 + `AppLogger.network` 에러 로깅. **`String?`로 바꾸지 않는다**(`TouristSpotEndpoint` 6개 케이스의 `URLQueryItem` 구성이 전부 영향받아 diff가 과도해짐). 지하철은 `fetchNearbySpots`/`fetchRegionSpots`/`fetchIntro` 경로에 절대 진입하지 않는 것을 `allItems` 제외 + Detail 스킵으로 구조적으로 보장한다.
    2. `Data/Extension/CategoryType+.swift`의 `init?(apiCode:)` — 관광공사 코드에 지하철이 없으므로 **매핑 추가 없음**(`default: return nil` 유지). spec 제약 그대로.
    3. `Presentation/Home/Model/CategoryType+.swift`의 `icon` → `.subway`(신규 `TabiIcon.subway = "tram.fill"`), `color` → `.tabiAccentCoral`, `label` → `Strings.Common.categorySubway`.
    4. 같은 파일의 `allItems` — `.subway` **미포함** (AC "필터 탭 미노출"이 이 한 줄로 충족됨).
    5. `Presentation/Detail/DetailFeature.swift`의 `TouristSpotIntro.empty(for:)` — `.subway`는 전 필드 `nil`인 `.sightseeing(...)` 플레이스홀더를 반환. 지하철역은 intro API를 호출하지 않으므로 실제로 렌더링되는 값이 없다(모든 `DetailInfoRow`가 자동 생략됨).
  - **부수효과 명시**: `BookmarkCategoryFilterBar`도 `allItems`를 쓰므로 북마크 화면에서 "지하철" 칩으로 필터링은 불가하다. "전체"에서는 정상 노출된다. spec 제약("검색결과 뱃지 용도로만 사용")과 일치하므로 의도된 동작으로 둔다.
  - `AddCustomPlaceView`의 일반 모드 카테고리 칩(`CategoryType.allItems` 기반)에는 여전히 `.subway`가 없다. 지하철역 생성은 결정 1의 전용 토글 경로로만 가능하며, 그 경로는 카테고리 칩을 아예 우회하고 `.subway`를 내부 고정값으로 사용한다 → 두 경로가 겹치지 않아 "`isStation`과 `isCustom`은 동시에 true 불가"가 UI 레벨에서도 자연스럽게 보강된다.

- **[결정 5] 지하철 검색은 관광지 검색과 별도 Effect로 실행하고, State에 배열을 분리 보관 후 표시 시점에 병합**
  - `TouristSpotUseCase.searchByKeyword` 내부에 지하철 로직을 밀어넣는 방식은 기각: MapFeature는 `searchNextPageResultsResult`로 **결과를 append**하므로, UseCase가 매 페이지마다 지하철 결과를 앞에 붙이면 2페이지 이후 중복·순서 붕괴가 발생한다.
  - 각 Feature State에 `subwayResults: [TouristSpot]`와 기존 관광지 결과 배열을 **따로** 두고, 뷰에는 `subwayResults + spotResults` 형태의 computed 프로퍼티를 노출한다. 두 Effect의 도착 순서와 무관하게 "지하철 우선" 불변 조건이 보장된다(단일 배열에 삽입하는 방식은 레이스에 취약해 기각).
  - `searchSubmitted`에서 `.merge(관광지 effect, 지하철 effect)`로 동시 실행. 지하철 effect는 별도 `CancelID`로 `cancelInFlight: true` — 검색 취소/재검색 시 함께 취소되도록 `searchCancelTapped`/`resetSearchState`에도 반영한다.
  - MapView 영향 점검(확인 완료): ① 마커 생성은 병합 배열을 쓰되 지하철도 좌표가 유효하므로 정상 표시, ② 셀 탭 시 `searchResults.first(where: id)` 조회도 병합 배열로 대체, ③ 다음 페이지 트리거(`spot.id == searchResults.last?.id`)는 **관광지 배열 기준**으로 유지해야 관광지 결과가 0건일 때 지하철 셀이 페이징을 유발하지 않는다.

- **[결정 6] 검색어 매칭 정규화 규칙**
  - 대조 대상: 로컬 JSON의 `station_nm_jpn`(가타카나) / `station_nm`(한국어).
  - 정규화: 앞뒤 공백 제거 → 전각/반각 통일 → 히라가나를 가타카나로 변환(일본어 IME 특성상 히라가나 입력이 흔함) → 접미사 `駅`/`역` 제거 → 대소문자·중점(`・`) 등 구분자 제거.
  - 매칭 방식: **prefix 매칭 우선 → contains 매칭 보조**로 정렬(정확도 높은 결과가 위로 오게). 부분 문자열만 쓰면 "역"류 단어에 과도하게 매칭된다.
  - 매칭 0건은 **에러가 아니다** — 지하철 결과 없이 관광지 검색만 진행(spec 명시).
  - 정규화 헬퍼는 Data 모듈 `Extension/`에 둔다. Core의 `String+`는 관광공사 응답 정제 전용이므로 섞지 않는다.

- **[결정 7] 환승역 그룹핑 / 호선 정보 표시 / ID 규칙**
  - 그룹핑 키: `station_nm`(한국어 역명). 같은 역명의 여러 로우를 1건으로 묶고 `line_num`을 배열로 보관 → 불변 조건 "역명당 1개" 충족.
  - **대표 로우 선정은 결정적이어야 한다** — `line_num` 오름차순(또는 `station_cd` 오름차순)으로 정렬한 첫 로우를 대표로 고정한다. 그렇지 않으면 검색할 때마다 대표 `station_cd`가 바뀌어 북마크 ID가 흔들린다.
  - `TouristSpot.id` = `"subway_" + 대표 station_cd`. 관광공사 `contentId`는 순수 숫자라 충돌 불가하며, `BookmarkModel.contentId`가 `@Attribute(.unique)`이므로 중복 저장도 DB에서 차단된다. **단, 판정은 접두사 파싱이 아니라 `isStation` 필드로 한다**(기존 `isCustom` 결정과 동일 원칙).
  - `TouristSpot.title` = `"{station_nm_jpn}（{station_nm}）"` 형태 → 기존 `japaneseTitle`/`koreanTitle` computed 파싱 규칙(전각 괄호 지원, 확인 완료)에 그대로 올라타 별도 뷰 분기가 불필요하다.
  - **호선 정보 노출 위치**: `TouristSpot.address`에 `"{호선 목록} · {지오코딩 주소}"` 형태로 담는다. 이유 — ① `TabiSpotRow`가 이미 `address`를 3번째 줄에 렌더링하고, ② `BookmarkModel.address`로 그대로 영속화되어 북마크 목록/DetailView에서도 호선 정보가 유지되며, ③ `TouristSpot`에 지하철 전용 필드(`lineNumbers`)를 추가하지 않아 엔티티 오염이 없다. 대안(엔티티에 `lineNumbers: [String]` 추가)은 SwiftData 스키마 컬럼이 하나 더 늘고 공유 payload까지 번지므로 기각.
  - 호선 문자열은 일본어 UI에 맞춰 `호선` → `号線` 치환 후 `・`로 조인하는 것을 권장(예: `1・4号線`). 최종 표기는 구현 시 실제 데이터 확인 후 확정.
  - `MapSearchResultRowView` / `PlanDetailAddSpotSpotRow`는 현재 `TabiSpotRow`에 `address`를 전달하지 않는다 → 전달하도록 수정. 관광지 검색 결과의 `address`는 `nil`이므로(`TouristSpotDTO.toEntity()`가 세팅하지 않음, 확인 완료) 기존 화면에 회귀 없음.

- **[결정 8] `isStation`을 `TravelPlanDetailSpot`까지 전파**
  - PlanDetailAddSpot이 spec의 명시적 진입점이므로 **지하철역이 일정에 추가될 수 있다**. 그런데 `TabBarFeature`의 `planDetail(.spotRowTapped)` 핸들러는 `TravelPlanDetailSpot`으로부터 `TouristSpot`을 재구성하며 `isCustom`만 넘긴다(확인 완료) → `isStation`을 전파하지 않으면 일정에서 역을 탭했을 때 `isStation == false`가 되어 **관광공사 상세 API를 `"subway_xxxx"` contentId로 호출**하고 실패 화면이 뜬다.
  - 따라서 `TravelPlanDetailSpot` / `TravelPlanDetailSpotModel` / `TravelPlanDetailSpotModel+` / `TravelPlanShareUseCase.SpotPayload` / `AddToItineraryFeature`·`PlanDetailAddSpotFeature`의 생성부에 `isStation`을 `isCustom`과 나란히 추가한다. 모두 기본값 `false`이므로 기존 호출부는 무수정 컴파일된다.
  - **대안(기각)**: ID 접두사 `"subway_"` 파싱으로 판정 → 결정 7의 원칙 위반.

- **[결정 9] SwiftData 스키마 변경은 라이트웨이트 마이그레이션 (VersionedSchema 미도입)**
  - 추가되는 건 `BookmarkModel.isStation: Bool = false`, `TravelPlanDetailSpotModel.isStation: Bool = false` 두 개의 **기본값 있는 신규 컬럼**뿐. 삭제·개명·타입 변경이 없어 자동 경량 마이그레이션 범위이며, 직전 `isCustom`/`address` 추가 때와 동일한 상황(선례 확인 완료).
  - **주의**: `BookmarkModelContainer`는 생성 실패 시 in-memory로 조용히 폴백하므로 마이그레이션이 깨지면 기존 북마크가 사라진 것처럼 보인다. 구현 후 **기존 DB가 있는 상태에서 앱을 재실행해 북마크·일정이 보존되는지 반드시 검증**한다(완료 조건 포함).

- **[결정 10] 서울 열린데이터 API 호출 정책 — 인증키 위치와 실패 시 폴백 (Phase 0 실제 호출로 확정 완료)**
  - `SearchInfoBySubwayNameService`는 인증키를 **URL 경로(path segment)** 에 포함하는 서울 열린데이터 광장 공통 형식이다(쿼리 파라미터 아님). `Endpoint.path`에서 `Secret` 값을 보간하는 첫 사례가 된다 — `queryItems`가 아니라 `path` 조립이라는 점을 구현 시 유의.
  - 확정된 URL 형식: `http://openapi.seoul.go.kr:8088/{인증키}/json/SearchInfoBySubwayNameService/{start}/{end}/{역명}` (HTTP, 포트 8088). 역명은 URL 인코딩 필요. 평문 HTTP이지만 `App/Info.plist`의 `NSAllowsArbitraryLoads = true`가 이미 설정돼 있어 ATS 예외 추가는 불필요(확인 완료).
  - **응답 스키마가 성공/실패에 따라 최상위 구조가 다르다** (실제 호출로 확인):
    - 성공: `{"SearchInfoBySubwayNameService":{"list_total_count":N,"RESULT":{"CODE":"INFO-000","MESSAGE":"..."},"row":[{"STATION_CD","STATION_NM","LINE_NUM","FR_CODE"}, ...]}}`
    - 0건: `{"RESULT":{"CODE":"INFO-200","MESSAGE":"해당하는 데이터가 없습니다."}}` — `SearchInfoBySubwayNameService`/`row` 키 자체가 없다. `SubwayStationSearchResponseDTO`는 이 두 형태를 모두 안전하게 디코딩해야 하며(`row`를 optional로 두거나 커스텀 `init(from:)`), 존재하지 않으면 빈 배열로 처리한다.
    - `LINE_NUM`은 `"02호선"` 외에 `"GTX-A"` 같은 비-호선 표기도 존재 — 로컬 JSON의 `line_num`(`"01호선"` 2자리 zero-padded)과 표기 체계가 다를 수 있으므로, 호선 문자열 표시(결정 7)는 로컬 JSON 값 기준으로 하고 API의 `LINE_NUM`은 실재 확인 용도로만 사용한다.
  - 시크릿 키 이름: `Secret.xcconfig` / `Secret.xcconfig.sample` / `Info.plist`에 신규 항목 1개 추가 + `Secret.swift`에 프로퍼티 1개 추가. 실제 값은 사용자가 `Secret.xcconfig`(gitignored)에 직접 기입하며 **커밋 금지**.
  - 인증키가 URL에 들어가므로 `AppLogger.network`의 요청 URL 로그에 노출된다. 기존 `TouristSpotEndpoint`도 `serviceKey`를 쿼리로 노출하고 있어 동일 수준이지만, 필요 시 이 엔드포인트만 `enableLog = false`로 두는 선택지가 있다(`Endpoint`가 이미 지원, 확인 완료).
  - 실패/타임아웃 → 지하철 결과만 빈 배열, `AppLogger.network` 로깅, 관광지 검색은 정상 진행(spec 명시).

- **[결정 11] 네트워크 호출량 — 상위 5건으로 먼저 자르고, 서울 API·지오코딩은 병렬 + 캐시**
  - 파이프라인: 로컬 매칭 → 그룹핑 → **정렬 후 상위 5건으로 절단** → (서울 API 조회 + 지오코딩)을 `withTaskGroup`으로 병렬 실행. 절단을 먼저 해야 검색 1회당 네트워크 호출이 최대 10건(서울 5 + 지오코딩 5)으로 상한이 잡힌다.
  - `SearchInfoBySubwayNameService`는 역명 1개 단위 조회이므로 역마다 1콜이다. 결과는 역명 키로 **인메모리 캐시**해 재검색 시 재호출을 피한다. 지오코딩 결과(좌표+주소)도 동일 키로 캐시한다 — Naver Geocoding은 유료/쿼터 대상이므로 중요.
  - 지오코딩 좌표 획득 실패한 역은 **결과에서 제외**한다(spec: 좌표 없는 상태로 노출 금지). `Coordinate.zero`로 채워 넣지 않는다 — `Coordinate.isValid`가 `.zero`를 무효로 보고 MapFeature의 `searchResultFitToken` 로직이 이를 근거로 카메라를 맞추기 때문.
  - 지오코딩 질의 문자열은 spec대로 `"{line_num} {station_nm}역"`. 환승역은 대표 호선(결정 7의 대표 로우) 하나만 사용한다.

- **[결정 12] `isStation`과 `isCustom` 동시 true 방지**
  - `TouristSpot`을 `isStation: true`로 만드는 지점은 **지하철 매퍼 단 한 곳**으로 제한하고, 그 지점에서 `isCustom`은 전달하지 않는다(기본값 `false`).
  - 추가로 UI 레벨 보강: 카테고리 칩에 "지하철"이 없어(결정 4) 사용자가 커스텀 장소를 지하철로 만들 수 없다.
  - `precondition`/`assert`로 런타임 강제하는 방식은 릴리스에서 무력화되고 크래시 리스크만 늘리므로 채택하지 않는다. 단일 생성 지점 + 코드 주석으로 불변 조건을 문서화한다.

- **[결정 13] DetailFeature의 스킵 조건은 `isCustom` 대신 "원격 상세 조회 대상 여부"로 일반화**
  - 현재 `DetailFeature`에는 `isCustom` 분기가 5곳(`State.init`의 address/coordinate, `hasReceivedAllResults`, `loadFailed`, `onAppear`)에 흩어져 있다. `|| isStation`을 5곳에 중복 작성하는 대신, `TouristSpot`에 `shouldSkipRemoteDetail`(= `isCustom || isStation`) 같은 computed 프로퍼티 하나를 두고 그것을 참조한다.
  - 지하철역 Detail 결과: `detail.address`에 저장 주소(호선 포함)가 채워지고, `intro`는 전 필드 `nil`이라 `DetailInfoRow`가 주소 행만 남으며, `images`가 비어 photos 탭이 자동 제외되고, map 탭은 유효 좌표로 정상 동작한다(모두 커스텀 장소에서 검증된 경로, 확인 완료) → **관광공사 API 호출 0건**.
  - `naverMapUseCase.makeShareURL(query:)` / `mapSearchButtonTapped`는 타이틀 기반이라 역명으로도 정상 동작한다.

---

## 구현 순서

### Phase 0. 사전 확인 (착수 전 차단 항목)
- 로컬 JSON 원본 파일 확보 및 실제 스키마 확인 — 키 이름(`station_nm`/`station_nm_jpn`/`line_num`/`station_cd`/`fr_code`), 최상위 구조(배열 vs 래핑 객체), 값 타입(문자열/숫자), `line_num` 실제 표기(`1호선` 등), 인코딩.
- 서울 열린데이터 `SearchInfoBySubwayNameService` 실제 호출 1회로 확정: 프로토콜/호스트/포트, 경로 형식과 인증키 위치, 페이지 파라미터, 응답 루트 키, `RESULT.CODE` 성공값, 역명 미존재 시 응답 형태.
- 서울 열린데이터 인증키 발급 및 `Secret.xcconfig`(gitignored)에 기입.

### Phase 1. Tuist 의존성
- `DependencyInformation.swift`의 `.data` 내부 의존에 `.resource` 추가 (결정 2).
- `tuist install && tuist generate` 후 기존 타깃 빌드 회귀 없는지 확인.

### Phase 2. Resource
- `Resources/Subway/`에 JSON 배치, `Sources/Data/SubwayStationResource.swift`로 public 접근자 추가.
- `Strings.Common.categorySubway`(일본어 문구 + 한국어 주석) 추가, `TabiIcon.subway = "tram.fill"` 추가.
- 신규 리소스 인식을 위해 `tuist generate` 재실행.

### Phase 3. Domain 엔티티 확장
- `CategoryType`에 `case subway` 추가 → 컴파일 에러 5곳(결정 4)을 순서대로 처리.
- `TouristSpot`에 `isStation: Bool = false` + `shouldSkipRemoteDetail` computed 추가 (결정 13).
- `TravelPlanDetailSpot`에 `isStation: Bool = false` 추가 (결정 8).
- 기존 호출부가 기본값 덕분에 무수정 컴파일되는지 빌드로 확인.

### Phase 4. Domain 지하철 계층
- `SubwayStation` 엔티티 정의(한/일 역명, 대표 `station_cd`, `fr_code`, `lineNumbers`).
- `SubwayStationRepositoryProtocol` 정의 — 로컬 검색(동기/비동기)과 서울 API 조회를 분리된 메서드로.
- `SubwayStationUseCaseProtocol` + `SubwayStationUseCase` 구현 — `SubwayStationRepositoryProtocol` + `NaverGeocodingRepositoryProtocol` 2개 주입(다중 Repository 주입은 `DataResetUseCase` 선례 있음, 확인 완료). 매칭 → 그룹핑 → 상위 5건 절단 → 서울 API/지오코딩 병렬 → `TouristSpot` 매핑까지 오케스트레이션 (결정 11).
- `TestSubwayStationUseCase` 더블 작성.
- `Dependency/Keys/SubwayStationUseCaseDependencyKey.swift`(testValue) + `DependencyValues.swift` 프로퍼티 추가.

### Phase 5. Data 로컬 JSON
- `SubwayStationLocalDTO` + 그룹핑/정렬 매핑 (결정 7).
- 정규화 헬퍼 (결정 6).
- `SubwayStationRepository`에 파싱 결과 인메모리 캐시 구현 (결정 3).
- 이 시점에서 **네트워크 없이** 매칭·그룹핑만 단위 검증(가타카나/히라가나/한국어/환승역/미존재 역).

### Phase 6. Data 서울 열린데이터 연동
- `Secret.swift` / `Secret.xcconfig.sample` / `App/Info.plist`에 신규 키 반영 (결정 10).
- `SubwayStationEndpoint` 작성 — 인증키를 `path`에 보간, 역명 URL 인코딩 확인.
- `SubwayStationSearchResponseDTO` + `RESULT.CODE` 검증 + `toEntities()` 매핑, 실패 시 `AppLogger.network` 로깅.
- `SubwayStationRepository`에 API 조회 구현 + 응답 캐시.

### Phase 7. Data 영속화 스키마
- `BookmarkModel` / `TravelPlanDetailSpotModel`에 `isStation: Bool = false` 추가 + 양방향 매핑 갱신.
- `TravelPlanShareUseCase.SpotPayload`에 `isStation` 추가 (결정 8).
- 기존 DB가 있는 상태로 앱 재실행 → 북마크/일정 보존 확인 (결정 9).

### Phase 8. App DI
- `App/Dependency/SubwayStationUseCaseDependencyKey.swift`에 `@retroactive DependencyKey` liveValue 정의 (`SubwayStationRepository()` + `NaverGeocodingRepository()` 조립).
- `tuist generate` 후 빌드 (신규 `.swift` 반영 필수).

### Phase 9. Presentation — 검색 통합
- `Home/Model/CategoryType+.swift`: `icon`/`color`/`label` 추가, `allItems` 미변경 (결정 4).
- `MapFeature`: `subwayResults` 상태 + 지하철 effect/액션 + 병합 computed + 취소/리셋 반영 (결정 5). `MapView`의 리스트·마커·셀 탭·페이징 트리거를 결정 5의 지침대로 조정.
- `MapSearchResultRowView` / `PlanDetailAddSpotSpotRow`에 `address` 전달 (결정 7).
- `PlanDetailAddSpotFeature`: 동일 패턴 적용. `saveButtonTapped`에서 `isStation` 전파 (결정 8).
- `AddToItineraryFeature`: `isStation` 전파.
- `AddCustomPlace`: 카테고리 섹션 바로 앞에 "지하철" 모드 토글 추가, 토글 ON 시 주소 TF 숨김 + 타이틀 TF를 역명 입력 전용으로 전환 + 카테고리 `.subway` 고정, `onSubmit` 시 매칭 파이프라인 실행 후 성공하면 지도 미리보기 표시·저장 버튼 활성화 (결정 1).

### Phase 10. Presentation — Detail 분기
- `TouristSpotIntro.empty(for:)`에 `.subway` 추가.
- `DetailFeature`의 `isCustom` 분기 5곳을 `shouldSkipRemoteDetail` 기준으로 교체 (결정 13).
- `DetailView`에서 지하철역 전용으로 숨기거나 손봐야 할 요소가 남았는지 실제 화면 확인 후 최소 수정.

### Phase 11. 빌드 / 검증
- `tuist install && tuist generate` 후 빌드 (시뮬레이터는 설치된 기기로).
- 시나리오 검증: 가타카나 입력 / 한국어 입력 / 히라가나 입력 / 환승역 / 미존재 역 / 서울 API 강제 실패 / 지오코딩 실패 / 3개 화면 각각 / 북마크 저장·목록·상세 / 일정 추가 후 일정에서 역 탭 / 카테고리 탭 4곳에 "지하철" 미노출 / 앱 재실행 후 보존.
- Xcode 네트워크 로그로 지하철역 Detail 진입 시 관광공사 호출 0건 확인.

---

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
  - [ ] MapView 검색 TF에 가타카나/한국어 역명 입력 시 최상단에 지하철역 노출
  - [ ] AddCustomPlace의 "지하철" 모드 토글에서 역명 입력 → 매칭 성공 시 지도 미리보기 표시·저장 버튼 활성화 / PlanDetailAddSpot 스팟 검색에서도 통합검색 결과 최상단에 노출
  - [ ] 검색결과 셀에 "지하철" 태그(`tram.fill`, `tabiAccentCoral`) 표시
  - [ ] 환승역이 중복 없이 1건으로 표시되고 호선 정보 확인 가능
  - [ ] 지하철역 북마크 저장 가능
  - [ ] 북마크 목록/상세화면에서 저장된 지하철역 확인 가능
  - [ ] 지하철역 Detail 진입 시 역명·주소만 표시, 관광공사 상세 API 호출 0건 (네트워크 로그 확인)
  - [ ] Home/Map(및 RegionSpot/Bookmark) 카테고리 필터 탭에 "지하철" 미노출
- [ ] 불변 조건 검증: 지하철 결과가 항상 관광지 결과보다 앞 / 역명 중복 없음 / `isStation`과 `isCustom` 동시 true 불가
- [ ] 실패 경로 검증: 매칭 0건·서울 API 실패·지오코딩 실패 시 관광지 검색은 정상 진행하고 `AppLogger.network` 로깅
- [ ] 기존 북마크·일정이 스키마 변경 후에도 유실 없이 유지 (경량 마이그레이션 검증)
- [ ] 일정에 추가한 지하철역을 일정 상세에서 탭했을 때 관광공사 API를 호출하지 않음 (결정 8 회귀 검증)
- [ ] `Secret.xcconfig`는 커밋되지 않고 `Secret.xcconfig.sample`에만 키 항목 반영
- [ ] `DependencyInformation` 의존성 방향 위반 없음 (Domain은 Data 미참조, liveValue 조립은 App에서만, Data → Resource는 `DependencyInformation.swift`를 통해 선언)
- [ ] 신규 `.swift`/리소스 추가 후 `tuist generate` 실행하여 stale 프로젝트 오탐 없이 빌드 성공

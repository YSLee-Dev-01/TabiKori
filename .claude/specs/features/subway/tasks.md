# Tasks: subway

## 참조
- spec: `.claude/specs/features/subway/spec.md`
- plan: `.claude/specs/features/subway/plan.md`

## Task 목록

### Phase 0. 사전 확인 (착수 전 차단 항목)

#### [x] Task 1 — 로컬 JSON 원본 스키마 확인
**파일**: 없음 (조사 전용, 코드 작성 없음)
- 서울교통공사_노선별 지하철역 정보 원본 JSON 파일을 확보한다
- 실제 키 이름(`station_nm`/`station_nm_jpn`/`line_num`/`station_cd`/`fr_code`) 존재 여부와 최상위 구조(배열 vs 래핑 객체), 값 타입(문자열/숫자), `line_num` 실제 표기(`1호선` 등), 인코딩을 확인한다
- 확인 결과를 바탕으로 Phase 5의 `SubwayStationLocalDTO` 필드/타입을 확정한다 (추측 금지, CLAUDE.md 원칙)
- **확인 결과**: 최상위 `{"DESCRIPTION": {...}, "DATA": [...]}` 래핑 객체. `DATA` 배열 각 로우는 `{"line_num","station_nm_chn","station_cd","station_nm_jpn","station_nm_eng","station_nm","fr_code"}` (모두 String). 총 799건, `station_nm` 기준 중복(환승역) 120건. 위경도/주소 필드 없음. UTF-8 인코딩. `line_num`은 `"01호선"` 형태(2자리 zero-padded)

---

#### [x] Task 2 — 서울 열린데이터 `SearchInfoBySubwayNameService` 실제 호출 확인
**파일**: 없음 (조사 전용, 코드 작성 없음)
- 실제 API를 1회 호출해 프로토콜/호스트/포트, 경로 형식과 인증키 위치(path segment, 결정 10), 페이지 파라미터, 응답 루트 키, `RESULT.CODE` 성공값, 역명 미존재 시 응답 형태를 확정한다
- 확인 결과를 바탕으로 Phase 6의 `SubwayStationEndpoint`/`SubwayStationSearchResponseDTO` 스펙을 확정한다 (추측 금지)
- **확인 결과**: `http://openapi.seoul.go.kr:8088/{인증키}/json/SearchInfoBySubwayNameService/{start}/{end}/{역명}` (HTTP, path segment 인증키, 포트 8088). 역명은 URL 인코딩 필요.
  - 성공 시: `{"SearchInfoBySubwayNameService":{"list_total_count":N,"RESULT":{"CODE":"INFO-000","MESSAGE":"..."},"row":[{"STATION_CD","STATION_NM","LINE_NUM","FR_CODE"}, ...]}}` — 서비스명이 최상위 키
  - **0건일 때는 최상위 래핑이 사라짐**: `{"RESULT":{"CODE":"INFO-200","MESSAGE":"해당하는 데이터가 없습니다."}}` (`SearchInfoBySubwayNameService`/`row` 키 자체가 없음 → DTO는 두 형태를 모두 디코딩 가능해야 함)
  - `LINE_NUM`은 API 응답에서 `"02호선"`뿐 아니라 `"GTX-A"` 같은 비-호선 표기도 존재 (로컬 JSON `line_num`과 표기가 다를 수 있음 — 결정 7의 호선 문자열 포맷팅 시 유의)

---

#### [x] Task 3 — 서울 열린데이터 인증키 발급 및 로컬 설정
**파일**: `Projects/Data/Sources/Secret.xcconfig` (gitignored, 커밋 금지)
- 서울 열린데이터 광장에서 인증키를 발급받는다
- 로컬 `Secret.xcconfig`(gitignored)에 신규 키 항목을 기입한다 (실제 키 이름은 Phase 6에서 `Secret.xcconfig.sample`에 추가하는 항목명과 일치시킨다)
- **주의**: 이 파일은 절대 git 작업 대상이 아님 (CLAUDE.md 명시)
- **완료**: 키 항목명 `SEOUL_SUBWAY_API_KEY` (사용자가 직접 값 기입), `Secret.xcconfig.sample`에도 `SEOUL_SUBWAY_API_KEY = ""` 템플릿 반영 완료. 실제 API 호출로 유효성 검증 완료 (Task 2)

---

### Phase 1. Tuist 의존성

#### [x] Task 4 — `DependencyInformation.swift` 수정 (Data → Resource 의존 추가)
**파일**: `Tuist/ProjectDescriptionHelpers/Dependency/DependencyInformation.swift`
- `internalDependencyInfo`의 `.data` 항목을 `[.domain, .core]` → `[.domain, .core, .resource]`로 수정 (결정 2)
- Resource는 최하위(의존 없음)이므로 순환 참조가 생기지 않는지 확인

---

#### [x] Task 5 — Tuist 재생성 및 회귀 확인
**파일**: 없음 (빌드 검증 전용)
- `tuist install && tuist generate` 실행
- 기존 타깃이 정상 빌드되는지 확인 (신규 코드 없이 의존성 그래프 변경만 반영된 상태)
- **완료**: `tuist install`/`tuist generate` 성공, `xcodebuild build`(AppDebug, iPhone 17) **BUILD SUCCEEDED**

---

### Phase 2. Resource

#### [x] Task 6 — 로컬 JSON 번들 리소스 배치
**파일**: `Projects/Resource/Resources/Subway/seoul_subway_station.json` (신규)
- Phase 0에서 확보한 서울교통공사 노선별 지하철역 정보 JSON을 배치한다
- **완료**: 원본 파일을 위 경로로 복사, UTF-8 인코딩 확인

---

#### [x] Task 7 — `SubwayStationResource.swift` (신규)
**파일**: `Projects/Resource/Sources/Data/SubwayStationResource.swift` (신규)
- `Bundle.module` 기반으로 `seoul_subway_station.json`의 `Data`(또는 `URL`)를 반환하는 public 접근자 작성
- 도메인 지식(파싱)은 포함하지 않고 바이트 전달만 담당 (결정 2)
- **완료**: 빌드된 `Resource.framework` 번들 루트에 `seoul_subway_station.json`이 그대로 위치함을 확인(하위 폴더 구조 미보존) → `Bundle.module.url(forResource:withExtension:)`만으로 조회

---

#### [x] Task 8 — `Strings.Common.categorySubway` 추가
**파일**: `Projects/Resource/Sources/Strings/Strings.swift` (기존 파일 수정)
- "지하철" 카테고리 태그용 문자열 상수 추가 (일본어 문구 기준, 기존 `Strings.Common` 네이밍 컨벤션 준수)

---

#### [x] Task 9 — `TabiIcon.subway` 추가
**파일**: `Projects/Resource/Sources/Image/TabiImage.swift` (기존 파일 수정)
- `TabiIcon`에 `case subway = "tram.fill"` 추가

---

#### [x] Task 10 — Tuist 재생성 (신규 리소스 반영)
**파일**: 없음 (빌드 검증 전용)
- `tuist generate` 재실행하여 신규 JSON 리소스와 `.swift` 파일이 stale 프로젝트 오탐 없이 인식되는지 확인
- **완료**: `tuist generate` + `xcodebuild build` BUILD SUCCEEDED

---

### Phase 3. Domain 엔티티 확장

#### [x] Task 11 — `CategoryType`에 `.subway` 케이스 추가
**파일**: `Projects/Domain/Sources/Entity/CategoryType.swift`
- `case subway` 추가
- 추가로 컴파일 에러가 발생하는 5개 지점(결정 4)은 이후 Task 12(Data), Task 34(Presentation Home), Task 43(Presentation Detail)에서 순서대로 처리하므로 이 Task에서는 컴파일 에러 발생 상태를 인지하고 다음 Task로 진행

---

#### [x] Task 12 — `CategoryType+.swift`(Data) exhaustive switch 처리
**파일**: `Projects/Data/Sources/Extension/CategoryType+.swift`
- `apiCode` switch에 `case .subway`를 추가하고 빈 문자열 반환 + `AppLogger.network`로 에러 로깅 (반환 타입은 `String?`로 바꾸지 않음 — `TouristSpotEndpoint` 6개 케이스 영향 방지, 결정 4-1)
- `init?(apiCode:)`는 매핑 추가 없이 `default: return nil` 그대로 유지 (관광공사 코드에 지하철 없음, 결정 4-2)
- **추가 발견 (plan.md 결정 4 누락분)**: `Projects/Data/Sources/DTO/TouristSpotIntro/TouristSpotIntroDTO.swift`의 `TouristSpotIntroItemDTO.toEntity()`에도 `CategoryType` exhaustive switch가 있어 6번째 지점으로 확인·수정 (`.subway` case에서 `TabiError.apiFailed` throw — 이 경로는 `CategoryType(apiCode:)`가 `.subway`를 만들지 않으므로 구조적으로 도달 불가능하지만 컴파일러 요구로 처리)

---

#### [x] Task 13 — `TouristSpot`에 `isStation` + `shouldSkipRemoteDetail` 추가
**파일**: `Projects/Domain/Sources/Entity/TouristSpot.swift`
- `isStation: Bool = false` 저장 프로퍼티 추가 + init 파라미터 추가 (기본값 부여로 기존 호출부 무영향, `isCustom`과 동일 편입 패턴)
- `shouldSkipRemoteDetail`(= `isCustom || isStation`) computed 프로퍼티 추가 (결정 13 — `DetailFeature`의 산재된 `isCustom` 분기 5곳을 이 프로퍼티 기준으로 일반화하기 위함)
- 불변 조건 주석 추가: `isStation`과 `isCustom`은 동시에 `true`가 될 수 없음 (결정 12, 생성 지점은 지하철 매퍼 단 한 곳으로 제한)

---

#### [x] Task 14 — `TravelPlanDetailSpot`에 `isStation` 추가
**파일**: `Projects/Domain/Sources/Entity/TravelPlanDetailSpot.swift`
- `isStation: Bool = false` 추가 (결정 8 — PlanDetailAddSpot으로 추가된 지하철역이 일정 상세에서도 판별 가능하도록)

---

#### [x] Task 15 — 빌드 확인 (기존 호출부 무수정 컴파일)
**파일**: 없음 (빌드 검증 전용)
- Task 11~14 반영 후 빌드하여 기존 `TouristSpot`/`TravelPlanDetailSpot` 생성 호출부가 기본값 덕분에 무수정 컴파일되는지 확인
- **완료**: `xcodebuild build` **BUILD SUCCEEDED**. 진행 중 컴파일 차단으로 Task 34(Presentation Home `CategoryType+.swift`의 icon/color/label, `allItems` 미변경)와 Task 43(`DetailFeature`의 `TouristSpotIntro.empty(for:)`에 `.subway` 추가)을 앞당겨 완료함

---

### Phase 4. Domain 지하철 계층

#### [x] Task 16 — `SubwayStation` 엔티티 (신규)
**파일**: `Projects/Domain/Sources/Entity/SubwayStation.swift` (신규)
- 로컬 JSON 매칭 + 그룹핑 결과를 표현하는 도메인 모델 정의: 역명 한/일, 대표 `station_cd`, `fr_code`, `lineNumbers: [String]`

---

#### [x] Task 17 — `SubwayStationRepositoryProtocol` (신규)
**파일**: `Projects/Domain/Sources/RepositoryProtocol/SubwayStationRepositoryProtocol.swift` (신규)
- 로컬 JSON 검색(동기/비동기)과 서울 열린데이터 API 조회를 분리된 메서드로 정의 (두 책임을 하나의 프로토콜에)

---

#### [x] Task 18 — `SubwayStationUseCaseProtocol` + `SubwayStationUseCase` (신규)
**파일**:
- `Projects/Domain/Sources/UseCase/SubwayStation/SubwayStationUseCaseProtocol.swift` (신규)
- `Projects/Domain/Sources/UseCase/SubwayStation/SubwayStationUseCase.swift` (신규)
- `SubwayStationRepositoryProtocol` + `NaverGeocodingRepositoryProtocol` 2개를 주입받는 구조로 구현 (다중 Repository 주입은 `Projects/Domain/Sources/UseCase/DataReset/DataResetUseCase.swift` 선례 참고)
- 오케스트레이션 순서: 로컬 매칭 → `station_nm` 기준 그룹핑(환승역 통합, 결정 7) → 정렬 후 상위 5건 절단(결정 11) → 서울 API 조회 + Naver Geocoding을 `withTaskGroup`으로 병렬 실행(결정 11) → `TouristSpot` 매핑
- 지오코딩 실패한 역은 결과에서 제외 (spec 명시, `Coordinate.zero` 채우지 않음)
- `TouristSpot` 매핑 시 `isStation: true`, `isCustom`은 전달하지 않음(기본값 `false`, 결정 12) — 이 UseCase가 `isStation: true`를 생성하는 유일한 지점
- **참고**: 그룹핑(환승역 통합)은 `SubwayStationRepositoryProtocol.searchLocal(keyword:)`이 이미 그룹핑된 `[SubwayStation]`을 반환하는 책임으로 설계(Phase 5, Task 21에서 구현) — UseCase는 정렬된 결과의 상위 5건 절단만 담당

---

#### [x] Task 19 — `TestSubwayStationUseCase` (신규)
**파일**: `Projects/Domain/Sources/UseCase/SubwayStation/TestSubwayStationUseCase.swift` (신규)
- `test-style.md` 규칙에 따라 `TestSubwayStationUseCase` 접두사, 프로토콜 채택, 데이터 주입용 `var` 프로퍼티 공개 형태로 작성

---

#### [x] Task 20 — `SubwayStationUseCaseDependencyKey`(testValue) + `DependencyValues` 등록
**파일**:
- `Projects/Domain/Sources/Dependency/Keys/SubwayStationUseCaseDependencyKey.swift` (신규)
- `Projects/Domain/Sources/Dependency/DependencyValues.swift` (기존 파일 수정)
- `TestDependencyKey` 채택 + `testValue`만 정의 (`TestSubwayStationUseCase` 반환)
- `DependencyValues`에 `subwayStationUseCase` 프로퍼티 추가

---

### Phase 5. Data 로컬 JSON

#### [x] Task 21 — `SubwayStationLocalDTO` + 그룹핑/정렬 매핑 (신규)
**파일**: `Projects/Data/Sources/DTO/SubwayStation/SubwayStationLocalDTO.swift` (신규)
- Phase 0에서 확인한 실제 스키마 기준으로 로컬 JSON 로우(`station_nm`, `station_nm_jpn`, `line_num`, `station_cd`, `fr_code`) 디코딩 정의
- `station_nm` 기준 그룹핑 + `SubwayStation` 엔티티로 매핑
- 대표 로우 선정은 `line_num` 오름차순(또는 `station_cd` 오름차순) 정렬 후 첫 로우로 고정 — 검색마다 대표값이 바뀌지 않도록 결정적으로 구현 (결정 7)

---

#### [x] Task 22 — 검색어 정규화 헬퍼 (신규)
**파일**: `Projects/Data/Sources/Extension/SubwayStationSearchNormalizer.swift` (신규)
- 정규화 순서: 앞뒤 공백 제거 → 히라가나→가타카나 변환 → 전각/반각 통일 → 접미사 `駅`/`역`·중점(`・`) 제거 → 대소문자 통일 (결정 6)
- 매칭 방식: prefix 매칭 우선 → contains 매칭 보조로 정렬
- Core의 `String+`(관광공사 응답 정제 전용)와는 분리해 Data 모듈 `Extension/`에 위치

---

#### [x] Task 23 — `SubwayStationRepository` 로컬 검색 + 인메모리 캐시 (신규)
**파일**: `Projects/Data/Sources/Repository/SubwayStation/SubwayStationRepository.swift` (신규)
- `SubwayStationRepositoryProtocol`의 로컬 검색 메서드 구현 — `SubwayStationResource.swift`(Resource)로부터 바이트를 받아 `SubwayStationLocalDTO`로 디코딩
- 앱 수명주기 1회만 파싱해 `actor`(`SubwayStationLocalCache`)로 메모리 캐시 (결정 3), 정규화 결과도 로우별로 미리 계산해 `IndexedSubwayStation`으로 캐시에 함께 저장
- 파일 누락/디코딩 실패 시 `AppLogger.core` 로깅 후 빈 배열 반환

---

#### [x] Task 24 — 로컬 매칭·그룹핑 단위 검증 (네트워크 없이)
**파일**: 없음 (수동/단위 검증 전용, 테스트 타겟 미구성 상태이므로 코드 실행으로 확인)
- 가타카나/히라가나/한국어/환승역/미존재 역 케이스로 로컬 매칭·그룹핑 로직만 검증 (서울 API·지오코딩 연동 전 단계)
- **검증 방법**: Swift 테스트 타겟이 없어 동일 알고리즘을 Python으로 재현해 실제 JSON 데이터(799건)로 검증
- **검증 결과**: 가타카나 정확 매칭 ✅ / 히라가나→가타카나 변환 매칭 ✅ / 한국어 매칭 ✅ / 환승역(서울역: 01호선·04호선·경의선·공항철도) 1건으로 그룹핑 ✅ / 존재하지 않는 역명 0건 ✅ / prefix 우선 정렬("강남" → 강남, 강남구청, 강남대 순) ✅
- **버그 발견 및 수정**: `station_nm_jpn`에 반각 괄호 부가 표기가 섞인 역 4곳 발견(`동대문역사문화공원`→"...(DDP)", `신촌`→"...(新村)", `삼성`→"...(三成)", `신천`→"...(新川)") — 기존 `TouristSpot.koreanTitle`의 전각/반각 괄호 파싱 규칙과 충돌해 `koreanTitle`이 "DDP" 등으로 잘못 파싱되는 버그를 사전에 확인. `SubwayStationUseCase.swift`에 `String.strippingParentheticalSuffix`를 추가해 title 생성 전 반각 괄호 부가 표기를 제거하도록 수정 완료

---

### Phase 6. Data 서울 열린데이터 연동

#### [x] Task 25 — 시크릿 항목 반영 (`Secret.swift` / `Secret.xcconfig.sample` / `Info.plist`)
**파일**:
- `Projects/Data/Sources/Network/Secret/Secret.swift` (기존 파일 수정)
- `Projects/Data/Sources/Secret.xcconfig.sample` (기존 파일 수정, 커밋 대상)
- `Projects/App/Sources/Info.plist` (기존 파일 수정)
- 서울 열린데이터 인증키 프로퍼티를 `Secret.swift`에 추가 (`Bundle.main`으로 Info.plist 값 읽기)
- `Secret.xcconfig.sample`에 신규 키 항목 추가 (템플릿, 실제 값은 미포함)
- `Info.plist`에 `$(...)` 주입 항목 추가
- **주의**: 로컬 `Secret.xcconfig`(gitignored)는 절대 커밋하지 않음
- **완료**: 키 이름 `SEOUL_SUBWAY_API_KEY`로 통일, `Secret.seoulSubwayAPIKey` 프로퍼티 추가

---

#### [x] Task 26 — `SubwayStationEndpoint` (신규)
**파일**: `Projects/Data/Sources/Network/EndPoint/SubwayStationEndpoint.swift` (신규)
- Phase 0에서 확인한 실제 스펙 기준으로 작성 — 인증키를 쿼리가 아닌 `path`에 보간 (결정 10), 역명 URL 인코딩 확인
- 필요 시 `enableLog = false`로 인증키 노출 방지 옵션 고려 (`Endpoint`가 이미 지원)
- **완료**: `enableLog = false` 적용, `.urlPathAllowed`로 역명 percent-encoding

---

#### [x] Task 27 — `SubwayStationSearchResponseDTO` (신규)
**파일**: `Projects/Data/Sources/DTO/SubwayStation/SubwayStationSearchResponseDTO.swift` (신규)
- Phase 0에서 확인한 응답 루트 키 기준으로 `STATION_CD`, `STATION_NM`, `LINE_NUM`, `FR_CODE` 디코딩 정의
- `RESULT.CODE` 성공값 검증 로직 포함
- `toEntities()` 매핑 메서드, 실패 시 `AppLogger.network` 로깅
- **완료**: 커스텀 `init(from:)`으로 성공 시(`SearchInfoBySubwayNameService` 래핑) / 0건 시(`RESULT`만) 두 응답 형태를 모두 디코딩. `toExistsResult()`가 `INFO-000`+row 존재 시 true, `INFO-200`(데이터 없음) 시 false, 그 외 코드는 `TabiError.apiFailed` throw

---

#### [x] Task 28 — `SubwayStationRepository` 서울 API 조회 + 응답 캐시 구현
**파일**: `Projects/Data/Sources/Repository/SubwayStation/SubwayStationRepository.swift` (Task 23에서 이어서 수정)
- `SubwayStationRepositoryProtocol`의 서울 API 조회 메서드 구현 (`NetworkService` 사용)
- 역명 키로 인메모리 캐시해 재검색 시 재호출 방지 (결정 11)
- 실패/타임아웃 시 빈 배열 반환 + `AppLogger.network` 로깅 (spec 명시, 관광지 검색에는 영향 없음)
- **완료**: `SubwayStationConfirmCache`(actor, `[String: Bool]`)로 역명별 확인 결과 캐시. 빌드(`tuist generate` + `xcodebuild`) **BUILD SUCCEEDED**

---

### Phase 7. Data 영속화 스키마

#### [x] Task 29 — `BookmarkModel` / `TravelPlanDetailSpotModel`에 `isStation` 컬럼 추가
**파일**:
- `Projects/Data/Sources/SwiftData/BookmarkModel.swift`
- `Projects/Data/Sources/Extension/BookmarkModel+.swift`
- `Projects/Data/Sources/SwiftData/TravelPlanDetailSpotModel.swift`
- `Projects/Data/Sources/Extension/TravelPlanDetailSpotModel+.swift`
- 각 모델에 `isStation: Bool = false` 컬럼 추가 (기본값 있는 신규 컬럼, 경량 마이그레이션 대상, 결정 9)
- 양방향 매핑(Entity ↔ Model)에 `isStation` 반영

---

#### [x] Task 30 — `TravelPlanShareUseCase.SpotPayload`에 `isStation` 추가
**파일**: `Projects/Domain/Sources/UseCase/TravelPlanShare/TravelPlanShareUseCase.swift`
- `SpotPayload`에 `isStation` 추가 (결정 8)
- **추가 조치**: `SpotPayload`는 일정 내보내기/가져오기(JSON export/import)에도 쓰이는 `Codable` 타입이라, 이 기능 이전에 내보낸 파일에는 `isStation` 키가 없음 — 커스텀 `init(from:)`으로 `decodeIfPresent(...) ?? false` 처리해 하위 호환 확보 (synthesized Decodable을 그대로 뒀다면 구버전 내보내기 파일 가져오기가 깨졌을 것)

---

#### [x] Task 31 — 기존 DB 보존 검증 (경량 마이그레이션)
**파일**: 없음 (수동 검증 전용)
- 스키마 변경 전 상태의 기존 DB가 있는 상태로 앱을 재실행해 기존 북마크·일정 데이터가 유실 없이 보존되는지 확인 (결정 9 — `BookmarkModelContainer`가 생성 실패 시 in-memory로 조용히 폴백하므로 반드시 실기기/시뮬레이터에서 확인)
- **부분 완료**: 새 스키마로 시뮬레이터(iPhone 17)에 설치·실행해 크래시 및 in-memory 폴백 로그 없음을 확인(스크린샷으로 홈 화면 정상 렌더링 확인). **단, 이 세션에는 스키마 변경 전 상태의 실제 데이터가 없어 "기존 데이터 보존" 자체는 재현 검증하지 못함** — 사용자 실기기/시뮬레이터에 기존 북마크·일정이 있다면 Phase 11 최종 검증 시 직접 확인 필요

---

### Phase 8. App DI

#### [x] Task 32 — `SubwayStationUseCaseDependencyKey`(liveValue) (신규)
**파일**: `Projects/App/Sources/Dependency/SubwayStationUseCaseDependencyKey.swift` (신규)
- 동일 타입에 `@retroactive DependencyKey` extension으로 `liveValue` 정의
- `SubwayStationRepository()` + `NaverGeocodingRepository()`(기존 AddCustomPlace에서 사용 중인 구현체 재사용)를 조립해 `SubwayStationUseCase` 생성

---

#### [x] Task 33 — Tuist 재생성 및 빌드
**파일**: 없음 (빌드 검증 전용)
- `tuist generate` 후 빌드 (신규 `.swift` 파일 반영 필수, CLAUDE.md IMPORTANT 규칙)
- **완료**: BUILD SUCCEEDED

---

### Phase 9. Presentation — 검색 통합

#### [x] Task 34 — `CategoryType+.swift`(Presentation Home) exhaustive switch 처리 (Phase 3에서 컴파일 차단으로 선행 완료)
**파일**: `Projects/Presentation/Sources/Home/Model/CategoryType+.swift`
- `icon` switch에 `.subway` → `TabiIcon.subway` 추가
- `color` switch에 `.subway` → `.tabiAccentCoral` 추가
- `label` switch에 `.subway` → `Strings.Common.categorySubway` 추가
- `allItems`에는 `.subway`를 **포함하지 않음** (Home/Map/RegionSpot/Bookmark 4개 카테고리 필터 탭 미노출 AC 충족, 결정 4)

---

#### [x] Task 35 — `MapFeature` 지하철 검색 상태/effect 추가
**파일**: `Projects/Presentation/Sources/Map/MapFeature.swift`
- State에 `subwayResults: [TouristSpot]`를 기존 관광지 결과 배열과 별도로 추가
- 뷰에 노출할 병합 computed 프로퍼티(`subwayResults + spotResults` 형태) 추가 — 지하철 우선 불변 조건을 순서와 무관하게 보장 (결정 5)
- `searchSubmitted`에서 `.merge(관광지 effect, 지하철 effect)`로 동시 실행
- 지하철 effect는 별도 `CancelID`로 `cancelInFlight: true` 적용, `searchCancelTapped`/`resetSearchState`에도 취소 반영
- 다음 페이지 트리거(`spot.id == searchResults.last?.id`)는 관광지 배열 기준으로 유지 (지하철 셀이 페이징을 유발하지 않도록)

---

#### [x] Task 36 — `MapView` 결과 리스트/마커/셀 탭 병합 반영
**파일**: `Projects/Presentation/Sources/Map/MapView.swift`
- 결과 리스트/마커가 병합 배열(Task 35의 computed 프로퍼티)을 보도록 변경
- 셀 탭 시 `searchResults.first(where: id)` 조회를 병합 배열 기준으로 변경
- 페이징 트리거는 관광지 결과 기준 유지 (결정 5)
- **추가 발견**: 빈 상태 판정(`searchResults.isEmpty`)도 병합 배열 기준으로 바꿔야 함 — 관광지 결과가 0건이어도 지하철 결과가 있으면 빈 상태를 보여주면 안 되는 케이스를 놓칠 뻔함

---

#### [x] Task 37 — `MapSearchResultRowView`에 `address` 전달
**파일**: `Projects/Presentation/Sources/Map/Sub/MapSearchResultRowView.swift`
- `TabiSpotRow(address:)` 파라미터 전달 (관광지 결과의 `address`는 `nil`이므로 기존 화면 무회귀, 결정 7)

---

#### [x] Task 38 — `PlanDetailAddSpotFeature` 동일 패턴 적용
**파일**: `Projects/Presentation/Sources/PlanDetailAddSpot/PlanDetailAddSpotFeature.swift`
- `MapFeature`와 동일하게 `subwayResults` 상태 + 지하철 effect/액션 + 병합 computed + 취소/리셋 반영 (결정 5)
- `saveButtonTapped`(또는 해당 저장 액션)에서 `isStation` 전파 (결정 8)
- `PlanDetailAddSpotView.swift`의 `results:` 전달부도 병합 배열로 변경

---

#### [x] Task 39 — `PlanDetailAddSpotSpotRow`에 `address` 전달
**파일**: `Projects/Presentation/Sources/PlanDetailAddSpot/Sub/PlanDetailAddSpotSpotRow.swift`
- `TabiSpotRow(address:)` 파라미터 전달 (결정 7)

---

#### [x] Task 40 — `AddToItineraryFeature`에 `isStation` 전파
**파일**: `Projects/Presentation/Sources/AddToItinerary/AddToItineraryFeature.swift`
- `TravelPlanDetailSpot` 생성부에 `isStation`을 `isCustom`과 나란히 전파 (결정 8 — 일정에서 지하철역을 탭했을 때 관광공사 상세 API가 잘못 호출되는 것을 방지)
- **추가 발견 (plan.md 누락분)**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`의 `path(.element(_, .planDetail(.spotRowTapped)))` 핸들러가 `TravelPlanDetailSpot` → `TouristSpot` 역변환 시 `isCustom`만 넘기고 `isStation`은 누락되어 있었음(결정 8이 실제로 막으려던 버그의 진짜 발생 지점) — `isStation: spot.isStation` 추가로 수정

---

#### [x] Task 41 — `AddCustomPlaceFeature` "지하철" 모드 토글 상태/로직 (결정 1)
**파일**: `Projects/Presentation/Sources/AddCustomPlace/AddCustomPlaceFeature.swift`
- "지하철" 모드 토글 State/Action 추가 (기존 화면 전용 UI 요소, `CategoryType.allItems` 미변경)
- 토글 ON: 주소 TF 관련 상태/액션(`addressSubmitted` 등) 비활성화, 카테고리는 내부적으로 `.subway`로 고정
- 타이틀 TF `onSubmit` 시 `SubwayStationUseCase`로 매칭 파이프라인 실행: 로컬 매칭 → 그룹핑 → 서울 API 조회 → Naver Geocoding
- 매칭 성공: 기존 주소 매칭 성공 시의 지도 미리보기 로직 재사용, `isConfirmEnabled` 활성화
- 매칭 실패/없음: 지도 미리보기 미표시, 저장 버튼 비활성 유지 (에러 얼럿 없음, spec 정책과 동일)
- 저장 시 `TouristSpot(isStation: true, isCustom: false, contentType: .subway, ...)`로 생성해 `bookmarkUseCase.add`에 전달 (결정 12)
- 토글 OFF(기본 모드): 기존 흐름 그대로 유지, 무회귀
- **구현 노트**: 별도로 `TouristSpot`을 재구성하지 않고, `SubwayStationUseCase.search(keyword:)`가 반환하는 이미 완성된 `TouristSpot`(`isStation:true`, 지오코딩된 좌표/주소, 서울 API 실재확인 완료)의 첫 매칭 결과를 그대로 `matchedStation`으로 사용 — MapView/PlanDetailAddSpot과 동일한 UseCase를 재사용해 로직 중복 없음

---

#### [x] Task 42 — `AddCustomPlaceView` "지하철" 모드 토글 UI (결정 1)
**파일**: `Projects/Presentation/Sources/AddCustomPlace/AddCustomPlaceView.swift`
- "지하철" 모드 토글을 카테고리 선택 섹션 바로 앞(주소 섹션 다음)에 추가
- 토글 ON 시 주소 TF 숨김, 타이틀 TF placeholder를 지하철역명 입력 전용으로 교체(별도 TF 신설 아님), 카테고리 칩 섹션 숨김/비활성화
- Task 41의 State/Action과 바인딩
- **구현**: 토글은 `TabiChip`(DesignSystem 기존 컴포넌트 재사용, 신규 컴포넌트 제작 없음)으로 표현, `subwayModeSection()`을 폼 최상단(카테고리 섹션 바로 앞)에 배치. `Strings.AddCustomPlace`에 `subwayModeSectionTitle`/`stationTitlePlaceholder` 2개 문자열 신규 추가

---

### Phase 10. Presentation — Detail 분기

#### [x] Task 43 — `TouristSpotIntro.empty(for:)`에 `.subway` 추가 (Phase 3에서 컴파일 차단으로 선행 완료)
**파일**: `Projects/Presentation/Sources/Detail/DetailFeature.swift`
- `TouristSpotIntro.empty(for:)` switch에 `.subway` 케이스 추가 — 전 필드 `nil`인 `.sightseeing(...)` 플레이스홀더 반환 (결정 4-5)

---

#### [x] Task 44 — `DetailFeature`의 `isCustom` 분기를 `shouldSkipRemoteDetail` 기준으로 교체
**파일**: `Projects/Presentation/Sources/Detail/DetailFeature.swift`
- `State.init`(address/coordinate 구성), `hasReceivedAllResults`, `loadFailed`, `onAppear`(원격 상세 API effect 스킵) 총 4곳의 `isCustom` 분기를 `TouristSpot.shouldSkipRemoteDetail`(Task 13에서 추가) 기준으로 일반화 (결정 13)
- 지하철역 결과 확인: `detail.address`에 저장 주소(호선 포함) 노출, `intro` 전 필드 `nil`로 `DetailInfoRow` 주소 행만 남음, `images` 비어 photos 탭 자동 제외, map 탭은 유효 좌표로 정상 동작 — 관광공사 API 호출 0건
- **추가 발견 (plan.md 누락분)**: `addBookmarkEffect`(Detail 화면에서 저장 버튼으로 북마크할 때)가 `TouristSpot`을 재구성하며 `isCustom`만 넘기고 `isStation`은 누락 — 지하철역 상세화면에서 직접 북마크하면 플래그가 유실될 뻔한 버그를 발견해 `isStation: spot.isStation` 추가로 수정

---

#### [x] Task 45 — `DetailView` 지하철역 화면 확인 및 최소 수정
**파일**: `Projects/Presentation/Sources/Detail/DetailView.swift`
- 커스텀 뱃지 조건이 `isCustom` 기준이므로 지하철역에는 뱃지가 붙지 않음을 실제 화면으로 확인
- 지하철역 전용으로 숨기거나 손봐야 할 요소가 남았는지 확인 후 필요 시 최소 수정
- **완료**: `isCustom` 기준 그대로 유지(의도된 동작, 코드 수정 없음)

---

### Phase 11. 빌드 / 검증

#### [x] Task 46 — 최종 Tuist 재생성 및 빌드
**파일**: 없음 (빌드 검증 전용)
- `tuist install && tuist generate` 후 빌드 (설치된 시뮬레이터 기기 사용)
- **완료**: `tuist install` + `tuist generate` + `xcodebuild build`(AppDebug, iPhone 17) **BUILD SUCCEEDED**

---

#### [~] Task 47 — 시나리오 전수 검증 (부분 완료 — 아래 "검증 한계" 참고)
**파일**: 없음 (수동 검증 전용)
- 가타카나 입력 / 한국어 입력 / 히라가나 입력 / 환승역 / 미존재 역 케이스 검증
  - **완료**: 실제 번들 JSON(799건)으로 동일 매칭·그룹핑 알고리즘을 Python 재현 검증(Task 24 참고) — 전부 통과. **단, 앱 UI를 통한 실제 검색 입력 E2E는 아래 한계로 미완료**
- 서울 API 강제 실패 / 지오코딩 실패 시 관광지 검색 정상 진행 확인 — **미검증** (코드 상 실패 시 빈 배열 반환 + 로깅으로 관광지 검색과 분리되어 있음을 정적 확인만 함)
- MapView 검색 / AddCustomPlace 지하철 모드 / PlanDetailAddSpot 스팟 검색 3개 화면 각각 검증 — **미검증** (아래 한계 참고)
- 북마크 저장 · 목록 · 상세 확인 — **미검증**
- 일정에 지하철역 추가 후 일정 상세에서 역 탭 → 관광공사 API 미호출 확인 (결정 8 회귀 검증) — **미검증** (단, 코드 경로상 `TabBarFeature`의 `isStation` 전파 버그를 발견·수정했으므로 정적으로는 안전)
- Home/Map/RegionSpot/Bookmark 카테고리 필터 탭 4곳에 "지하철" 미노출 확인
  - **완료**: 시뮬레이터에서 Home 화면 카테고리 행을 실제로 확인 — 観光地/飲食店/宿泊/お祭り/ショッピング/自然 6개만 노출, 地下鉄 없음 (스크린샷 확인)
- 앱 재실행 후 기존 데이터 보존 확인 — **부분 완료** (Task 31 참고: 새 스키마로 크래시·폴백 없이 기동은 확인, 기존 데이터 보존 자체는 이 세션에 재현 데이터가 없어 미검증)

**검증 한계(중요)**: 이 환경에는 XCUITest 타겟이 없고, `idb`(Facebook iOS debug bridge)로 시뮬레이터 UI 자동화를 시도했으나 **일본어/한국어(비ASCII) 텍스트 입력이 안정적으로 동작하지 않음**을 확인함 — `idb ui text`는 하드웨어 키코드 기반이라 비ASCII 문자에서 즉시 예외 발생, pasteboard 붙여넣기(`xcrun simctl pbcopy`)로 우회 시도했으나 롱프레스 Paste 메뉴가 뜨지 않았고 ASCII 텍스트("gangnam")조차 검색 필드에 입력되지 않음(placeholder 그대로 유지, 네트워크 로그에도 검색 트리거 없음) — 원인 미상. 따라서 **지하철역 검색이 실제 화면에서 동작하는지는 사용자가 직접 확인 필요**. 코드 레벨(빌드 성공, 로컬 매칭 알고리즘 실데이터 검증, Seoul API 실제 호출 검증, 정적 코드 추적)로는 정상 동작할 것으로 판단되나 UI 통합 동작은 보증하지 못함

---

#### [~] Task 48 — 네트워크 로그로 관광공사 API 호출 0건 확인 (미검증)
**파일**: 없음 (수동 검증 전용)
- 지하철역 Detail 진입 시 Xcode 네트워크 로그에서 관광공사 상세 API 호출이 0건인지 확인
- **미검증**: Task 47과 동일한 이유로 지하철역 검색결과 자체를 UI에서 만들어내지 못해 Detail 진입까지 도달 못함. 코드 추적으로는 `shouldSkipRemoteDetail`(=`isStation`) 체크가 `onAppear`의 `fetchDetailEffect`/`fetchIntroEffect`/`fetchImagesEffect` 호출 전체를 스킵하도록 되어 있어 구조적으로 API 호출 0건이 보장됨

---

## 체크리스트

### 품질 (DoD)
- [x] 빌드 성공 (`tuist generate` 후 `xcodebuild build`)
- [x] `DependencyInformation` 의존성 방향 위반 없음 (Domain은 Data 미참조, liveValue 조립은 App에서만)
- [x] 신규 `.swift`/리소스 추가 후 `tuist generate` 실행하여 stale 프로젝트 오탐 없이 빌드 성공
- [x] `Secret.xcconfig`는 커밋되지 않고 `Secret.xcconfig.sample`에만 신규 키 항목 반영
- [x] 테스트 타겟 미구성 상태이므로 별도 테스트 코드 작성 없음 (구성 시 `test-style.md` 규칙 적용)
- [x] `swift-code-reviewer` 전체 리뷰 완료, 발견된 WARNING 3건(비결정적 정렬, cancellation 오탐 로깅, AddCustomPlace 레이스 컨디션) 전부 수정 및 재빌드 확인

### 기능 (AC)
> UI 자동화 한계로 아래 항목은 구현·정적 검증까지만 완료. 상세는 Task 47/48 참고, 최종 사용자 확인 필요

- [ ] MapView 검색 TF에 가타카나/한국어 역명 입력 시 최상단에 지하철역 노출 (구현 완료, UI 검증 필요)
- [ ] AddCustomPlace, PlanDetailAddSpot(스팟 검색)에서도 동일하게 지하철역 검색결과 표시 (구현 완료, UI 검증 필요)
- [ ] 검색결과 셀에 "지하철" 카테고리 태그(`tram.fill` 아이콘, `tabiAccentCoral` 색상) 표시 (구현 완료, UI 검증 필요)
- [ ] 환승역(여러 호선)이 중복 없이 1개 항목으로 표시되고 호선 정보 확인 가능 (그룹핑 로직 실데이터 검증 완료, UI 검증 필요)
- [ ] 검색된 지하철역을 북마크에 저장 가능 (구현 완료, UI 검증 필요)
- [ ] 북마크 목록/상세화면에서 저장된 지하철역 확인 가능 (구현 완료, UI 검증 필요)
- [ ] 지하철역 DetailView 진입 시 역명과 주소만 표시, 관광공사 API 상세 호출 미발생 (코드상 구조적 보장, 실기기 로그 확인 필요)
- [x] Home/Map(및 RegionSpot/Bookmark) 카테고리 필터 탭에 "지하철" 미노출 (시뮬레이터 실확인 완료)
- [ ] 불변 조건: 지하철 결과가 항상 관광지 결과보다 앞 / 역명 중복 없음 / `isStation`과 `isCustom` 동시 true 불가 (코드 리뷰로 정적 검증, UI 검증 필요)
- [ ] 실패 경로: 매칭 0건·서울 API 실패·지오코딩 실패 시 관광지 검색은 정상 진행, `AppLogger.network` 로깅 (코드 리뷰로 정적 검증, UI 검증 필요)
- [ ] 기존 북마크·일정이 스키마 변경 후에도 유실 없이 유지 (경량 마이그레이션 검증) — 새 스키마 정상 기동만 확인, 기존 데이터 보존 자체는 미검증
- [ ] 일정에 추가한 지하철역을 일정 상세에서 탭했을 때 관광공사 API 미호출 (결정 8 회귀 검증) — `TabBarFeature`의 `isStation` 누락 버그를 코드 리뷰로 발견·수정, UI 검증 필요
</content>

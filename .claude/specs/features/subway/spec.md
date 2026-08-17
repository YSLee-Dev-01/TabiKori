# subway

## 무엇을 하는가
일본어(가타카나) 발음이나 한국어로 지하철역명을 입력해도 검색할 수 있도록, MapView 검색·AddCustomPlace 검색·PlanDetailAddSpot(스팟 검색)의 기존 통합 검색 TF에 지하철역 검색 결과를 함께 노출한다. 지하철역 검색 결과는 관광지 검색 결과보다 항상 먼저 표시되며, 북마크 저장과 상세화면 진입도 지원한다.

## 동작 명세
- 트리거: 기존 통합 검색 TF(MapView 검색 / AddCustomPlace 검색 / PlanDetailAddSpot 스팟 검색)에서 텍스트 입력 후 검색 실행 — 새로운 버튼/화면 없이 기존 검색 액션(`searchSubmitted` 등)을 그대로 사용
- 결과:
  - 검색어를 로컬 번들 JSON(서울교통공사 노선별 지하철역 정보: `station_nm`, `station_nm_jpn`, `line_num`, `station_cd`, `fr_code`)의 `station_nm_jpn`(가타카나) 또는 `station_nm`(한국어)과 대조해 매칭되는 로우를 찾는다
  - 매칭된 로우를 `station_nm` 기준으로 그룹핑해 환승역(같은 역명, 여러 `line_num`)을 1개 결과로 통합하고, 호선 목록은 함께 보관한다
  - 통합된 역명으로 서울 열린데이터 광장 `SearchInfoBySubwayNameService` API(응답 필드: `STATION_CD`, `STATION_NM`, `LINE_NUM`, `FR_CODE` — 로컬 JSON의 `station_cd`/`fr_code`와 동일 키로 매칭 가능)를 조회한다
  - 지하철역 검색 결과를 최대 5개까지 검색결과 리스트 최상단에 배치하고, 그 아래 기존 관광지 키워드 검색 결과를 이어서 표시한다
  - 검색결과 셀(`TabiSpotRow`)의 카테고리 태그는 "지하철"로 표시한다 (아이콘 `tram.fill`, 색상 `tabiAccentCoral` 재사용 — 신규 컬러 asset 없이 기존 토큰 재사용)
  - Naver Geocoding(기존 AddCustomPlace에서 사용 중인 UseCase 재사용)에 `"{line_num} {station_nm}역"` 텍스트로 주소를 조회해 좌표와 주소 문자열을 얻는다
  - 지하철역은 `TouristSpot`에 `isStation: Bool` 플래그를 추가해 표현한다 (`isCustom`과 동일한 편입 패턴)
- 사이드이펙트: 로컬 JSON 파싱, 서울 열린데이터 API 호출, Naver Geocoding API 호출
- 불변 조건:
  - 지하철역 검색 결과는 항상 관광지 검색 결과보다 앞에 표시된다
  - 동일 검색 결과 내에서 같은 역명이 중복 표시되지 않는다 (환승역은 역명당 1개)
  - `isStation`이 `true`인 `TouristSpot`은 `isCustom`과 동시에 `true`가 될 수 없다

## 무엇이 잘못될 수 있는가
- 검색어가 로컬 JSON의 `station_nm_jpn`/`station_nm` 어디에도 매칭되지 않음 → 지하철역 결과 없이 기존 관광지 검색만 정상 진행 (에러 아님)
- 서울 열린데이터 API 요청 실패/타임아웃 → 지하철역 검색 결과만 스킵, 관광지 검색은 정상 진행, `AppLogger.network`로 로그
- Naver Geocoding에서 좌표를 찾지 못함 → 해당 지하철역은 검색 결과에서 제외 (좌표 없는 상태로 노출하지 않음)
- 로컬 JSON에 없는 신규/개통 역 → 검색 불가 (데이터 최신화는 이번 기능 범위 밖)

## 무엇에 의존하는가
### 의존성
- 서울 열린데이터 광장 `SearchInfoBySubwayNameService` API — 인증키 필요, `Secret.xcconfig`에 신규 키 추가
- 로컬 JSON 번들 리소스 (서울교통공사_노선별 지하철역 정보) — 프로젝트 내 최초의 로컬 JSON 파싱 사례, Resource 모듈에 추가
- 기존 Naver Geocoding UseCase (AddCustomPlace 재사용)
- 기존 `TouristSpot` Entity, `CategoryType` Entity, `BookmarkModel`(SwiftData), `DetailFeature`의 `isCustom` 스킵 패턴

### 제약
- `CategoryType`에 `subway` 케이스를 추가하되, 관광공사 `apiCode` 매핑(`Data/Sources/Extension/CategoryType+.swift`의 `apiCode`/`init?(apiCode:)`)에는 포함하지 않는다 — 지하철은 관광공사 API 대상이 아님
- Home/Map 카테고리 필터 탭에는 "지하철" 카테고리를 노출하지 않는다 (서울 API가 주변 반경 검색을 지원하지 않아 기존 `fetchNearbySpots` 흐름 재사용 불가, 검색결과 뱃지 용도로만 사용)
- `BookmarkModel`(SwiftData) 스키마에 `isStation` 필드 추가 시 라이트웨이트 마이그레이션으로 처리 (기존 데이터 삭제 없음)
- 지하철역 DetailView는 역명과 주소만 표시하고, 관광공사 상세 API 호출은 스킵한다 (`isCustom` 커스텀 장소와 동일한 패턴)
- 서울 열린데이터 API 인증키는 `Secret.xcconfig`(gitignored)와 `Secret.xcconfig.sample`(커밋 대상, 템플릿)에 신규 항목으로 추가

## Acceptance Criteria
> 아래 [x] 표시는 구현·정적 코드 검증(빌드 성공, 실데이터 매칭 로직 재현 검증, Seoul API 실호출 검증)까지 완료된 항목이다. 시뮬레이터 UI 자동화(`idb`)로 실기기 조작 검증을 시도했으나 일본어/한국어 텍스트 입력이 안정적으로 동작하지 않아(비ASCII 키코드 미지원, 붙여넣기도 실패) **검색 흐름 자체의 UI 조작 검증은 완료하지 못했다** — 사용자가 실제 기기/시뮬레이터에서 직접 확인 필요
- [ ] MapView 검색 TF에 일본어(가타카나) 또는 한국어로 지하철역명을 입력하면 검색결과 최상단에 매칭된 지하철역이 표시된다 (구현 완료, UI 검증 필요)
- [ ] AddCustomPlace 검색, PlanDetailAddSpot(스팟 검색) TF에서도 동일하게 지하철역 검색결과가 표시된다 (구현 완료, UI 검증 필요)
- [ ] 검색결과 셀에 "지하철" 카테고리 태그(`tram.fill` 아이콘, `tabiAccentCoral` 색상)가 표시된다 (구현 완료, UI 검증 필요)
- [ ] 환승역(여러 호선)은 검색결과에 중복 없이 1개 항목으로 표시되고 호선 정보를 확인할 수 있다 (그룹핑 로직은 실데이터로 검증 완료, 화면 표시 UI 검증 필요)
- [ ] 검색된 지하철역을 북마크에 저장할 수 있다 (구현 완료, UI 검증 필요)
- [ ] 북마크 목록/상세화면에서 저장된 지하철역을 확인할 수 있다 (구현 완료, UI 검증 필요)
- [ ] 지하철역 DetailView 진입 시 역명과 주소만 표시되고 관광공사 API 상세 호출은 발생하지 않는다 (코드상 `shouldSkipRemoteDetail`로 구조적 보장, 실기기 네트워크 로그 확인 필요)
- [x] Home/Map 카테고리 필터 탭에는 "지하철" 카테고리가 노출되지 않는다 (시뮬레이터에서 Home 화면 실제 확인 완료 — 観光地/飲食店/宿泊/お祭り/ショッピング/自然 6개만 노출)

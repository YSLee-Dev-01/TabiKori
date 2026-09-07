# bookmark_custom_place

## 무엇을 하는가
Bookmark 화면에서 한국관광공사 API 검색 결과뿐 아니라 사용자가 직접 입력한 장소(커스텀 장소)도 북마크로 저장할 수 있게 한다. API에 없는 개인 장소(집, 숙소, 지인 추천 장소 등)도 다른 북마크와 동일하게 목록/필터/삭제·상세보기가 가능하도록 한다.

## 동작 명세
- 트리거: Bookmark 화면(또는 지정 진입점)에서 "커스텀 장소 추가" 버튼 탭
- 결과:
  - 카테고리(`CategoryType`) 선택 + 타이틀 입력 + 주소 입력 폼 표시
  - 저장 버튼 탭 시 주소를 Naver Geocoding API로 좌표(`Coordinate`) 변환
  - 변환 성공 시 `TouristSpot(isCustom: true, address: ...)`를 생성해 기존 `BookmarkUseCase.add(spot)`를 그대로 호출 → SwiftData에 저장되고 Bookmark 목록에 즉시 반영(기존 정렬/로직 재사용)
  - Bookmark 목록의 카테고리 필터, 스와이프 삭제는 기존 로직 그대로 커스텀 장소에도 적용됨
  - 커스텀 장소의 Cell을 탭해 상세화면 진입 시, 관광공사 상세조회 API 호출 없이 저장된 필드(title/address/category/coordinate)만으로 렌더링
- 사이드이펙트: Naver Geocoding API 네트워크 호출(주소→좌표), SwiftData write(`BookmarkModel`에 `isCustom`/`address` 컬럼 포함 저장)
- 불변 조건: 커스텀 장소의 `id`는 기존 API contentId와 절대 충돌하지 않음(prefix로 구분), 좌표 변환에 실패하면 북마크는 저장되지 않음(부분 저장 없음)

## 무엇이 잘못될 수 있는가
- 주소로 좌표를 찾을 수 없음(Naver Geocoding 결과 0건) → 에러 안내, 저장 취소
- Naver Geocoding 네트워크 실패(타임아웃, 인증 실패 등) → 에러 안내, `AppLogger.network` 로깅, 저장 취소
- 타이틀/주소 미입력 상태로 저장 시도 → 저장 버튼 비활성 또는 유효성 에러 (구체적 UX는 plan 단계에서 결정)
- 커스텀 장소 상세화면에서 관광공사 API 전용 UI 요소가 그대로 노출되면 안 됨 → DetailFeature/DetailView에서 `isCustom` 분기 필요

## 무엇에 의존하는가
### 의존성
- Domain: `TouristSpot`에 `isCustom: Bool`, `address: String?` 필드 추가 (기존 필드는 유지)
- Domain: 신규 `NaverGeocodingUseCaseProtocol`/`NaverGeocodingUseCase`, `testValue`
- Data: 신규 `NaverGeocodingRepository`, Endpoint, DTO (Naver Geocoding API 응답 매핑)
- Data: `BookmarkModel`(SwiftData)에 `isCustom`, `address` 컬럼 추가 + `BookmarkModel+.swift` 매핑 갱신
- App: `NaverGeocodingUseCaseDependencyKey`의 `liveValue` 등록, `Secret.xcconfig`/`Secret.xcconfig.sample`에 신규 키 항목 추가 (NCP 콘솔에서 Geocoding 제품 활성화는 사용자가 별도로 진행)
- Presentation: 신규 입력 폼 Feature/View (카테고리 선택 + 타이틀/주소 TextField) — DesignSystem 기존 컴포넌트(`TabiTextField` 등) 우선 재사용
- Presentation: `DetailFeature`/`DetailView`에 `isCustom` 분기 추가 (기존 상세조회 API 호출 스킵)
- Presentation: `BookmarkView`(또는 다른 진입점)에 "커스텀 장소 추가" 진입 버튼 추가

### 제약
- 기존 `TouristSpot`은 한국관광공사 API 전용 엔티티로 설계되어 있었음 — `isCustom`/`address` 추가로 의미가 확장되므로, 필드 추가가 기존 API 매핑 코드(`TouristSpotDTO+`, `BookmarkModel+`)에 영향 없는지 plan 단계에서 확인 필요
- Naver Geocoding API는 이 프로젝트에서 첫 도입(기존 NaverMap SDK의 `searchPlace`는 외부 앱을 여는 딥링크 방식이라 재사용 불가) — 신규 API 키/시크릿 관리 필요
- `BookmarkModel`(SwiftData) 스키마 변경(컬럼 추가) — 기존 로컬 DB에 저장된 데이터와의 마이그레이션 방식은 plan 단계에서 결정
- 커스텀 장소는 썸네일 이미지가 없음(`thumbnailURLString: nil`) — 기존 Cell/Detail UI가 썸네일 nil 상태를 이미 지원하는지 plan 단계에서 확인
- 커스텀 장소의 `distanceMeters` 표시 가능 여부(현재 위치 기반 거리 계산이 API 목록 전용 로직인지) plan 단계에서 확인

## Acceptance Criteria
- [x] Bookmark 화면(또는 지정 진입점)에서 "커스텀 장소 추가" 버튼으로 카테고리/타이틀/주소 입력 폼에 진입할 수 있다
- [x] 유효한 주소를 입력 후 저장하면 Naver Geocoding으로 좌표가 변환되어 Bookmark 목록에 즉시 나타난다
- [ ] 좌표를 찾을 수 없는 주소를 입력하면 에러가 안내되고 저장되지 않는다
- [ ] 커스텀 장소도 기존 API 기반 북마크와 동일하게 카테고리 필터링, 스와이프 삭제가 동작한다
- [ ] 커스텀 장소를 탭해 상세화면에 진입하면 관광공사 API 호출 없이 저장된 정보만으로 화면이 렌더링된다
- [ ] 앱을 재실행해도 커스텀 장소가 유지된다

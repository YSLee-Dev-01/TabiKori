# Plan: bookmark_custom_place

## 참조 Spec
- @specs/features/bookmark_custom_place/spec.md

## 참조 Skill
신규 화면 생성 시
- @skills/create-feature/SKILL.md
  - (현재 레포에 `create-feature` 스킬 파일은 존재하지 않음. 신규 Feature/View 작성은 기존 선례인 `AddTravelPlanFeature`/`AddTravelPlanView` 구조를 그대로 따른다)

---

## 현재 상태 파악

### 신규
- **Domain**
  - `RepositoryProtocol/NaverGeocodingRepositoryProtocol.swift` — 주소 → 좌표 변환 프로토콜
  - `UseCase/NaverGeocoding/NaverGeocodingUseCase.swift`, `NaverGeocodingUseCaseProtocol.swift`, `TestNaverGeocodingUseCase.swift`
  - `Dependency/Keys/NaverGeocodingUseCaseDependencyKey.swift` (testValue)
- **Data**
  - `Network/EndPoint/NaverGeocodingEndpoint.swift`
  - `DTO/NaverGeocoding/NaverGeocodingResponseDTO.swift` (+ `addresses` 아이템 DTO, `toEntity()` 매핑)
  - `Repository/NaverGeocoding/NaverGeocodingRepository.swift`
- **App**
  - `Dependency/NaverGeocodingUseCaseDependencyKey.swift` (liveValue)
- **Presentation**
  - `AddCustomPlace/AddCustomPlaceFeature.swift`, `AddCustomPlaceView.swift`
  - `AddCustomPlace/Sub/` — 카테고리 선택 그리드(또는 칩 로우), 하단 CTA 등 서브 뷰 (body 50줄 초과 시 분리)
- **Resource**
  - `Strings.swift`에 `Strings.AddCustomPlace` 네임스페이스 신설 (화면 타이틀, 타이틀/주소 placeholder, 저장 버튼, 좌표 변환 실패 알럿 문구 등) — 기존 파일 수정

### 재사용
- `TouristSpot`, `Coordinate`, `CategoryType`, `Bookmark`(Domain) — 커스텀 장소도 동일 엔티티로 표현
- `BookmarkUseCase.add(_:)` / `fetch()` / `remove(contentId:)` — 수정 없이 그대로 사용
- `BookmarkFeature`의 `filteredBookmarks`(카테고리 필터), `deleteSwiped`(스와이프 삭제) — 수정 없이 커스텀 장소에도 적용됨
- `TabiSpotRow` — 썸네일 `nil`이면 `KFImage.placeholder`(mappin 아이콘)로 폴백하므로 커스텀 장소용 별도 셀 불필요 (확인 완료)
- `BookmarkView`가 `TabiSpotRow(distance: nil)`로 고정 호출 → 커스텀 장소의 `distanceMeters` 미지원 이슈 없음 (확인 완료)
- `TabiTextField`(placeholder/text/maxLength), `TabiButton`, `TabiChip`, `TabiLabel`, `TabiNavigationBar`, `TabiGlassIconButton`, `TabiColor`, `TabiRadius`
- `CategoryType+`(Presentation) — `label` / `color` / `icon` / `allItems`
- `AddTravelPlanFeature` 패턴 — `BindableAction` + `isConfirmEnabled` computed + `@Presents var alert` + `@Dependency(\.dismiss)` + `saveResult(Bool)` 구조를 그대로 차용
- `PlanView`의 `.sheet(item: $store.scope(...))` 패턴 — 신규 폼 화면 표시 방식
- `NetworkService` / `Endpoint` / `NetworkError` / `AppLogger.network` — Geocoding 호출에 재사용
- `TabiError.dataNotFound` — Geocoding 결과 0건 표현에 재사용 (신규 케이스 불필요)

### 수정
- `Domain/Entity/TouristSpot.swift` — `isCustom: Bool`, `address: String?` 저장 프로퍼티 + init 파라미터 추가 (기본값 부여, 기술 결정 1)
- `Domain/Dependency/DependencyValues.swift` — `naverGeocodingUseCase` 프로퍼티 추가
- `Data/SwiftData/BookmarkModel.swift` — `isCustom: Bool`, `address: String?` 컬럼 추가
- `Data/Extension/BookmarkModel+.swift` — `toDomain` / `convenience init(spot:savedAt:)` 양방향 매핑에 두 필드 반영
- `Data/Network/EndPoint/Protocol/EndPoint.swift` — `headers: [String: String]` 요구사항 + 기본 구현 `[:]` 추가 (기술 결정 4)
- `Data/Network/Service/NetworkService.swift` — `URLRequest`에 `endPoint.headers` 적용
- `Data/Network/Secret/Secret.swift` — Geocoding 인증용 키 프로퍼티 추가
- `Data/Sources/Secret.xcconfig.sample` — Geocoding 관련 키 항목 추가 (`Secret.xcconfig` 실제 값은 사용자가 직접 기입, 커밋 금지)
- `App/Info.plist` — Geocoding 키를 `$(...)`로 주입하는 항목 추가
- `Presentation/Bookmark/BookmarkFeature.swift` — `@Presents var addCustomPlaceState`, `addCustomPlaceButtonTapped`, `addCustomPlace(PresentationAction<...>)` 추가, 저장 완료 시 목록 리로드
- `Presentation/Bookmark/BookmarkView.swift` — 상단에 "커스텀 장소 추가" 진입 버튼 + `.sheet` 연결
- `Presentation/Detail/DetailFeature.swift` — `isCustom` 분기: 상세/소개/이미지 API 호출 스킵, 저장된 필드로 `detail` 구성, shareText 별도 생성
- `Presentation/Detail/DetailView.swift` — 커스텀 장소일 때 관광공사 전용 UI 비노출 처리 (기술 결정 7)
- `Tuist/ProjectDescriptionHelpers` / `Project.swift` — 수정 불필요 (신규 모듈·의존성 없음, `.swift` 파일 추가만 있으므로 `tuist generate`만 필요)

### 삭제
- 없음

---

## 기술적 결정사항

- **[결정 1] `TouristSpot`에 `isCustom`/`address`를 기본값 있는 init 파라미터로 추가 (별도 엔티티 신설 대신)**
  - 이유: spec의 핵심 요구가 "기존 `BookmarkUseCase.add(spot)`를 그대로 호출"이다. 별도 `CustomPlace` 엔티티를 만들면 `Bookmark` → `BookmarkModel` → 목록 필터/셀/Detail 전 경로가 이중 분기되어 비용이 크다.
  - `init(..., isCustom: Bool = false, address: String? = nil)`로 기본값을 주면 기존 호출부 5곳(`TouristSpotDTO.toEntity()`, `FestivalDTO`, `BookmarkModel+.toDomain`, `DetailView` Preview, `AddToItineraryView` Preview)이 **무수정으로 컴파일**된다. spec 제약 "필드 추가가 기존 API 매핑 코드에 영향 없는지 확인"에 대한 답 = 기본값 부여 시 영향 없음(확인 완료).
  - `address`는 커스텀 장소 전용 저장소이며, API 기반 spot의 주소는 기존대로 `TouristSpotDetail.address`(상세조회 응답)에서 온다. 두 경로를 섞지 않는다.
  - `Equatable`/`Sendable`/`Identifiable` 채택은 저장 프로퍼티 추가만으로 자동 유지된다.

- **[결정 2] 커스텀 장소 ID 규칙 → `"custom_" + UUID().uuidString`**
  - 이유: 관광공사 `contentId`는 숫자 문자열이므로 `custom_` 접두사가 붙은 ID와 절대 충돌하지 않는다(spec 불변 조건). `BookmarkModel.contentId`는 `@Attribute(.unique)`라 중복 insert도 DB 레벨에서 차단된다.
  - 단, **분기 판정은 접두사 파싱이 아니라 저장된 `isCustom` 필드로 한다.** 접두사는 ID 충돌 방지용 보조 장치이며 판정 로직에 문자열 파싱을 끌어들이지 않는다.

- **[결정 3] SwiftData 스키마 변경 → 경량 마이그레이션 (VersionedSchema 미도입)**
  - 추가되는 건 `address: String?`(옵셔널)과 `isCustom: Bool`(프로퍼티 선언 시 `= false` 기본값 부여) 두 개뿐이며, 삭제·개명·타입 변경이 없으므로 SwiftData 자동 경량 마이그레이션 범위다. `VersionedSchema` + `SchemaMigrationPlan` 도입은 과잉이라 판단.
  - **주의**: `BookmarkModelContainer`는 컨테이너 생성 실패 시 in-memory로 폴백하는 구조라, 마이그레이션이 실패하면 사용자 기존 북마크가 조용히 전부 사라진 것처럼 보인다. 구현 후 **기존 DB가 있는 상태에서 앱을 업데이트 실행해 기존 북마크가 유지되는지 반드시 실기기/시뮬레이터로 검증**한다(완료 조건 포함). 실패하면 그때 `VersionedSchema` 도입을 재검토.

- **[결정 4] Naver Geocoding 인증 → `Endpoint` 프로토콜에 `headers` 추가 (URLSession 직접 호출 대신)**
  - 이유: 현재 `Endpoint`에는 헤더 개념이 없고 `NetworkService.request`도 `httpMethod`/`timeoutInterval`만 설정한다(확인 완료). Naver Geocoding은 인증 정보를 쿼리가 아닌 **HTTP 헤더**로 요구하므로 그대로는 호출할 수 없다.
  - `Endpoint`에 `var headers: [String: String] { get }`를 추가하고 extension에 기본 구현 `[:]`을 두면, 기존 `TouristSpotEndpoint`/`FestivalEndpoint`는 **선언 변경 없이** 그대로 동작한다. `NetworkService`는 `request.allHTTPHeaderFields = endPoint.headers` 한 줄만 추가.
  - 대안: Repository에서 `URLSession`을 직접 쓰기 → 기존 로깅/상태코드 처리/에러 매핑이 중복되고 레이어 일관성이 깨져 기각.

- **[결정 5] 시크릿 키 — 사용자 확인 완료 (Phase 0 종료)**
  - 현재 `Secret.swift`는 `TOUR_API_KEY`, `NMFNcpKeyId`(= `Info.plist`에서 `$(NAVERMAP_CLIENT_ID)`)만 읽는다. `Secret.xcconfig.sample`에는 `TOUR_API_KEY`만 있고 `NAVERMAP_CLIENT_ID`는 누락돼 있다(확인 완료 — 이번에 함께 보정).
  - **확정 1 — 엔드포인트**: `https://maps.apigw.ntruss.com/map-geocode/v2/geocode` (GET). 공식 문서 페이지마다 `naveropenapi.apigw.ntruss.com`(구버전)/`maps.apigw.ntruss.com`(VPC 신버전) 두 호스트가 혼재해 있었음 — 구버전 호스트로 최초 구현 시 Client ID/Secret·Geocoding 구독 체크가 전부 정상인데도 `errorCode 210 Permission Denied`가 발생, VPC 신버전 호스트로 교체 후 실기 테스트로 정상 동작 확인 완료(2026-08-06). 이 Application이 NCP 콘솔에서 VPC 환경으로 등록되어 있어 VPC 신버전 호스트를 써야 했던 것으로 추정.
  - **확정 2 — 인증**: 기존 Maps Application을 그대로 재사용. Client ID는 기존 `NAVERMAP_CLIENT_ID`(`Secret.naverMapClientID`)를 재사용하고, Client Secret만 신규로 `NAVER_GEOCODING_CLIENT_SECRET` 키를 `Secret.xcconfig`에 추가(총 2개 값 — 별도의 `NAVER_GEOCODING_CLIENT_ID` 키는 불필요하여 제거함):
    - `Secret.naverMapClientID`(기존 `NAVERMAP_CLIENT_ID` 재사용) → 요청 헤더 `x-ncp-apigw-api-key-id`
    - `NAVER_GEOCODING_CLIENT_SECRET`(신규) → 요청 헤더 `x-ncp-apigw-api-key`
    - 그 외 필수 헤더: `Accept: application/json`
  - **확정 3 — 요청 파라미터**: 쿼리 파라미터 `query`(필수, 주소 문자열). `coordinate`/`filter`/`language`/`page`/`count`는 선택이며 이번 스코프에서는 `query`만 사용.
  - **확정 4 — 응답 스키마**: `{ status, meta: { totalCount, page, count }, addresses: [{ roadAddress, jibunAddress, englishAddress, addressElements: [...], x(경도, String), y(위도, String), distance }], errorMessage }`. 좌표는 `x`=경도, `y`=위도이며 `String` 타입이므로 DTO에서 `Double` 파싱 필요. 결과 0건이면 `addresses`가 빈 배열로 온다(공식 예시는 없으나 `meta.totalCount == 0` 및 배열 비어있음 기준으로 판단). HTTP/status 코드: `OK`(200), `INVALID_REQUEST`(400), `SYSTEM_ERROR`(500).
  - 반영 대상: `Secret.xcconfig.sample`(빈 값 템플릿에 신규 2키 추가 + 기존 누락된 `NAVERMAP_CLIENT_ID` 추가), `App/Info.plist`(`$(NAVER_GEOCODING_CLIENT_ID)`/`$(NAVER_GEOCODING_CLIENT_SECRET)` 주입 항목), `Secret.swift`(프로퍼티 2개 추가). 실제 값이 든 `Secret.xcconfig`는 사용자가 이미 채움, **커밋 대상 아님**.

- **[결정 6] Geocoding 실패 처리 → 부분 저장 없음, 알럿 안내**
  - 결과 0건 → `TabiError.dataNotFound`(기존 케이스 재사용) → 폼에서 "주소를 찾을 수 없음" 알럿. 네트워크/인증 실패 → `NetworkError`가 그대로 전파되고 `NetworkService`가 이미 `AppLogger.network`로 로깅 → 폼에서는 `AppLogger.view` 로깅 후 일반 실패 알럿.
  - **좌표 변환이 성공한 뒤에만** `TouristSpot`을 만들어 `bookmarkUseCase.add`를 호출한다. 실패 시 저장 로직에 진입하지 않으므로 spec 불변 조건("부분 저장 없음")이 구조적으로 보장된다.
  - `TabiError`에 신규 케이스 추가는 불필요(기존 `dataNotFound`로 충분).

- **[결정 7] 입력 유효성 UX → 저장 버튼 비활성화 (인라인 에러 대신)**
  - 이유: `AddTravelPlanFeature.isConfirmEnabled`가 이미 같은 방식(공백 트림 후 빈 값이면 비활성)을 쓰고 있어 앱 전체 일관성이 있다. spec의 "저장 버튼 비활성 또는 유효성 에러" 중 전자를 채택.
  - 조건: 카테고리 선택됨 && 트림한 타이틀 비어있지 않음 && 트림한 주소 비어있지 않음 && `isSaving == false`.
  - 타이틀/주소는 `TabiTextField(maxLength:)`로 길이를 제한한다(구체 값은 구현 시 확정).

- **[결정 8] 진입점 → `BookmarkView` 상단 + `.sheet` present**
  - 이유: spec이 Bookmark 화면을 기본 진입점으로 지정. `PlanView` → `AddTravelPlanView`가 이미 `.sheet(item: $store.scope(...))` + `@Presents` 패턴이라 동일 구조를 따른다. `StackPath`(네비게이션 스택)에는 추가하지 않는다 — 일회성 입력 폼이라 sheet가 적합하고, `TabBarFeature`의 path 분기를 건드리지 않아 diff가 작다.
  - 저장 성공 시: 자식이 `savedResult(true)` 성격의 액션을 올리면 부모 `BookmarkFeature`가 sheet를 닫고 `.send(.onAppear)`로 목록을 리로드한다(기존 `fetch()`가 `savedAt` 내림차순 정렬이므로 새 항목이 맨 위에 즉시 표시됨).

- **[결정 9] Detail 화면의 `isCustom` 분기 → API effect 자체를 발행하지 않음**
  - `DetailFeature.onAppear`에서 `state.touristSpot.isCustom == true`면 `fetchDetailEffect`/`fetchIntroEffect`/`fetchImagesEffect`를 **머지하지 않고**, `fetchIsBookmarkedEffect`만 실행한다. `isLoading`은 즉시 `false`.
  - `State.init`은 이미 `touristSpot`으로 `detail` 플레이스홀더를 구성하고 있다. 커스텀일 때는 여기에 `address: touristSpot.address ?? ""`, `coordinate: touristSpot.coordinate`를 채워 넣어 상세 화면이 저장값만으로 렌더링되게 한다(현재는 `address: ""`, `coordinate: (0,0)` 하드코딩).
  - `hasReceivedAllResults` 기반 로딩 게이트는 커스텀 경로에서는 우회한다(결과 액션이 오지 않으므로 이 플래그에 의존하면 영구 로딩).
  - shareText는 현재 `detailResult`에서만 만들어진다 → 커스텀은 `onAppear` 시점에 저장된 title/address로 동일한 `makeShareText`를 호출해 구성한다.

- **[결정 10] Detail 화면에서 숨길 관광공사 전용 UI**
  - `photos` 탭: `images`가 항상 비어 `visibleTabs`에서 자동 제외됨(추가 작업 불필요, 확인 완료).
  - `map` 탭: 저장된 좌표가 유효하므로 그대로 노출한다. `mapSearchButtonTapped`(네이버 지도 앱 장소 검색)도 타이틀 기반이라 동작한다.
  - `info` 탭: `intro`가 `.empty(for:)` 플레이스홀더라 모든 intro 필드가 `nil` → `DetailInfoRow`들이 자동 생략되고 주소 행만 남는다(확인 완료). `overview`도 `nil`이라 미표시.
  - 명시적으로 손봐야 하는 건 **`routeDirectionsButtonTapped`**(`state.detail.coordinate` 사용 → 커스텀은 위에서 저장 좌표로 채워지므로 정상 동작)와 **ShareLink**(위 결정 9로 해결). 그 외 추가 분기가 필요한지는 구현 중 실제 화면을 보고 최종 판단한다.

- **[결정 11] `PlanDetailAddSpot`(일정에 스팟 추가)의 북마크 탭 영향**
  - `PlanDetailAddSpotFeature`도 `bookmarkUseCase.fetch()`로 같은 목록을 읽으므로 커스텀 장소가 그 목록에도 자연히 노출된다. 이번 스코프에서는 **의도된 동작으로 두고 코드를 수정하지 않는다**(CLAUDE.md "현재 태스크와 무관한 코드 수정 금지"). 문제가 되면 별도 spec으로 다룬다.

---

## 구현 순서

### Phase 0. 사전 확인 (완료)
- NCP Geocoding 활성화 확인 완료, `Secret.xcconfig`에 `NAVER_GEOCODING_CLIENT_ID`/`NAVER_GEOCODING_CLIENT_SECRET` 추가 완료(결정 5 참고).
- 호스트/경로/헤더명/파라미터/응답 스키마 확정 완료 → Phase 3·4 진행 가능.

### Phase 1. Domain 엔티티 확장
- `TouristSpot`에 `isCustom: Bool = false`, `address: String? = nil` 추가 (기본값 부여로 기존 호출부 무영향).
- 기존 5개 호출부가 그대로 컴파일되는지 빌드로 확인.

### Phase 2. Domain Geocoding 계층
- `NaverGeocodingRepositoryProtocol` 정의 (주소 문자열 → `Coordinate`, `async throws`).
- `NaverGeocodingUseCaseProtocol` + `NaverGeocodingUseCase` 구현 (Repository 위임, 결과 0건은 `TabiError.dataNotFound`).
- `TestNaverGeocodingUseCase` 더블 작성 (주입용 `var` 프로퍼티 공개).
- `Dependency/Keys/NaverGeocodingUseCaseDependencyKey.swift`(testValue) + `DependencyValues.swift`에 프로퍼티 추가.

### Phase 3. Data 네트워크 레이어 확장
- `Endpoint`에 `headers` 요구사항 + 기본 구현 `[:]` 추가.
- `NetworkService.request`에서 `allHTTPHeaderFields` 설정 (기존 엔드포인트 회귀 없는지 확인).
- `Secret.xcconfig.sample` / `App/Info.plist` / `Secret.swift`에 Geocoding 키 반영 (Phase 0 확정값 기준). 실제 `Secret.xcconfig`는 사용자가 직접 기입.

### Phase 4. Data Geocoding 구현
- `NaverGeocodingEndpoint` 작성 (query 파라미터 + 인증 헤더).
- `NaverGeocodingResponseDTO` + `toEntity()` 매핑 작성 (결과 0건/좌표 파싱 실패 → `TabiError.dataNotFound`, `AppLogger.network` 로깅).
- `NaverGeocodingRepository` 구현 (`NetworkService` 주입, 기본값은 `NetworkService()` — 기존 Repository 선례와 동일).

### Phase 5. Data SwiftData 스키마 변경
- `BookmarkModel`에 `isCustom: Bool = false`, `address: String?` 추가 + init 파라미터 반영.
- `BookmarkModel+.swift`의 `toDomain` / `convenience init(spot:savedAt:)` 양방향 매핑 갱신.
- 기존 DB가 있는 상태에서 앱을 재실행해 기존 북마크가 살아있는지 확인(결정 3의 검증).

### Phase 6. App DI 조립
- `App/Dependency/NaverGeocodingUseCaseDependencyKey.swift`에 `@retroactive DependencyKey` liveValue 정의.
- `tuist install && tuist generate` 후 빌드 (신규 `.swift` 파일 반영 필수).

### Phase 7. Resource 문자열
- `Strings.AddCustomPlace` 네임스페이스 신설 + 문구 추가 (일본어 UI 문구, 기존 Strings 컨벤션대로 한국어 주석 병기).
- "삭제"·카테고리 라벨 등은 `Strings.Common` 기존 항목 재사용 — 새로 만들지 않는다.

### Phase 8. Presentation 커스텀 장소 입력 폼
- `AddCustomPlaceFeature` State/Action/body 작성: 바인딩(타이틀/주소) → 카테고리 선택 → `isConfirmEnabled` computed → `confirmTapped`에서 geocoding effect → 성공 시 `TouristSpot` 생성 후 `bookmarkUseCase.add` → 결과 액션. 실패 시 `@Presents var alert`.
- `AddCustomPlaceView` 구성: `TabiNavigationBar` + 카테고리 선택 + `TabiTextField` × 2 + 하단 `TabiButton`. body 50줄 초과 시 `Sub/`로 분리.
- CancelID로 저장 effect 중복 실행 방지(연속 탭 대비).

### Phase 9. Presentation 연결
- `BookmarkFeature`에 `@Presents var addCustomPlaceState` + 진입/자식 액션 추가, 저장 성공 시 sheet 닫고 목록 리로드.
- `BookmarkView` 상단에 진입 버튼 추가 + `.sheet` 연결 (`PlanView` 패턴 참조).

### Phase 10. Detail 분기
- `DetailFeature.State.init`에서 커스텀일 때 `detail`의 `address`/`coordinate`를 저장값으로 구성.
- `onAppear`에서 `isCustom` 분기: API effect 스킵, `isLoading = false`, shareText 구성, `isBookmarked`만 조회.
- `DetailView`에서 커스텀 전용으로 숨길 요소가 남았는지 실제 화면 확인 후 최소 수정.

### Phase 11. 빌드/검증
- `tuist generate` 후 빌드 (시뮬레이터는 iPhone 17 사용 — iPhone 16 Pro 미설치).
- 정상 주소 저장 → 목록 즉시 반영 / 잘못된 주소 → 알럿 + 미저장 / 필터·스와이프 삭제 / 커스텀 상세 진입 시 네트워크 로그에 관광공사 호출이 없는지 / 앱 재실행 후 유지 — 순서대로 확인.

---

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
  - [ ] Bookmark 화면의 "커스텀 장소 추가" 버튼으로 카테고리/타이틀/주소 입력 폼 진입
  - [ ] 유효 주소 저장 시 Geocoding 좌표 변환 → 목록 최상단에 즉시 반영
  - [ ] 좌표를 찾을 수 없는 주소는 알럿 안내 + 미저장(부분 저장 없음)
  - [ ] 커스텀 장소도 카테고리 필터링 / 스와이프 삭제 정상 동작
  - [ ] 커스텀 장소 상세 진입 시 관광공사 API 호출 0건 (네트워크 로그로 확인)
  - [ ] 앱 재실행 후 커스텀 장소 유지
- [ ] 기존 API 기반 북마크가 스키마 변경 후에도 유실 없이 유지 (경량 마이그레이션 검증)
- [ ] Geocoding 실패 시 `AppLogger.network` / `AppLogger.view` 로깅
- [ ] `Endpoint.headers` 추가 후 기존 관광공사·축제 API 호출 회귀 없음
- [ ] `Secret.xcconfig`는 커밋되지 않음, `Secret.xcconfig.sample`에만 키 항목 반영
- [ ] `DependencyInformation` 의존성 방향 위반 없음 (Domain은 Data 미참조, liveValue 조립은 App에서만)

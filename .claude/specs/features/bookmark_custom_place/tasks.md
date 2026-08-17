# Tasks: bookmark_custom_place

## 참조
- spec: `.claude/specs/features/bookmark_custom_place/spec.md`
- plan: `.claude/specs/features/bookmark_custom_place/plan.md`

> Phase 0(NCP Geocoding 호스트/키 확정, `Secret.xcconfig`에 `NAVER_GEOCODING_CLIENT_ID`/`NAVER_GEOCODING_CLIENT_SECRET` 추가)는 완료된 상태이므로 Task 목록에서 제외한다.

## Task 목록

### Phase 1. Domain 엔티티 확장

#### [x] Task 1 — `TouristSpot.swift` (수정)
**파일**: `Projects/Domain/Sources/Entity/TouristSpot.swift`
- 저장 프로퍼티 `isCustom: Bool`, `address: String?` 추가
- `init`에 `isCustom: Bool = false`, `address: String? = nil` 파라미터를 기본값과 함께 추가 (결정 1 — 별도 엔티티 신설 대신 기본값 있는 파라미터로 확장)
- 기존 호출부 5곳(`TouristSpotDTO.toEntity()`, `FestivalDTO`, `BookmarkModel+.toDomain`, `DetailView` Preview, `AddToItineraryView` Preview)이 무수정으로 컴파일되는지 빌드로 확인
- `address`는 커스텀 장소 전용이며 API 기반 spot의 주소(`TouristSpotDetail.address`)와 혼용하지 않음

---

### Phase 2. Domain Geocoding 계층

#### [x] Task 2 — `NaverGeocodingRepositoryProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/RepositoryProtocol/NaverGeocodingRepositoryProtocol.swift`
- 주소 문자열 → `Coordinate` 변환 메서드 정의 (`async throws`)
- 기존 `TouristSpotRepositoryProtocol` 등 선례와 동일한 프로토콜 네이밍/구조 사용

---

#### [x] Task 3 — `NaverGeocodingUseCaseProtocol.swift`, `NaverGeocodingUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/NaverGeocoding/NaverGeocodingUseCaseProtocol.swift`, `Projects/Domain/Sources/UseCase/NaverGeocoding/NaverGeocodingUseCase.swift`
- `NaverGeocodingUseCaseProtocol`에 주소 → `Coordinate` 변환 메서드 선언
- `NaverGeocodingUseCase`는 `NaverGeocodingRepositoryProtocol`을 주입받아 위임 (`TouristSpotUseCase` 패턴 참조)
- 변환 결과 0건(주소를 찾을 수 없음)은 `TabiError.dataNotFound`로 매핑 (결정 6 — 신규 에러 케이스 불필요, 기존 케이스 재사용)

---

#### [x] Task 4 — `TestNaverGeocodingUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/NaverGeocoding/TestNaverGeocodingUseCase.swift`
- `Test{Name}` 접두사 규칙에 따라 `TestNaverGeocodingUseCase` 작성, `NaverGeocodingUseCaseProtocol` 채택
- 테스트 데이터 주입용 `var` 프로퍼티(반환할 `Coordinate` 또는 던질 에러) 공개
- `TestDependencyKey.testValue`가 참조하므로 Domain 모듈 본체에 위치 (test-style.md 규칙)

---

#### [x] Task 5 — `NaverGeocodingUseCaseDependencyKey.swift` (신규, testValue) + `DependencyValues.swift` (수정)
**파일**: `Projects/Domain/Sources/Dependency/Keys/NaverGeocodingUseCaseDependencyKey.swift`, `Projects/Domain/Sources/Dependency/DependencyValues.swift`
- `NaverGeocodingUseCaseDependencyKey`가 `TestDependencyKey` 채택, `testValue`에 `TestNaverGeocodingUseCase` 반환
- `DependencyValues`에 `naverGeocodingUseCase` 프로퍼티 확장 추가 (기존 프로퍼티들과 함께 정렬)

---

### Phase 3. Data 네트워크 레이어 확장

#### [x] Task 6 — `EndPoint.swift` (수정)
**파일**: `Projects/Data/Sources/Network/EndPoint/Protocol/EndPoint.swift`
- `var headers: [String: String] { get }` 요구사항 추가
- extension에 기본 구현 `[:]` 제공 (결정 4 — 기존 `TouristSpotEndpoint`/`FestivalEndpoint`는 선언 변경 없이 그대로 동작)

---

#### [x] Task 7 — `NetworkService.swift` (수정)
**파일**: `Projects/Data/Sources/Network/Service/NetworkService.swift`
- `URLRequest` 구성 시 `request.allHTTPHeaderFields = endPoint.headers` 한 줄 추가
- 기존 `httpMethod`/`timeoutInterval` 설정 로직 변경 없이 헤더만 추가되는지 확인, 기존 엔드포인트 회귀 없는지 확인

---

#### [x] Task 8 — `Secret.xcconfig.sample`, `Info.plist`, `Secret.swift` (수정)
**파일**: `Projects/Data/Sources/Secret.xcconfig.sample`, `Projects/App/Info.plist`, `Projects/Data/Sources/Network/Secret/Secret.swift`
- `Secret.xcconfig.sample`에 `NAVER_GEOCODING_CLIENT_ID`, `NAVER_GEOCODING_CLIENT_SECRET` 빈 값 템플릿 추가 + 기존 누락된 `NAVERMAP_CLIENT_ID` 항목도 함께 추가 (결정 5)
- `Info.plist`에 `$(NAVER_GEOCODING_CLIENT_ID)` / `$(NAVER_GEOCODING_CLIENT_SECRET)`를 주입하는 키 항목 추가
- `Secret.swift`에 두 값을 `Bundle.main`에서 읽는 프로퍼티 2개 추가 (기존 `TOUR_API_KEY`/`NMFNcpKeyId` 패턴 참조)
- 실제 값이 든 `Secret.xcconfig`는 사용자가 이미 채웠으므로 이 Task에서는 건드리지 않음 (커밋 대상 아님)

---

### Phase 4. Data Geocoding 구현

#### [x] Task 9 — `NaverGeocodingEndpoint.swift` (신규)
**파일**: `Projects/Data/Sources/Network/EndPoint/NaverGeocodingEndpoint.swift`
- URL: `https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode`, GET
- 쿼리 파라미터: `query`(필수, 주소 문자열)만 사용 (`coordinate`/`filter`/`language`/`page`/`count`는 이번 스코프에서 미사용)
- `headers`: `x-ncp-apigw-api-key-id` = `Secret.naverGeocodingClientID`, `x-ncp-apigw-api-key` = `Secret.naverGeocodingClientSecret`, `Accept: application/json` (결정 5 확정값)

---

#### [x] Task 10 — `NaverGeocodingResponseDTO.swift` (신규)
**파일**: `Projects/Data/Sources/DTO/NaverGeocoding/NaverGeocodingResponseDTO.swift`
- 응답 스키마 매핑: `{ status, meta: { totalCount, page, count }, addresses: [{ roadAddress, jibunAddress, englishAddress, addressElements: [...], x, y, distance }], errorMessage }` (결정 5 확정값)
- `x`(경도), `y`(위도)는 `String` 타입으로 오므로 `Double` 파싱 로직 포함
- `toEntity()` 매핑 작성: `addresses`가 빈 배열이거나 `meta.totalCount == 0`이면 `TabiError.dataNotFound` throw, 좌표 파싱 실패 시에도 동일하게 처리하며 `AppLogger.network`로 로깅

---

#### [x] Task 11 — `NaverGeocodingRepository.swift` (신규)
**파일**: `Projects/Data/Sources/Repository/NaverGeocoding/NaverGeocodingRepository.swift`
- `NaverGeocodingRepositoryProtocol` 채택 (extension으로 분리)
- `NetworkService` 주입, 기본값 `NetworkService()` (기존 Repository 선례와 동일)
- `NaverGeocodingEndpoint` 호출 → `NaverGeocodingResponseDTO` 디코딩 → `toEntity()`로 `Coordinate` 반환

---

### Phase 5. Data SwiftData 스키마 변경

#### [x] Task 12 — `BookmarkModel.swift` (수정)
**파일**: `Projects/Data/Sources/SwiftData/BookmarkModel.swift`
- `isCustom: Bool = false`, `address: String?` 컬럼(프로퍼티) 추가
- `isCustom`은 선언 시 `= false` 기본값 부여 (경량 마이그레이션 대상, 결정 3)
- init 파라미터에도 두 필드 반영

---

#### [x] Task 13 — `BookmarkModel+.swift` (수정)
**파일**: `Projects/Data/Sources/Extension/BookmarkModel+.swift`
- `toDomain` 매핑에 `isCustom`, `address` 반영 → `TouristSpot(..., isCustom:, address:)`
- `convenience init(spot:savedAt:)` 매핑에 `spot.isCustom`, `spot.address`를 `BookmarkModel`에 반영

---

#### [~] Task 14 — 마이그레이션 검증 (Phase 11 최종 검증 단계에서 실기 확인 예정)
**파일**: 없음 (검증 절차)
- 기존 DB(스키마 변경 전 저장된 `BookmarkModel` 레코드)가 있는 상태에서 앱을 재빌드/재실행해 기존 북마크가 유실 없이 유지되는지 확인 (결정 3 — `BookmarkModelContainer`는 컨테이너 생성 실패 시 in-memory로 조용히 폴백하므로 반드시 실기기/시뮬레이터로 검증)
- 실패 시 `VersionedSchema` 도입 재검토 필요 (이번 Task 범위 밖, 발견 시 별도 보고)

---

### Phase 6. App DI 조립

#### [x] Task 15 — `NaverGeocodingUseCaseDependencyKey.swift` (신규, liveValue)
**파일**: `Projects/App/Sources/Dependency/NaverGeocodingUseCaseDependencyKey.swift`
- 기존 `TouristSpotUseCaseDependencyKey.swift`(App) 패턴 참조
- `NaverGeocodingUseCaseDependencyKey`에 `@retroactive DependencyKey` extension으로 `liveValue` 정의
- `NaverGeocodingUseCase(repository: NaverGeocodingRepository())` 조립

---

#### [x] Task 16 — Tuist 재생성 및 빌드 확인
**파일**: 없음 (빌드 절차)
- `tuist install && tuist generate` 실행 (신규 `.swift` 파일 다수 반영 필수)
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'`로 빌드 성공 확인

---

### Phase 7. Resource 문자열

#### [ ] Task 17 — `Strings.swift` (수정)
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- `Strings.AddCustomPlace` 네임스페이스 신설: 화면 타이틀, 타이틀 입력 placeholder, 주소 입력 placeholder, 저장 버튼 문구, 좌표 변환 실패(주소 없음) 알럿 문구, 일반 실패 알럿 문구
- 기존 컨벤션대로 한국어 주석 병기, 일본어 UI 문구로 작성
- "삭제"·카테고리 라벨 등은 `Strings.Common` 기존 항목을 재사용하고 새로 만들지 않음

---

### Phase 8. Presentation 커스텀 장소 입력 폼

#### [x] Task 18 — `AddCustomPlaceFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/AddCustomPlace/AddCustomPlaceFeature.swift`
- `AddTravelPlanFeature` 구조 차용: `BindableAction`(타이틀/주소 바인딩) + 카테고리 선택 상태 + `isConfirmEnabled` computed + `@Presents var alert` + `@Dependency(\.dismiss)`
- `isConfirmEnabled` 조건(결정 7): 카테고리 선택됨 && 트림한 타이틀 비어있지 않음 && 트림한 주소 비어있지 않음 && `isSaving == false`
- `confirmTapped` effect: `naverGeocodingUseCase`로 주소 → `Coordinate` 변환 → 성공 시 `TouristSpot(id: "custom_" + UUID().uuidString, ..., isCustom: true, address: 입력주소, thumbnailURLString: nil)` 생성 (결정 2 — ID 접두사 `custom_`) → `bookmarkUseCase.add(spot)` 호출 → 결과 액션(`saveResult(Bool)` 성격)
- 실패 처리(결정 6): 0건 → `TabiError.dataNotFound` → "주소를 찾을 수 없음" 알럿, 네트워크/인증 실패 → `AppLogger.view` 로깅 후 일반 실패 알럿. 좌표 변환 성공 전에는 `bookmarkUseCase.add` 호출하지 않음(부분 저장 없음)
- CancelID를 사용해 저장 effect 중복 실행 방지 (연속 탭 대비)

---

#### [x] Task 19 — `AddCustomPlaceView.swift` (신규)
**파일**: `Projects/Presentation/Sources/AddCustomPlace/AddCustomPlaceView.swift`
- `TabiNavigationBar` + 카테고리 선택 UI + `TabiTextField`(타이틀, 주소 각각 `maxLength` 지정) + 하단 `TabiButton`(저장, `isConfirmEnabled`로 활성/비활성)
- body 50줄 초과 시 `Sub/`로 서브뷰 분리

---

#### [x] Task 20 — 카테고리 선택 서브뷰 (신규, 필요 시)
**파일**: `Projects/Presentation/Sources/AddCustomPlace/Sub/` 하위 (예: 카테고리 선택 그리드/칩 로우, 하단 CTA 뷰 — `AddTravelPlanView`의 `Sub/AddPlanRegionGridView.swift`, `Sub/AddPlanBottomCTAView.swift` 패턴 참조)
- `CategoryType+`(Presentation)의 `label`/`color`/`icon`/`allItems` 재사용해 카테고리 선택 UI 구성
- Task 19에서 body가 50줄을 넘는 경우에만 분리 적용

---

### Phase 9. Presentation 연결

#### [x] Task 21 — `BookmarkFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/Bookmark/BookmarkFeature.swift`
- `@Presents var addCustomPlaceState: AddCustomPlaceFeature.State?` 추가
- `addCustomPlaceButtonTapped` 액션(진입 버튼 탭) 추가 → `addCustomPlaceState` 설정
- `addCustomPlace(PresentationAction<AddCustomPlaceFeature.Action>)` 하위 액션 추가, `.ifLet`으로 body 마지막에 연결
- 저장 성공 시(결정 8): sheet 닫고 `.send(.onAppear)`로 목록 리로드 (`fetch()`가 `savedAt` 내림차순이므로 새 항목이 최상단에 즉시 표시됨)

---

#### [x] Task 22 — `BookmarkView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Bookmark/BookmarkView.swift`
- 상단에 "커스텀 장소 추가" 진입 버튼 추가 (`addCustomPlaceButtonTapped` 액션 전송)
- `.sheet(item: $store.scope(state: \.addCustomPlaceState, action: \.addCustomPlace))` 연결 (`PlanView`의 `.sheet(item:)` 패턴 참조, 결정 8 — `StackPath`에는 추가하지 않음)

---

### Phase 10. Detail 분기

#### [x] Task 23 — `DetailFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/Detail/DetailFeature.swift`
- `State.init`에서 `touristSpot.isCustom == true`일 때 `detail`의 `address`를 `touristSpot.address ?? ""`, `coordinate`를 `touristSpot.coordinate`로 채워서 구성 (현재 하드코딩된 `address: ""`, `coordinate: (0,0)` 대체, 결정 9)
- `onAppear`에서 `isCustom` 분기: `true`면 `fetchDetailEffect`/`fetchIntroEffect`/`fetchImagesEffect`를 머지하지 않고 `fetchIsBookmarkedEffect`만 실행, `isLoading`은 즉시 `false`로 설정
- `hasReceivedAllResults` 기반 로딩 게이트를 커스텀 경로에서는 우회 (결과 액션이 오지 않아 게이트에 의존하면 영구 로딩됨)
- shareText: 커스텀 장소는 `onAppear` 시점에 저장된 title/address로 기존 `makeShareText`를 호출해 구성 (기존은 `detailResult`에서만 생성됨)

---

#### [x] Task 24 — `DetailView.swift` (코드 검토 결과 수정 불필요 — DetailInfoTabView/DetailMapTabView가 nil 가드로 자동 대응함을 확인)
**파일**: `Projects/Presentation/Sources/Detail/DetailView.swift`
- 결정 10에 따라 `photos` 탭(이미지 항상 비어 자동 제외), `info` 탭(intro 필드 전부 nil로 자동 생략)은 추가 작업 불필요함을 실기기 화면 확인으로 재검증
- `map` 탭과 `routeDirectionsButtonTapped`(`state.detail.coordinate` 사용)는 Task 23에서 저장 좌표가 채워지므로 정상 동작하는지 확인
- 실제 화면 확인 중 관광공사 전용 UI 요소가 커스텀 장소에 노출되는 경우에만 최소 수정 적용

---

### Phase 11. 빌드/검증

#### [~] Task 25 — 최종 빌드 및 기능 검증 (빌드 성공 확인 완료, 시나리오 1~6은 실기 확인 필요)
**파일**: 없음 (검증 절차)
- `tuist generate` 후 `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'`로 빌드 성공 확인
- 시나리오 순서대로 확인:
  1. 정상 주소 저장 → Bookmark 목록 최상단에 즉시 반영
  2. 잘못된/찾을 수 없는 주소 저장 시도 → 알럿 안내 + 미저장(부분 저장 없음)
  3. 커스텀 장소도 카테고리 필터·스와이프 삭제 정상 동작
  4. 커스텀 장소 상세 진입 시 네트워크 로그에 관광공사 API 호출이 없는지 확인
  5. 앱 재실행 후 커스텀 장소 유지 확인
  6. 기존 API 기반 북마크가 스키마 변경 후에도 유실 없이 유지되는지 재확인 (Task 14와 함께 최종 확인)

---

## 체크리스트

### 품질 (DoD)
- [ ] 빌드 성공 (`tuist generate` 후 `xcodebuild build`)
- [ ] 테스트 통과 (테스트 타겟 미구성 상태 — 해당 없음)
- [ ] `Endpoint.headers` 추가 후 기존 관광공사·축제 API 호출 회귀 없음
- [ ] `Secret.xcconfig`는 커밋되지 않음, `Secret.xcconfig.sample`에만 키 항목 반영
- [ ] `DependencyInformation` 의존성 방향 위반 없음 (Domain은 Data 미참조, liveValue 조립은 App에서만)
- [ ] Geocoding 실패 시 `AppLogger.network`(Data) / `AppLogger.view`(Presentation) 로깅

### 기능 (AC)
- [ ] Bookmark 화면의 "커스텀 장소 추가" 버튼으로 카테고리/타이틀/주소 입력 폼 진입
- [ ] 유효한 주소 입력 후 저장 시 Naver Geocoding으로 좌표 변환되어 Bookmark 목록에 즉시 반영
- [ ] 좌표를 찾을 수 없는 주소 입력 시 에러 안내 + 미저장
- [ ] 커스텀 장소도 기존 API 기반 북마크와 동일하게 카테고리 필터링, 스와이프 삭제 동작
- [ ] 커스텀 장소를 탭해 상세화면 진입 시 관광공사 API 호출 없이 저장된 정보만으로 렌더링
- [ ] 앱을 재실행해도 커스텀 장소가 유지됨

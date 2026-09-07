# Tasks: plan_detail_map

## 참조
- spec: `.claude/specs/features/plan_detail_map/spec.md`
- plan: `.claude/specs/features/plan_detail_map/plan.md`

## Task 목록

### Phase 1. Domain

#### [x] Task 1 — `TravelPlanRepositoryProtocol.swift`
**파일**: `Projects/Domain/Sources/RepositoryProtocol/TravelPlanRepositoryProtocol.swift`
- `func update(_ plan: TravelPlan) async throws` 시그니처 추가 (`add` 다음 위치)

---

#### [x] Task 2 — `TravelPlanUseCaseProtocol.swift`
**파일**: `Projects/Domain/Sources/UseCase/TravelPlan/TravelPlanUseCaseProtocol.swift`
- `Task 1`과 동일한 `update(_ plan: TravelPlan) async throws` 시그니처 추가

---

#### [x] Task 3 — `TravelPlanUseCase.swift`
**파일**: `Projects/Domain/Sources/UseCase/TravelPlan/TravelPlanUseCase.swift`
- `update(_ plan:)` 구현 — `repository.update(plan)` 위임 1메서드

---

#### [x] Task 4 — `TestTravelPlanUseCase.swift`
**파일**: `Projects/Domain/Sources/UseCase/TravelPlan/TestTravelPlanUseCase.swift`
- `update(_ plan:)` 구현 — `plans` 배열에서 `id`가 일치하는 요소를 새 `plan`으로 교체, 일치하는 요소가 없으면 아무 것도 하지 않음(no-op)

---

#### [x] Task 5 — `TravelPlanDetailRepositoryProtocol.swift`
**파일**: `Projects/Domain/Sources/RepositoryProtocol/TravelPlanDetailRepositoryProtocol.swift`
- `func removeSpots(planId: UUID, fromDayIndex: Int) async throws` 시그니처 추가 (`removeSpot` 다음 위치)

---

#### [x] Task 6 — `TravelPlanDetailUseCaseProtocol.swift` / `TravelPlanDetailUseCase.swift`
**파일**: `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCaseProtocol.swift`, `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCase.swift`
- Protocol에 `removeSpots(planId: UUID, fromDayIndex: Int) async throws` 시그니처 추가
- UseCase 구현에 `repository.removeSpots(planId:fromDayIndex:)` 위임 1메서드 추가

---

#### [x] Task 7 — `TestTravelPlanDetailUseCase.swift`
**파일**: `Projects/Domain/Sources/UseCase/TravelPlanDetail/TestTravelPlanDetailUseCase.swift`
- `removeSpots(planId:fromDayIndex:)` 구현 — 해당 `planId`의 detail을 `spots.filter { $0.dayIndex < fromDayIndex }` 결과로 교체

---

### Phase 2. Data

#### [x] Task 8 — `TravelPlanRepository.swift`
**파일**: `Projects/Data/Sources/Repository/TravelPlan/TravelPlanRepository.swift`
- `update(_ plan:)` 구현
  - `plan.id`를 지역 상수로 캡처 후 `FetchDescriptor<TravelPlanModel>(predicate: #Predicate { $0.id == planId })`로 조회
  - 조회 결과 없으면 `AppLogger.core.log(.error, ...)` 후 `TabiError.persistenceFailed` throw
  - 조회 결과 있으면 `title` / `regionRaw` / `customRegionText` / `customEmoji` / `startDate` / `endDate` 대입 후 `save()`
  - 기존 메서드와 동일한 `do-catch` + `AppLogger.core` + `persistenceFailed` 매핑 형태 준수

---

#### [x] Task 9 — `TravelPlanDetailRepository.swift`
**파일**: `Projects/Data/Sources/Repository/TravelPlanDetail/TravelPlanDetailRepository.swift`
- `removeSpots(planId:fromDayIndex:)` 구현
  - `planId` / `fromDayIndex`를 지역 상수로 캡처 후 `#Predicate { $0.planId == planId && $0.dayIndex >= fromDayIndex }`로 조회
  - 조회된 항목 전부 `context.delete` 후 `save()` (대상 0건이면 그대로 `save()` — 정상 성공)
  - 실패 시 `AppLogger.core.log(.error, "일정 상세 스팟 일괄 삭제 실패: ...")` + `TabiError.persistenceFailed`

---

### Phase 3. Resource

#### [x] Task 10 — `Strings.swift`
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- `Strings.Plan`에 아래 5개 항목 추가(각 항목에 한국어 주석 포함)
  - `planEditMenuTitle = "予定を編集"` — `"..."` 메뉴의 플랜 편집 항목
  - `editPlanScreenTitle = "日程を編集"` — 편집 시트 타이틀
  - `dayShrinkAlertTitle = "日程が短くなります"`
  - `dayShrinkAlertMessage: ((Int) -> String) = { "\($0)日目以降のスポットは削除されます。よろしいですか？" }` — 인자는 삭제 시작 일차(1-based)
  - `alertCancel = "キャンセル"`
- 기존 문구(`nameLabel` / `namePlaceholder` / `dateLabel` / `editSaveButton` / `saveFailedAlertTitle` / `saveFailedAlertMessage` / `alertConfirm` / `editMenuTitle`)는 재사용하며 신규 추가하지 않음

---

### Phase 4. DesignSystem (마커 순번)

#### [x] Task 11 — `TabiMapMarker.swift`
**파일**: `Projects/DesignSystem/Sources/Map/TabiMapMarker.swift`
- `public let index: Int?` 프로퍼티 추가
- `init(..., color: TabiColor, index: Int? = nil)` — 마지막 파라미터에 기본값 `nil` 추가 (기존 3개 호출부 무변경 컴파일 보장)

---

#### [x] Task 12 — `TabiMapMarkerPinView.swift`
**파일**: `Projects/DesignSystem/Sources/Map/TabiMapMarkerPinView.swift`
- `let index: Int?` 프로퍼티 추가
- 원 + `tabiOnColor` 스트로크는 유지, overlay 내용만 분기
  - `index`가 있으면 `Text("\(index)")` (`.system(size: 14, weight: .bold)`, `tabiOnColor`)
  - `index`가 없으면 기존 `Image(icon)` 렌더 그대로 유지

---

#### [x] Task 13 — `TabiMapMarkerImageFactory.swift`
**파일**: `Projects/DesignSystem/Sources/Map/TabiMapMarkerImageFactory.swift`
- `static func image(icon:color:index:)`로 확장
- `reuseIdentifier = "\(icon.rawValue)-\(color.rawValue)-\(index.map(String.init) ?? "noIndex")"` — index를 캐시 키에 반영
- `TabiMapMarkerPinView(icon:color:index:)`에 index 전달

---

#### [x] Task 14 — `TabiMapView+Coordinator.swift`
**파일**: `Projects/DesignSystem/Sources/Map/TabiMapView+Coordinator.swift`
- `markerAppearances` 딕셔너리 타입에 `index: Int?` 추가 (`[String: (icon: TabiIcon, color: TabiColor, index: Int?)]`)
- `syncPlainMarkers`에서 `TabiMapMarkerImageFactory.image(icon:color:index:)` 호출로 index 전달
- `syncClusteredMarkers`에서 `markerAppearances[marker.id] = (marker.icon, marker.color, marker.index)`로 index 반영
- `TabiLeafMarkerUpdater.appearanceProvider` 타입 및 호출부에 index 반영
- 마커 생성/제거 로직(`newIDs` / `staleIDs` 비교)은 변경하지 않음

---

### Phase 5. Presentation — 플랜 편집 시트 (신규 Feature)

#### [x] Task 15 — `TravelPlan+.swift` / `AddPlanDateRangeView.swift`
**파일**: `Projects/Presentation/Sources/Plan/Model/TravelPlan+.swift`, `Projects/Presentation/Sources/AddTravelPlan/Sub/AddPlanDateRangeView.swift`
- `TravelPlan+.swift`에 `static func dayCount(startDate: Date, endDate: Date) -> Int` 추가, 기존 인스턴스 `dayCount`가 이를 호출하도록 위임(계산식 동일, 동작 변화 없음)
- `AddPlanDateRangeView.swift`에 `var initialMonth: Date = Date()` 파라미터 추가 후 `TabiRangeCalendar(startDate:endDate:initialMonth:)`에 전달 (`AddTravelPlanView` 호출부는 무변경)

---

#### [x] Task 16 — `PlanDetailEditFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetailEdit/PlanDetailEditFeature.swift`
- 의존성: `@Dependency(\.travelPlanUseCase)`, `@Dependency(\.travelPlanDetailUseCase)`, `@Dependency(\.dismiss)`
- State (공개 → fileprivate → `@Presents` 순)
  - `title: String`, `startDate: Date?`, `endDate: Date?`, `isSaving: Bool = false`
  - `fileprivate let plan: TravelPlan` (원본 — id / region / customRegionText / customEmoji 보존 및 기존 `dayCount` 비교용)
  - 계산 프로퍼티: `trimmedTitle`, `isConfirmEnabled`(제목 non-empty + 두 날짜 non-nil), `newDayCount: Int?`, `currentDayCount: Int`
  - `@Presents var alert: AlertState<Action.Alert>?`
  - `public init(plan: TravelPlan)` — `title` / `startDate` / `endDate`를 plan 값으로 프리필
- Action (`BindableAction, Equatable`): `binding` → `closeButtonTapped`, `confirmButtonTapped` → `planUpdated(TravelPlan)`, `saveFailed` → `alert(PresentationAction<Alert>)`
  - `public enum Alert: Equatable { case shrinkConfirmed }`
- Reduce
  - `.closeButtonTapped`: `.run { await dismiss() }`
  - `.confirmButtonTapped`: `isSaving == false && isConfirmEnabled` 및 `startDate <= endDate` 가드 → 갱신된 plan(`title`/`startDate`/`endDate`만 교체) 생성 → `newDayCount >= currentDayCount`면 `isSaving = true` + `saveEffect(plan:)` 실행, 작으면 State 변경 없이 축소 확인 알럿만 표시(`dayShrinkAlertTitle`, `dayShrinkAlertMessage(newDayCount + 1)`, 확인 = `.destructive` + `.shrinkConfirmed`, 취소 = `ButtonState(role: .cancel)` + `alertCancel`)
  - `.alert(.presented(.shrinkConfirmed))`: `isSaving = true` → `shrinkAndSaveEffect(plan:fromDayIndex: newDayCount)`
  - `.alert(.dismiss)` 및 취소: `.none` (spec의 "취소 시 시트 유지, 변경 없음")
  - `.planUpdated`: `.none` (부모가 처리)
  - `.saveFailed`: `isSaving = false` + `saveFailedAlertTitle` / `saveFailedAlertMessage` 알럿 표시
  - `private enum CancelID { case save }`, 저장 Effect에 `.cancellable(id: CancelID.save)`
- `// MARK: - Method` `private extension`
  - `saveEffect(plan:)` — `update` 성공 시 `.planUpdated(plan)`, 실패 시 `AppLogger.view.log(.error, ...)` + `.saveFailed`
  - `shrinkAndSaveEffect(plan:fromDayIndex:)` — `removeSpots` → 같은 Effect에서 `update` 순차 실행. 어느 단계든 throw면 로깅 + `.saveFailed`(삭제 실패 시 `update` 미실행)

---

#### [x] Task 17 — `PlanDetailEditView.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetailEdit/PlanDetailEditView.swift`
- `@Bindable private var store`, `@FocusState private var isTitleFocused`, `@State private var selectedDetent: PresentationDetent = .medium`
- `ScrollView` + `VStack(spacing: 24)`: 이름 섹션(`TabiLabel(nameLabel)` + `TabiTextField(namePlaceholder)`) / 날짜 섹션(`TabiLabel(dateLabel)` + `AddPlanDateRangeView(startDate:endDate:initialMonth:)`, `initialMonth`에는 프리필된 `startDate ?? Date()` 전달)
- `safeAreaBar(edge: .top)`: `TabiNavigationBar(title: Strings.Plan.editPlanScreenTitle) { TabiCircleIconButton(systemName: "xmark") }`
- `safeAreaBar(edge: .bottom)`: `TabiButton(Strings.Plan.editSaveButton, style: .primary, isExpanded: true, isLoading: store.isSaving, height: 45, cornerRadius: .tabiRadiusFull)` + `.disabled(!store.isConfirmEnabled)` + `.padding(.horizontal, 20)`
- `.presentationDetents([.medium, .large], selection:)`, `.presentationDragIndicator(.visible)`, `.alert($store.scope(state: \.alert, action: \.alert))`, 제목 필드 포커스 시 `.large`로 승격
- `body`가 50줄 초과 시 `private extension`의 `nameField()` / `dateSection()` / `closeButton()`로 분리 (`AddTravelPlanView` 구조 참고)
- `#Preview` — `TravelPlan.mock` 주입

---

### Phase 6. Presentation — PlanDetail 연결 (메뉴 / 취소 버튼 / 순번 / 지도)

#### [x] Task 18 — `TravelPlanDetailSpot+.swift`
**파일**: `Projects/Presentation/Sources/PlanDetail/Model/TravelPlanDetailSpot+.swift`
- `import DesignSystem` 추가
- `func toMapMarker(index: Int) -> TabiMapMarker?` 추가
  - `guard self.coordinate.isValid`로 좌표 무효 시 `nil` 반환
  - `id: "\(self.id.uuidString)-\(index)"`, `title: self.title.truncated(to: 15)`, `icon: self.category.icon`, `color: self.category.color`, `index: index`

---

#### [x] Task 19 — `PlanDetailSpotRow.swift`
**파일**: `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailSpotRow.swift`
- `let index: Int` 프로퍼티 추가 (`spot` 다음)
- `timeline`: `Circle().fill(self.spot.category.color).frame(width: 22, height: 22)` + `overlay { TabiLabel(title: "\(self.index)", style: .captionXSBold, color: .tabiOnColor) }`
- 원을 감싼 `VStack`의 `frame(width: 10)` → `frame(width: 22)`로 변경 (시간 라벨/타임라인/카드 정렬 유지)
- 위/아래 세로선 세그먼트와 `isFirst` / `isLast` 처리는 변경하지 않음

---

#### [x] Task 20 — `PlanDetailMapSection.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailMapSection.swift`
- `let markers: [TabiMapMarker]`, `let fitToken: Int`
- `TabiMapView(centerLatitude: markers.first?.latitude ?? Coordinate.seoulCityHall.latitude, centerLongitude: ..., markers:, isClusteringEnabled: false, showsLocationButton: false, followsUserLocation: false, boundsFitToken: fitToken, onMapTapped: { _, _ in }, onMarkerTapped: { _ in })`
- `.frame(height: 200)` + `clipShape(RoundedRectangle(cornerRadius: .tabiRadiusLg))` + `stroke(tabiBorder.opacity(0.4))` + `.padding(.horizontal, 20)`
- 마커가 1개 이상일 때만 호출됨을 전제로 하는 순수 표시 뷰 (호출부에서 빈 배열 체크)

---

#### [x] Task 21 — `PlanDetailFeature.swift`
**파일**: `Projects/Presentation/Sources/PlanDetail/PlanDetailFeature.swift`
- State: `var dayMapFitToken: Int = 0` 추가, `@Presents var editPlanState: PlanDetailEditFeature.State?` 추가(`@Presents` 블록 최하단)
- Action: `case planEditMenuButtonTapped`(인터랙션 구역), `case editPlan(PresentationAction<PlanDetailEditFeature.Action>)`(하위 액션, 마지막)
- `.planEditMenuButtonTapped`: `state.editPlanState = PlanDetailEditFeature.State(plan: state.plan)`
- `.dayButtonTapped(index:)`: 인덱스 갱신 후, 해당 일자 스팟에 `coordinate.isValid`가 하나라도 있으면 `dayMapFitToken += 1`
- `.travelPlanDetailResult(let detail)`: 대입 후 선택 일자 기준 동일 조건으로 `dayMapFitToken += 1`
- `.editPlan(.presented(.planUpdated(let plan)))`: `state.plan = plan` → `state.selectedDayIndex = min(state.selectedDayIndex, plan.dayCount - 1)` → `isEditing = false` / `editingSpots = []` / `isSaving = false` → `editPlanState = nil` → `fetchTravelPlanDetailEffect(id: plan.id)` 반환 (기존 `.cancel(id: CancelID.saveEditedSpots)` 취소와 충돌 없이 `.merge` 또는 순서 정리)
- `.editPlan` 그 외 케이스: `.none`
- `body` 마지막에 `.ifLet(\.$editPlanState, action: \.editPlan) { PlanDetailEditFeature() }` 추가

---

#### [x] Task 22 — `PlanDetailView.swift`
**파일**: `Projects/Presentation/Sources/PlanDetail/PlanDetailView.swift`
- 툴바 `Menu`에 `Button(Strings.Plan.planEditMenuTitle) { store.send(.planEditMenuButtonTapped) }` 추가 (기존 `editMenuTitle`("編集") 항목 아래, 그 항목은 유지)
- 본문 재구성
  - `dayTabScroll(plan:)` 유지
  - 헤더 블록(`PlanDetailDayHeader`)에 `.id(store.selectedDayIndex)` + 기존 `asymmetric(move)` transition 부여
  - `let markers = self.selectedDayMarkers`; `if markers.isEmpty == false { PlanDetailMapSection(markers: markers, fitToken: store.dayMapFitToken) }` 추가 (`.id` 없이 컨테이너 밖에 배치 — day 전환 시 지도 재생성 방지)
  - 리스트 블록(`spotList()`)에 `.id(store.selectedDayIndex)` + 동일 transition 부여
  - 루트의 `.animation(.tabiStandard, value: store.selectedDayIndex)` / `.animation(.tabiStandard, value: store.isEditing)` 유지
- `private extension`에 `var selectedDayMarkers: [TabiMapMarker]` 추가 — `store.displayedSpots.enumerated().compactMap { $0.element.toMapMarker(index: $0.offset + 1) }`
- `ForEach`에서 `PlanDetailSpotRow(spot:index: index + 1, isFirst:isLast:isEditing:)`로 index 전달
- `editActionButtons()`의 취소 버튼 `style: .secondary` → `.ghost`로 변경 (`isExpanded: true` 등 나머지 파라미터 유지)
- `.sheet(item: self.$store.scope(state: \.editPlanState, action: \.editPlan)) { PlanDetailEditView(store: $0) }` 추가

---

### Phase 7. 빌드 / 검증

#### [x] Task 23 — `tuist generate`
**파일**: 없음 (Tuist 프로젝트 재생성)
- 신규 파일 3개(`PlanDetailEditFeature.swift`, `PlanDetailEditView.swift`, `PlanDetailMapSection.swift`) + 신규 폴더 `PlanDetailEdit/` 추가로 `tuist install` / `tuist generate` 필수 실행

---

#### [x] Task 24 — 빌드 및 시나리오 검증
**파일**: 없음 (수동/빌드 검증)
- `xcodebuild build`로 빌드 성공 확인
- `"..."` → `予定を編集` → 이름/날짜 수정 → 저장 → 내비게이션 타이틀·day 탭 개수 즉시 반영, 뒤로 가면 일정 목록(`PlanFeature.onAppear` 재조회)에도 반영되는지 확인
- 일수 동일/증가 → 알럿 없이 저장, 기존 스팟 유지 확인
- 일수 축소 → 알럿 취소 시 시트 유지 + 스팟 유지 / 확인 시 초과 dayIndex 스팟 삭제 후 저장, 마지막 일자로 선택 이동 확인
- 제목 비우기 / 날짜 미선택 → 저장 버튼 비활성 확인
- 편집모드 취소 버튼: 보더 없음 + non-bold, 저장 버튼과 5:5 유지 확인
- 타임라인 원 안 1,2,3… 표시 및 시간 라벨/카드 정렬 유지 확인 (편집모드 드래그 후 번호 재정렬 확인)
- 좌표 유효 스팟 있는 날 → 지도 표시 + 마커 번호 일치, day 전환 시 카메라 재조정 + 지도 깜빡임 없는지 확인
- 좌표 유효 스팟 0인 날 → 지도 영역 미표시 확인
- 회귀 확인: `MapView` 검색 마커(클러스터 off/on), `DetailView` 지도 탭, `AddCustomPlaceView` 미리보기 마커가 기존과 동일하게 보이는지 확인

---

## 체크리스트

### 품질 (DoD)
- [x] 빌드 성공 (`xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'`)
- [x] `tuist generate` 후 stale 프로젝트 오탐 에러 없음
- [x] `TabiButton`은 수정되지 않았고, `TabiMapMarker` 기존 호출부 3곳(`AddCustomPlaceView`/`MapView`/`DetailMapTabView`)은 코드 변경 없이 컴파일·동작
- [x] `TabiMapMarkerImageFactory`의 `reuseIdentifier`에 index가 포함되어 서로 다른 순번 마커가 같은 이미지를 재사용하지 않음
- [ ] 테스트 통과 (테스트 타겟 미구성 상태이므로 해당 없음 — 추가 시 `.claude/rules/test-style.md` 준수)

### 기능 (AC)
- [x] `"..."` 메뉴에서 플랜 이름/날짜를 수정할 수 있고, 날짜 개수가 같거나 늘어나면 확인 없이 저장된다
- [x] 날짜 개수가 줄어들면 확인 알럿이 뜨고, 확인 시 초과 dayIndex의 스팟이 삭제된 뒤 저장되며, 취소 시 아무 변경도 발생하지 않는다
- [x] 편집모드 취소 버튼이 보더 없이 non-bold로 표시되고, 다른 화면의 `.secondary` 버튼은 기존과 동일하다
- [x] 스팟 타임라인의 원 안에 1부터 시작하는 순번이 표시된다
- [x] 선택된 일자에 좌표가 유효한 스팟이 있으면 지도가 표시되고, 마커에 순번이 보이며 day 전환 시 카메라가 재조정된다
- [x] 좌표가 유효한 스팟이 하나도 없는 날에는 지도 영역이 보이지 않는다
- [x] `AddCustomPlaceView`/`MapView`/`DetailMapTabView`의 기존 지도/마커 동작에 회귀가 없다

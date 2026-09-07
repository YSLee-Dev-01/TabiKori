# Plan: plan_detail_map (플랜 자체 수정 + 취소 버튼 스타일 + 타임라인 순번 + 선택 일자 지도)

## 참조 Spec
- @.claude/specs/features/plan_detail_map/spec.md

## 참조 Skill
- 프로젝트에 `create-feature` 스킬 없음 (`.claude/skills/`에는 code-review / commit / feature / prompt만 존재)
- 레퍼런스 패턴:
  - `@.claude/specs/features/plan_detail_plus/plan.md` — `PlanDetail` + `@Presents` 시트 자식 Feature 구성, "자식은 결과 액션만 보내고 부모가 닫는다" 규약
  - `Presentation/AddTravelPlan` — 이름/날짜 입력 + `isConfirmEnabled` + 저장 실패 알럿
  - `Presentation/Map` — `boundsFitToken` 증가로 카메라 재조정
  - `Presentation/Detail/Sub/DetailMapTabView`, `Presentation/AddCustomPlace` — 카드형(고정 높이 + 라운드 + 보더) 지도 임베드
  - `Presentation/Plan` — 저장/삭제 실패 알럿 처리 관행

---

## 현재 상태 파악

### 신규

**Presentation** (`Projects/Presentation/Sources/PlanDetailEdit/`)
- `PlanDetailEditFeature.swift` — 플랜 이름/날짜 수정 시트 Reducer. `dayCount` 비교 → 즉시 저장 / 축소 확인 알럿 분기, 스팟 일괄 삭제 후 저장 Effect 보유
- `PlanDetailEditView.swift` — 시트 루트 뷰. `TabiNavigationBar`(닫기) + 이름 필드 + 날짜 섹션 + 하단 저장 CTA

**Presentation** (`Projects/Presentation/Sources/PlanDetail/Sub/`)
- `PlanDetailMapSection.swift` — 선택 일자 마커 지도 카드 (고정 높이 + 라운드 + 보더). 마커가 1개 이상일 때만 호출됨을 전제로 하는 순수 표시 뷰

**Resource**
- `Strings.Plan`에 5개 추가: `planEditMenuTitle`, `editPlanScreenTitle`, `dayShrinkAlertTitle`, `dayShrinkAlertMessage(Int)`, `alertCancel`

### 재사용
- **DesignSystem**: `TabiMapView`(생성자 무변경, `boundsFitToken` 기존 파라미터 사용), `TabiButton` `.ghost` / `.primary`, `TabiTextField`, `TabiLabel`, `TabiNavigationBar`, `TabiCircleIconButton`, `TabiRangeCalendar`, `TabiCard`, `TabiColor`, `.tabiRadiusLg` / `.tabiRadiusFull`, `.tabiStandard`
- **Presentation**: `AddTravelPlan/Sub/AddPlanDateRangeView`(spec가 명시한 크로스 폴더 재사용), `Plan/Model/TravelPlan+.swift`의 `dayCount` / `dayDates`, `Home/Model/CategoryType+.swift`의 `icon` / `color`, `PlanDetail/PlanDetailMock.swift`(Preview)
- **Domain**: `TravelPlan`(전 필드 `var`라 값 갱신 가능), `TravelPlanDetailSpot.coordinate`, `Coordinate.isValid`, `TabiError.persistenceFailed`
- **Core**: `AppLogger.view`(Feature) / `AppLogger.core`(Repository), `String.truncated(to:)`
- **Resource**: `Strings.Plan.editMenuTitle`(스팟 순서 편집 메뉴 — 그대로 유지), `nameLabel` / `namePlaceholder` / `dateLabel`, `editSaveButton`("保存" — 편집 시트 하단 CTA로 재사용), `saveFailedAlertTitle` / `saveFailedAlertMessage`(플랜 저장 실패 · 스팟 일괄 삭제 실패 공용), `alertConfirm`
- **App**: `Projects/App/Sources/Dependency/TravelPlanUseCaseDependencyKey.swift`, `TravelPlanDetailUseCaseDependencyKey.swift` — **변경 없음** (프로토콜에 메서드가 늘어도 `liveValue` 조립식은 동일)

### 수정

**Domain**
- `Sources/RepositoryProtocol/TravelPlanRepositoryProtocol.swift` — `func update(_ plan: TravelPlan) async throws` 추가
- `Sources/UseCase/TravelPlan/TravelPlanUseCaseProtocol.swift` — 동일 시그니처 추가
- `Sources/UseCase/TravelPlan/TravelPlanUseCase.swift` — Repository 위임 1메서드
- `Sources/UseCase/TravelPlan/TestTravelPlanUseCase.swift` — `plans` 배열에서 `id` 일치 요소 교체(없으면 no-op)
- `Sources/RepositoryProtocol/TravelPlanDetailRepositoryProtocol.swift` — `func removeSpots(planId: UUID, fromDayIndex: Int) async throws` 추가
- `Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCaseProtocol.swift` — 동일 시그니처 추가
- `Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCase.swift` — Repository 위임 1메서드
- `Sources/UseCase/TravelPlanDetail/TestTravelPlanDetailUseCase.swift` — `dayIndex < fromDayIndex`만 남기도록 필터

**Data**
- `Sources/Repository/TravelPlan/TravelPlanRepository.swift` — `update(_:)` 구현 (id로 `TravelPlanModel` 조회 → 필드 대입 → `save()`)
- `Sources/Repository/TravelPlanDetail/TravelPlanDetailRepository.swift` — `removeSpots(planId:fromDayIndex:)` 구현 (`planId` + `dayIndex >= fromDayIndex` 조회 → 전부 `delete` → `save()`)
- `Sources/SwiftData/TravelPlanModel.swift`, `Extension/TravelPlanModel+.swift` — **변경 없음** (스키마 변경 없음, 기존 필드 대입만)

**DesignSystem**
- `Sources/Map/TabiMapMarker.swift` — `public let index: Int?` 추가, `init`의 마지막 파라미터에 `index: Int? = nil` (기존 3개 호출부 무변경 컴파일)
- `Sources/Map/TabiMapMarkerPinView.swift` — `let index: Int?` 추가. `index != nil`이면 숫자 텍스트, `nil`이면 기존 아이콘 렌더 (기존 렌더 결과 100% 동일)
- `Sources/Map/TabiMapMarkerImageFactory.swift` — `image(icon:color:index:)`로 확장, `reuseIdentifier`에 index 포함
- `Sources/Map/TabiMapView+Coordinator.swift` — `markerAppearances` 튜플에 `index` 추가 + factory 호출 2곳(plain / clustered leaf)에 index 전달
- `Sources/Map/TabiMapView.swift` — **변경 없음**

**Presentation**
- `Sources/PlanDetail/PlanDetailFeature.swift`
  - State: `var dayMapFitToken: Int = 0` 추가, `@Presents var editPlanState: PlanDetailEditFeature.State?` 추가(`@Presents` 블록 최하단)
  - Action: `case planEditMenuButtonTapped`(인터랙션 구역), `case editPlan(PresentationAction<PlanDetailEditFeature.Action>)`(하위 액션, 마지막)
  - `.dayButtonTapped`: 새 일자에 좌표 유효 스팟이 있으면 `dayMapFitToken += 1`
  - `.travelPlanDetailResult`: 대입 후 선택 일자에 좌표 유효 스팟이 있으면 `dayMapFitToken += 1`
  - `.editPlan(.presented(.planUpdated(let plan)))`: `state.plan = plan`, `selectedDayIndex = min(selectedDayIndex, plan.dayCount - 1)`, `editPlanState = nil`, `isEditing`/`editingSpots` 초기화, `fetchTravelPlanDetailEffect` 재호출
  - body 마지막에 `.ifLet(\.$editPlanState, action: \.editPlan) { PlanDetailEditFeature() }`
- `Sources/PlanDetail/PlanDetailView.swift`
  - 툴바 `Menu`에 `Strings.Plan.planEditMenuTitle` 항목 추가 (기존 `editMenuTitle` 항목 유지)
  - `// TODO: 지도 영역 추가` + `EmptyView()` 제거 → `PlanDetailMapSection` 호출로 교체
  - 컨테이너 재구성: 지도를 `.id(selectedDayIndex)` 밖으로 빼고, 헤더 블록 / 리스트 블록에 각각 `.id` + 기존 좌우 전환 `transition` 부여
  - `PlanDetailSpotRow`에 `index: offset + 1` 전달
  - `editActionButtons()`의 취소 버튼 `style: .secondary` → `.ghost`
  - `.sheet(item: self.$store.scope(state: \.editPlanState, action: \.editPlan))` 추가
- `Sources/PlanDetail/Sub/PlanDetailSpotRow.swift` — `let index: Int` 추가, 타임라인 원 10 → 22 지름 + 내부 순번 텍스트(`captionXSBold`, `tabiOnColor`), `timeline`의 `frame(width: 10)` → 22
- `Sources/PlanDetail/Model/TravelPlanDetailSpot+.swift` — `import DesignSystem` 추가 + `func toMapMarker(index: Int) -> TabiMapMarker?` (좌표 무효 시 `nil`)
- `Sources/Plan/Model/TravelPlan+.swift` — `static func dayCount(startDate:endDate:) -> Int` 추가하고 기존 인스턴스 `dayCount`가 이를 호출하도록 위임 (계산식 동일, 동작 변화 없음)
- `Sources/AddTravelPlan/Sub/AddPlanDateRangeView.swift` — `var initialMonth: Date = Date()` 파라미터 추가 후 `TabiRangeCalendar(initialMonth:)`에 전달 (`AddTravelPlanView` 호출부 무변경)

### 삭제
- 없음
- `TabiButton`의 `.secondary` 스타일 정의와 `DetailMapTabView`의 `.secondary` 버튼, `RegionSpot` / `Festival` / `DetailView`의 `.ghost` 재시도 버튼은 손대지 않는다 (spec 불변 조건)
- `AddTravelPlanFeature` / `AddTravelPlanView` / `AddPlanBottomCTAView` / `AddPlanRegionGridView`는 수정하지 않는다 (`AddPlanDateRangeView`만 하위 호환 파라미터 1개 추가)

---

## 기술적 결정사항

- **플랜 편집은 `AddTravelPlanFeature` 재사용이 아니라 새 Feature로 만든다**: ① 입력 항목이 다르다(region/emoji 없음 → `isConfirmEnabled`의 필수 조건 자체가 다름), ② 종단 동작이 `add`가 아니라 `update`이고 축소 확인 알럿이라는 분기가 추가된다, ③ `AddTravelPlanFeature.State`는 빈 값에서 시작하지만 편집은 기존 plan을 주입받아 시작한다. 모드 플래그로 한 Feature에 합치면 지역/이모지 검증과 알럿 분기가 서로 얽혀 두 화면이 동시에 취약해진다
- **뷰 계층은 `AddPlanDateRangeView`만 공유한다**: spec이 명시한 재사용 대상이며, 날짜 두 박스 + 범위 캘린더는 편집에서도 동일하다. 반면 `AddPlanBottomCTAView`는 타이틀이 `Strings.Plan.confirmButton`("日程を作成する")로 하드코딩돼 있어 그대로 쓸 수 없고, 파라미터화하면 다른 화면의 `Sub/`를 양방향으로 얽는다("Sub는 해당 화면 전용" 전제). 편집 시트는 동일 시각 스펙(`.primary`, `isExpanded`, `height: 45`, `cornerRadius: .tabiRadiusFull`)의 `TabiButton`을 뷰 내부에 직접 둔다
- **`AddPlanDateRangeView`에 `initialMonth`를 추가한다**: `TabiRangeCalendar.initialMonth` 기본값이 `Date()`라, 3개월 뒤 여행을 편집하면 캘린더가 이번 달에서 열리고 사용자가 매번 월을 넘겨야 한다. 편집 시 `plan.startDate`를 넘겨 기존 선택 구간이 보이는 달에서 시작하게 한다. 기본값이 있으므로 `AddTravelPlanView`는 무변경
- **`dayCount` 계산은 Presentation에 유지한다**: `TravelPlan.dayCount`는 이미 `Presentation/Plan/Model/TravelPlan+.swift`의 확장이다. 이를 Domain으로 올리면 이번 작업 범위를 넘는 이동이 생긴다. 대신 "선택된 두 날짜의 일수"가 필요하므로 같은 파일에 `static func dayCount(startDate:endDate:)`를 추가하고 인스턴스 프로퍼티가 이를 호출하게 해 계산식 중복을 없앤다. Domain의 `removeSpots`는 `fromDayIndex: Int`만 받아 캘린더 계산을 전혀 모른다
- **축소 시 "스팟 삭제 → 플랜 저장"을 하나의 Effect에서 순차 await 한다**: spec의 "삭제 실패 시 저장을 진행하지 않는다"를 지키려면 두 호출이 같은 Effect 안에 있어야 한다. Action 왕복으로 쪼개면 중간에 시트가 닫히거나 재탭이 끼어들 여지가 생긴다. 삭제가 throw되면 `update`를 호출하지 않고 `.saveFailed`만 보낸다(플랜 기간은 그대로 남아 데이터가 항상 "기간 ⊇ 스팟" 관계를 유지)
- **`dayCount`가 같거나 늘어나는 경우는 알럿 없이 `update`만 호출한다**: 늘어날 때 새 dayIndex에 스팟이 없는 것은 정상 상태이고, 줄지 않으므로 삭제 대상이 없다. day 배정(`dayIndex`)은 시작일이 바뀌어도 재계산하지 않는다 — spec에 재배정 요구가 없고, `dayIndex`는 "N일차"라는 상대 개념이라 시작일 이동 시 함께 이동하는 것이 사용자 기대에 맞다
- **`TravelPlanRepository.update`는 대상 모델이 없으면 `persistenceFailed`를 throw 한다**: `removeSpot`은 "이미 지워진 항목 재탭"이 정상 경로라 조용히 return 하지만, 여기서 조용히 성공하면 UI가 "저장됨"으로 오인하고 화면 값과 DB가 어긋난다. 실패를 드러내 알럿으로 이어지게 한다
- **저장 성공 시 자식은 `.planUpdated(TravelPlan)`만 보내고 시트 닫기/상태 반영은 부모가 한다**: `PlanDetailAddSpotFeature.spotAdded`와 동일 규약. 부모가 `plan` 갱신 + `selectedDayIndex` 클램프 + detail 재조회를 같은 액션에서 처리해, "시트 닫힘"과 "화면 갱신" 사이의 중간 상태가 노출되지 않는다
- **부모는 저장 후 `travelPlanDetail`을 로컬 병합하지 않고 전체 재조회한다**: 축소 저장 시 어떤 스팟이 사라졌는지 정확히 아는 주체는 SwiftData다. 기존 `fetchTravelPlanDetailEffect`를 그대로 쓰므로 신규 코드가 거의 없다. 동시에 `selectedDayIndex`를 `min(selectedDayIndex, dayCount - 1)`로 클램프해, 4박이던 플랜의 4일차를 보던 중 2일로 줄이면 마지막 일자로 이동시킨다(빈 화면/인덱스 이탈 방지)
- **`isEditing`(스팟 순서 편집)은 플랜 편집 저장 시 해제한다**: 순서 편집 중에는 `"..."` 메뉴가 노출되지 않으므로 동시 진입은 불가하지만, 저장 결과가 `editingSpots`(스냅샷)와 어긋날 수 있어 방어적으로 초기화한다
- **취소 버튼은 `.ghost`로 바꾸기만 한다**: `.ghost`는 이미 보더 없음 + `bodyM`(non-bold) + `tabiBackground`로 spec 요구와 정확히 일치한다. `TabiButton`을 수정하지 않으므로 `.secondary`를 쓰는 `DetailMapTabView`와 `.ghost`를 쓰는 재시도 버튼 4곳에 회귀가 없다. `isExpanded: true`는 유지해 저장 버튼과의 5:5 분할 레이아웃을 그대로 둔다
- **타임라인 순번은 `spot.order`가 아니라 화면 표시 인덱스(`enumerated().offset + 1`)를 주입한다**: 편집모드의 `editingSpots`는 저장 전이라 `order`가 재계산되지 않은 상태다. `order`를 쓰면 드래그 중 숫자가 리스트 순서와 어긋난다. 행 컴포넌트는 이미 `isFirst` / `isLast`를 인덱스 기반으로 받고 있어 파라미터 추가 비용도 낮다
- **원 지름을 10 → 22로 키우고 `timeline`의 `frame(width:)`도 함께 22로 바꾼다**: 현재 `VStack`이 `frame(width: 10)`으로 고정돼 있어 원만 키우면 세로선/카드 정렬이 밀린다. 폭을 함께 올려 시간 라벨(40pt) → 타임라인(22pt) → 카드 순서의 정렬을 유지한다. 숫자는 `captionXSBold`(11pt) + `tabiOnColor`로 카테고리 색 원 위 대비를 확보한다
- **지도 마커 id에 순번을 포함한다 (`"\(spot.id.uuidString)-\(index)"`)**: `TabiMapView.Coordinator.syncPlainMarkers`는 `markerCache[marker.id] == nil`인 마커만 새로 만들고 기존 마커의 `iconImage`를 갱신하지 않는다. 따라서 같은 id로 index만 바뀌면 숫자가 갱신되지 않는다. Coordinator에 "기존 마커 갱신" 로직을 넣으면 다른 3개 화면의 마커 동기화 경로까지 건드리게 되어(spec 불변 조건) 회귀 위험이 크다. 호출부에서 id에 index를 섞으면 stale id 제거 + 신규 생성 경로만 타므로 DesignSystem 동기화 로직은 무변경이다. 마커 탭 핸들러가 no-op이라 id 문자열을 파싱하는 곳도 없다
- **`TabiMapMarkerImageFactory.reuseIdentifier`에 index를 넣는다**: spec이 지목한 위험. `NMFOverlayImage`는 `reuseIdentifier` 기준으로 캐시되므로 index를 빼면 1번 마커 이미지가 2번에도 재사용된다. `Coordinator.markerAppearances` 튜플에도 index를 넣어, 클러스터링 경로(`TabiLeafMarkerUpdater`)에서 index가 유실돼 번호 없는 이미지가 그려지는 불일치를 막는다 (PlanDetail은 클러스터링 미사용이지만 시그니처를 한 벌로 유지)
- **`index`는 `Int?`이고 `nil`이면 기존 아이콘 렌더를 그대로 한다**: `AddCustomPlaceView` / `MapView` / `DetailMapTabView`는 `index`를 넘기지 않아 `nil`이 되고, `reuseIdentifier`도 기존과 다른 접미사가 붙을 뿐 렌더 결과가 동일하다
- **지도는 `.id(selectedDayIndex)` 컨테이너 밖에 둔다**: 안에 두면 day 탭마다 `NMFNaverMapView`가 파기/재생성되어 지도 SDK 초기화 + 타일 재로딩 깜빡임이 매 탭마다 발생한다. 지도를 밖으로 빼고 헤더 블록 / 리스트 블록에 각각 `.id` + 기존 `asymmetric(move)` transition을 부여하면, 지도만 제자리에 유지되고 헤더·리스트의 좌우 전환 연출은 유지된다(둘 다 `selectedDayIndex` 변화에 같은 애니메이션으로 반응). 카메라 재조정은 재생성이 아니라 `boundsFitToken` 증가로 처리한다
- **`boundsFitToken`은 Feature State(`dayMapFitToken`)로 관리하고 유효 좌표가 있을 때만 증가시킨다**: `MapFeature.searchResultFitToken` 패턴과 동일. `Coordinator.applyBoundsFitIfNeeded`는 토큰이 바뀌고 마커가 비어있지 않을 때만 카메라를 옮기므로, 좌표 없는 날을 거쳐가도 직전 카메라가 엉뚱하게 튀지 않는다. 좌표 유효 스팟이 하나도 없는 날에는 지도 뷰 자체가 트리에서 제거되고, 다시 마커가 있는 날로 돌아오면 새 Coordinator가 생성되어 첫 sync에서 곧바로 bounds fit이 적용된다
- **지도 마커는 `selectedDaySpots`가 아니라 `displayedSpots` 기준으로 만든다**: 편집모드에서는 리스트가 `editingSpots`를 그리므로, 마커 번호를 리스트와 일치시키려면 같은 소스를 써야 한다. 비편집 상태에서 `displayedSpots == selectedDaySpots`이므로 spec의 명세와 동일하다
- **좌표 무효 스팟은 번호를 부여한 뒤 걸러낸다**: `enumerated()`로 리스트 순번을 먼저 매기고 `toMapMarker(index:)`에서 `coordinate.isValid == false`면 `nil`을 반환해 `compactMap` 한다. 중간에 좌표 없는 스팟이 있어도 지도 번호가 리스트 번호와 어긋나지 않는다(3번만 없는 1·2·4 마커가 정상)
- **마커 탭은 no-op으로 둔다**: spec에 마커 탭 동작이 없고, 스팟 상세로 보내려면 `spotRowTapped` 경로(TabBar 라우팅)까지 엮여 범위가 커진다. `DetailMapTabView` / `AddCustomPlaceView`와 동일하게 `onMarkerTapped: { _ in }`
- **지도 카드 스펙은 기존 임베드 지도 관행을 따른다**: 높이 200(`DetailMapTabView` 300 / `AddCustomPlaceView` 180 사이, 스팟 리스트를 가리지 않는 선), `clipShape(RoundedRectangle(cornerRadius: .tabiRadiusLg))` + `stroke(tabiBorder.opacity(0.4))`, `padding(.horizontal, 20)`, `showsLocationButton: false`, `followsUserLocation: false`, `isClusteringEnabled: false`(하루치 스팟은 최대 수십 개)
- **문자열은 재사용을 우선한다**: 하단 CTA는 `Strings.Plan.editSaveButton`("保存"), 실패 알럿은 `saveFailedAlertTitle` / `saveFailedAlertMessage`, 확인 버튼은 `alertConfirm`을 재사용한다. 신규는 메뉴 항목·시트 타이틀·축소 알럿 2문구·알럿 취소 버튼 5개뿐이다. 알럿 취소는 기존 `editCancelButton`("キャンセル")이 "스팟 순서 편집 취소" 전용 이름이라 의미가 어긋나므로 `alertCancel`을 새로 둔다
- **시작일 > 종료일은 구조적으로 막고 가드로 한 번 더 확인한다**: `TabiRangeCalendar`의 연동 모드가 역순 조합을 만들지 않지만, `AddTravelPlanFeature.confirmTapped`와 동일하게 `startDate <= endDate` 가드를 저장 직전에 둔다. 저장 버튼 비활성 조건은 `제목 비어있지 않음 && startDate != nil && endDate != nil`
- **`isSaving` 중 중복 저장/중복 알럿 차단**: `guard state.isSaving == false`(기존 관행) + 저장 Effect에 `cancellable(id:)`. 실패 시 `isSaving = false`만 되돌리고 입력값과 시트를 유지해 재시도 가능하게 한다 (spec 불변 조건)
- **시트 detent는 `AddTravelPlanView`와 동일하게 `[.medium, .large]`**: 이름 필드 포커스 시 `.large`로 승격하는 동작까지 맞춰 두 화면의 조작감을 통일한다
- **Feature/State/Action은 `public`, View는 `internal`**: `AddTravelPlanFeature`(public) / `PlanDetailAddSpotView`(internal)와 동일 수준

---

## 구현 순서

### Phase 1. Domain
1. `Projects/Domain/Sources/RepositoryProtocol/TravelPlanRepositoryProtocol.swift` — `update(_ plan: TravelPlan) async throws` 추가 (`add` 다음 위치)
2. `Projects/Domain/Sources/UseCase/TravelPlan/TravelPlanUseCaseProtocol.swift` — 동일 시그니처 추가
3. `Projects/Domain/Sources/UseCase/TravelPlan/TravelPlanUseCase.swift` — `repository.update(plan)` 위임
4. `Projects/Domain/Sources/UseCase/TravelPlan/TestTravelPlanUseCase.swift` — `plans`에서 `id` 일치 인덱스 교체, 없으면 아무 것도 하지 않음
5. `Projects/Domain/Sources/RepositoryProtocol/TravelPlanDetailRepositoryProtocol.swift` — `removeSpots(planId: UUID, fromDayIndex: Int) async throws` 추가 (`removeSpot` 다음)
6. `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCaseProtocol.swift` / `TravelPlanDetailUseCase.swift` — 동일 시그니처 + 위임
7. `Projects/Domain/Sources/UseCase/TravelPlanDetail/TestTravelPlanDetailUseCase.swift` — 해당 `planId`의 detail을 `spots.filter { $0.dayIndex < fromDayIndex }`로 교체

### Phase 2. Data
1. `Projects/Data/Sources/Repository/TravelPlan/TravelPlanRepository.swift`
   - `update(_ plan:)`: `ModelContext` 생성 → `FetchDescriptor<TravelPlanModel>(predicate: #Predicate { $0.id == planId })` (`plan.id`를 지역 상수로 캡처해 `#Predicate` 안에서 사용) → 없으면 `AppLogger.core.log(.error, ...)` + `TabiError.persistenceFailed` throw → 있으면 `title` / `regionRaw` / `customRegionText` / `customEmoji` / `startDate` / `endDate` 대입 후 `save()`
   - `do-catch` + `AppLogger.core` + `persistenceFailed` 매핑은 기존 메서드와 동일 형태
2. `Projects/Data/Sources/Repository/TravelPlanDetail/TravelPlanDetailRepository.swift`
   - `removeSpots(planId:fromDayIndex:)`: `#Predicate { $0.planId == planId && $0.dayIndex >= fromDayIndex }`로 조회 → 전부 `context.delete` → `save()`. 대상 0건이면 그대로 `save()`(정상 성공)
   - 실패 시 `AppLogger.core.log(.error, "일정 상세 스팟 일괄 삭제 실패: ...")` + `persistenceFailed`

### Phase 3. Resource
1. `Projects/Resource/Sources/Strings/Strings.swift`의 `Strings.Plan`에 추가 (각 항목에 한국어 주석)
   - `planEditMenuTitle = "予定を編集"` — `"..."` 메뉴의 플랜 편집 항목
   - `editPlanScreenTitle = "日程を編集"` — 편집 시트 타이틀
   - `dayShrinkAlertTitle = "日程が短くなります"`
   - `dayShrinkAlertMessage: ((Int) -> String) = { "\($0)日目以降のスポットは削除されます。よろしいですか？" }` — 인자는 삭제 시작 일차(1-based)
   - `alertCancel = "キャンセル"`
   - 나머지 문구는 기존 재사용(`nameLabel` / `namePlaceholder` / `dateLabel` / `editSaveButton` / `saveFailedAlert*` / `alertConfirm` / `editMenuTitle`)

### Phase 4. DesignSystem (마커 순번)
1. `TabiMapMarker.swift` — `public let index: Int?`, `init(... , color: TabiColor, index: Int? = nil)`
2. `TabiMapMarkerPinView.swift` — `let index: Int?` 추가. 원 + `tabiOnColor` 스트로크는 유지하고 overlay 내용만 분기: `index`가 있으면 `Text("\(index)")` (`.system(size: 14, weight: .bold)`, `tabiOnColor`), 없으면 기존 `Image(icon)`
3. `TabiMapMarkerImageFactory.swift` — `static func image(icon:color:index:)`, `reuseIdentifier = "\(icon.rawValue)-\(color.rawValue)-\(index.map(String.init) ?? "noIndex")"`, `TabiMapMarkerPinView(icon:color:index:)` 전달
4. `TabiMapView+Coordinator.swift`
   - `markerAppearances: [String: (icon: TabiIcon, color: TabiColor, index: Int?)]`
   - `syncPlainMarkers`: `TabiMapMarkerImageFactory.image(icon: marker.icon, color: marker.color, index: marker.index)`
   - `syncClusteredMarkers`: `markerAppearances[marker.id] = (marker.icon, marker.color, marker.index)`
   - `TabiLeafMarkerUpdater.appearanceProvider` 타입 및 호출부에 `index` 반영
   - 마커 생성/제거 로직(`newIDs` / `staleIDs` 비교)은 **변경하지 않는다**

### Phase 5. Presentation — 플랜 편집 시트 (신규 Feature)
1. `Projects/Presentation/Sources/Plan/Model/TravelPlan+.swift` — `static func dayCount(startDate: Date, endDate: Date) -> Int` 추가 후 인스턴스 `dayCount`가 위임
2. `Projects/Presentation/Sources/AddTravelPlan/Sub/AddPlanDateRangeView.swift` — `var initialMonth: Date = Date()` 추가 → `TabiRangeCalendar(startDate:endDate:initialMonth:)`
3. `Projects/Presentation/Sources/PlanDetailEdit/PlanDetailEditFeature.swift` 신규
   - 의존성: `@Dependency(\.travelPlanUseCase)`, `@Dependency(\.travelPlanDetailUseCase)`, `@Dependency(\.dismiss)`
   - State (공개 → fileprivate → `@Presents` 순)
     - `title: String`, `startDate: Date?`, `endDate: Date?`, `isSaving: Bool = false`
     - `fileprivate let plan: TravelPlan` (원본 — id / region / customRegionText / customEmoji 보존 및 기존 `dayCount` 비교용)
     - 계산: `trimmedTitle`, `isConfirmEnabled`(제목 non-empty + 두 날짜 non-nil), `newDayCount: Int?`, `currentDayCount: Int`
     - `@Presents var alert: AlertState<Action.Alert>?`
     - `public init(plan: TravelPlan)` — `title` / `startDate` / `endDate`를 plan 값으로 프리필
   - Action (`BindableAction, Equatable`): `binding` → `closeButtonTapped`, `confirmButtonTapped` → `planUpdated(TravelPlan)`, `saveFailed` → `alert(PresentationAction<Alert>)`
     - `public enum Alert: Equatable { case shrinkConfirmed }`
   - Reduce
     - `.closeButtonTapped`: `.run { await dismiss() }`
     - `.confirmButtonTapped`: `isSaving == false && isConfirmEnabled`, `startDate <= endDate` 가드 → 갱신 plan(`title`/`startDate`/`endDate`만 교체) 생성 → `newDayCount >= currentDayCount`면 `isSaving = true` + `saveEffect(plan:)`, 작을 때는 State 변경 없이 축소 확인 알럿만 표시(`dayShrinkAlertTitle`, `dayShrinkAlertMessage(newDayCount + 1)`, 확인 = `.destructive` + `.shrinkConfirmed`, 취소 = `ButtonState(role: .cancel)` + `alertCancel`)
     - `.alert(.presented(.shrinkConfirmed))`: `isSaving = true` → `shrinkAndSaveEffect(plan:fromDayIndex: newDayCount)`
     - `.alert(.dismiss)` 및 취소: 아무 변경 없음(`.none`) — spec의 "취소 시 시트 유지, 변경 없음"
     - `.planUpdated`: `.none` (부모가 처리)
     - `.saveFailed`: `isSaving = false` + `saveFailedAlertTitle` / `saveFailedAlertMessage` 알럿
   - `private enum CancelID { case save }`, 저장 Effect에 `.cancellable(id: CancelID.save)`
   - `// MARK: - Method` `private extension`
     - `saveEffect(plan:)` — `update` 성공 시 `.planUpdated(plan)`, 실패 시 `AppLogger.view.log(.error, ...)` + `.saveFailed`
     - `shrinkAndSaveEffect(plan:fromDayIndex:)` — `removeSpots` → 같은 Effect에서 `update` 순차 실행. 어느 단계든 throw면 로깅 + `.saveFailed`(삭제 실패 시 `update` 미실행)
4. `Projects/Presentation/Sources/PlanDetailEdit/PlanDetailEditView.swift` 신규
   - `@Bindable private var store`, `@FocusState private var isTitleFocused`, `@State private var selectedDetent: PresentationDetent = .medium`
   - `ScrollView` + `VStack(spacing: 24)`: 이름 섹션(`TabiLabel(nameLabel)` + `TabiTextField(namePlaceholder)`) / 날짜 섹션(`TabiLabel(dateLabel)` + `AddPlanDateRangeView(startDate:endDate:initialMonth: store.plan.startDate 대신 프리필된 startDate ?? Date())`)
   - `safeAreaBar(edge: .top)`: `TabiNavigationBar(title: Strings.Plan.editPlanScreenTitle) { TabiCircleIconButton(systemName: "xmark") }`
   - `safeAreaBar(edge: .bottom)`: `TabiButton(Strings.Plan.editSaveButton, style: .primary, isExpanded: true, isLoading: store.isSaving, height: 45, cornerRadius: .tabiRadiusFull)` + `.disabled(!store.isConfirmEnabled)` + `.padding(.horizontal, 20)`
   - `.presentationDetents([.medium, .large], selection:)`, `.presentationDragIndicator(.visible)`, `.alert($store.scope(state: \.alert, action: \.alert))`, 제목 포커스 시 `.large` 승격
   - `body` 50줄 초과 시 `private extension`의 `nameField()` / `dateSection()` / `closeButton()`로 분리 (`AddTravelPlanView` 구조 동일)
   - `#Preview` — `TravelPlan.mock` 주입

### Phase 6. Presentation — PlanDetail 연결 (메뉴 / 취소 버튼 / 순번 / 지도)
1. `Sources/PlanDetail/Model/TravelPlanDetailSpot+.swift` — `import DesignSystem` + `func toMapMarker(index: Int) -> TabiMapMarker?`
   - `guard self.coordinate.isValid`, `id: "\(self.id.uuidString)-\(index)"`, `title: self.title.truncated(to: 15)`, `icon: self.category.icon`, `color: self.category.color`, `index: index`
2. `Sources/PlanDetail/Sub/PlanDetailSpotRow.swift`
   - `let index: Int` 추가 (`spot` 다음)
   - `timeline`: `Circle().fill(self.spot.category.color).frame(width: 22, height: 22)` + `overlay { TabiLabel(title: "\(self.index)", style: .captionXSBold, color: .tabiOnColor) }`, 감싼 `VStack`의 `frame(width: 10)` → `frame(width: 22)`
   - 위/아래 세로선 세그먼트와 `isFirst` / `isLast` 처리는 그대로
3. `Sources/PlanDetail/Sub/PlanDetailMapSection.swift` 신규
   - `let markers: [TabiMapMarker]`, `let fitToken: Int`
   - `TabiMapView(centerLatitude: markers.first?.latitude ?? Coordinate.seoulCityHall.latitude, centerLongitude: ..., markers:, isClusteringEnabled: false, showsLocationButton: false, followsUserLocation: false, boundsFitToken: fitToken, onMapTapped: { _, _ in }, onMarkerTapped: { _ in })`
   - `.frame(height: 200)` + `clipShape(.tabiRadiusLg)` + `stroke(tabiBorder.opacity(0.4))` + `.padding(.horizontal, 20)`
4. `Sources/PlanDetail/PlanDetailFeature.swift`
   - State: `var dayMapFitToken: Int = 0`, `@Presents var editPlanState: PlanDetailEditFeature.State?`
   - Action: `case planEditMenuButtonTapped`, `case editPlan(PresentationAction<PlanDetailEditFeature.Action>)`
   - `.planEditMenuButtonTapped`: `state.editPlanState = PlanDetailEditFeature.State(plan: state.plan)`
   - `.dayButtonTapped(index:)`: 인덱스 갱신 후, 해당 일자 스팟에 `coordinate.isValid`가 하나라도 있으면 `dayMapFitToken += 1`
   - `.travelPlanDetailResult(let detail)`: 대입 후 선택 일자 기준 동일 조건으로 `dayMapFitToken += 1`
   - `.editPlan(.presented(.planUpdated(let plan)))`: `state.plan = plan` → `state.selectedDayIndex = min(state.selectedDayIndex, plan.dayCount - 1)` → `isEditing = false` / `editingSpots = []` / `isSaving = false` → `editPlanState = nil` → `fetchTravelPlanDetailEffect(id: plan.id)` (기존 `.cancel(id: CancelID.saveEditedSpots)`와 충돌하지 않도록 `.merge` 또는 순서 정리)
   - `.editPlan`: `.none`
   - body 마지막에 `.ifLet(\.$editPlanState, action: \.editPlan) { PlanDetailEditFeature() }`
5. `Sources/PlanDetail/PlanDetailView.swift`
   - 툴바 `Menu`에 `Button(Strings.Plan.planEditMenuTitle) { store.send(.planEditMenuButtonTapped) }` 추가 (기존 `editMenuTitle` 항목 아래)
   - 본문 재구성
     - `dayTabScroll(plan:)` 유지
     - 헤더 블록(`PlanDetailDayHeader`)에 `.id(store.selectedDayIndex)` + 기존 `asymmetric(move)` transition
     - `let markers = self.selectedDayMarkers`; `if markers.isEmpty == false { PlanDetailMapSection(markers: markers, fitToken: store.dayMapFitToken) }` — `.id` 없음
     - 리스트 블록(`spotList()`)에 `.id(store.selectedDayIndex)` + 동일 transition
     - 루트의 `.animation(.tabiStandard, value: store.selectedDayIndex)` / `.animation(.tabiStandard, value: store.isEditing)` 유지
   - `private extension`에 `var selectedDayMarkers: [TabiMapMarker]` — `store.displayedSpots.enumerated().compactMap { $0.element.toMapMarker(index: $0.offset + 1) }`
   - `ForEach`에서 `PlanDetailSpotRow(spot:index: index + 1, isFirst:isLast:isEditing:)`
   - `editActionButtons()`의 취소 버튼 `style: .secondary` → `.ghost` (나머지 파라미터 유지)
   - `.sheet(item: self.$store.scope(state: \.editPlanState, action: \.editPlan)) { PlanDetailEditView(store: $0) }`

### Phase 7. 빌드 / 검증
1. `tuist generate` — 신규 파일 3개(`PlanDetailEditFeature`, `PlanDetailEditView`, `PlanDetailMapSection`) + 신규 폴더 `PlanDetailEdit/` 추가로 필수
2. 빌드 후 시나리오 확인
   - `"..."` → `予定を編集` → 이름/날짜 수정 → 저장 → 내비게이션 타이틀·day 탭 개수 즉시 반영, 뒤로 가면 일정 목록(`PlanFeature.onAppear` 재조회)에도 반영
   - 일수 동일/증가 → 알럿 없이 저장, 기존 스팟 유지
   - 일수 축소 → 알럿 취소 시 시트 유지 + 스팟 유지 / 확인 시 초과 dayIndex 스팟 삭제 후 저장, 마지막 일자로 선택 이동
   - 제목 비우기 / 날짜 미선택 → 저장 버튼 비활성
   - 편집모드 취소 버튼: 보더 없음 + non-bold, 저장 버튼과 5:5 유지
   - 타임라인 원 안 1,2,3… 표시 및 시간 라벨/카드 정렬 유지 (편집모드 드래그 후 번호 재정렬 확인)
   - 좌표 유효 스팟 있는 날 → 지도 표시 + 마커 번호 일치, day 전환 시 카메라 재조정 + 지도 깜빡임 없음
   - 좌표 유효 스팟 0인 날 → 지도 영역 미표시
   - 회귀: `MapView` 검색 마커(클러스터 off/on), `DetailView` 지도 탭, `AddCustomPlaceView` 미리보기 마커가 기존과 동일하게 보이는지 확인

---

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
- [ ] `"..."` 메뉴에 `編集`(스팟 순서)과 `予定を編集`(플랜) 두 항목이 있고, 후자가 이름/날짜 수정 시트를 연다
- [ ] `dayCount`가 같거나 늘어나면 알럿 없이 저장되고, 스팟 데이터가 유지된다
- [ ] `dayCount`가 줄어들면 알럿이 뜨고, 확인 시 `removeSpots(planId:fromDayIndex:)` → `update(_:)` 순서로 처리되며, 취소 시 DB·State 변경이 없다
- [ ] `removeSpots` 실패 시 `update`가 호출되지 않고 실패 알럿이 뜨며 시트가 유지된다 (`isSaving` 해제)
- [ ] 저장 후 PlanDetail의 타이틀 / day 탭 / 스팟 목록이 재조회로 갱신되고 `selectedDayIndex`가 범위를 벗어나지 않는다
- [ ] 편집모드 취소 버튼이 `.ghost`로 표시되고, `DetailMapTabView`의 `.secondary` 버튼과 `RegionSpot` / `Festival` / `Detail`의 `.ghost` 재시도 버튼은 기존과 동일하다
- [ ] 타임라인 원 안에 1부터 시작하는 순번이 보이고 리스트 정렬이 깨지지 않는다
- [ ] 좌표 유효 스팟이 있는 날에만 지도가 보이고, 마커에 리스트와 같은 번호가 표시되며 day 전환 시 카메라가 재조정된다
- [ ] day 전환 시 지도 뷰가 재생성되지 않는다 (헤더/리스트만 좌우 전환)
- [ ] `TabiButton`은 수정되지 않았고, `TabiMapMarker` 기존 호출부 3곳은 코드 변경 없이 컴파일·동작한다
- [ ] `TabiMapMarkerImageFactory`의 캐시 키에 index가 포함되어 서로 다른 순번 마커가 같은 이미지를 재사용하지 않는다
- [ ] `tuist generate` 후 빌드 성공

---

### 구현 시 주의점 (파일에 포함되지 않는 보충 메모)
- `PlanDetailFeature`의 `.editPlan(.presented(.planUpdated))` 처리에서 기존 `CancelID.saveEditedSpots` 취소와 재조회 Effect를 함께 반환해야 하면 `.merge(...)`를 사용하세요.
- `Data`의 `#Predicate`는 `plan.id` / `fromDayIndex`를 지역 상수로 캡처한 뒤 사용해야 컴파일됩니다.

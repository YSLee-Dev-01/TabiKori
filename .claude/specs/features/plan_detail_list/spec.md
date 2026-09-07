# plan_detail_list

## 무엇을 하는가
PlanDetailView에서 선택된 날짜(Day)의 스팟 목록을 보여주는 화면. 사용자가 일정에 등록한 관광지/음식점 등을 시간순으로 확인하고, 필요 없는 항목은 스와이프로 삭제할 수 있다. 상단 지도 자리는 이번 범위에서 EmptyView로만 채우고(추후 별도 기능), 리스트만 스크롤되도록 해 지도가 항상 화면에 고정되어 보이게 한다.

## 동작 명세
- 트리거:
  - `PlanDetailView` 진입(`onAppear`) 시 이미 조회된 `travelPlanDetailUseCase.fetch(planId:)` 결과(`state.travelPlanDetail`)를 화면에 실제로 렌더링
  - Day 탭 버튼 전환(`dayButtonTapped(index:)`) 시 해당 Day에 속한 스팟만 필터링되어 표시
  - 스팟 카드를 오른쪽에서 왼쪽으로 스와이프 → 삭제 버튼 노출 → 탭 시 삭제(`spotDeleteButtonTapped(id:)`)
- 결과:
  - 선택된 Day에 스팟이 없으면: 캘린더 아이콘 + "まだスポットがありません" 제목 + "観光地や飲食店の詳細ページから「日程に追加する」で追加できます" 설명이 담긴 점선(dash) 테두리 카드 표시
  - 선택된 Day에 스팟이 있으면: 시간("HH:mm") + 타임라인 dot(카테고리 색상)/세로선 + 카드(카테고리 태그, 제목, 부제, 소요시간) 형태의 로우가 `order` 순으로 세로 나열
  - Day 헤더에 캘린더 아이콘 + "M月d日（E）" 날짜(전각 괄호, 요일 포함) + 스팟 개수 안내 텍스트("スポットがまだ追加されていません" / "N件のスポットが追加されています") 표시
  - 지도 영역은 `EmptyView()`만 배치, 리스트 스크롤과 무관하게 고정 위치 유지(헤더/지도는 `ScrollView` 밖, 리스트만 `ScrollView` 안)
  - 스와이프 삭제 성공 시 해당 카드가 화면에서 사라짐
- 사이드이펙트:
  - `spotDeleteButtonTapped(id:)` → `travelPlanDetailUseCase.removeSpot(planId:spotId:)` 호출 → SwiftData에서 해당 스팟 레코드 삭제(재조회해도 복원되지 않음)
  - 삭제 성공 응답 후에만 `state.travelPlanDetail?.spots`에서 해당 항목 제거(낙관적 업데이트 없음)
- 불변 조건:
  - `state.travelPlanDetail`이 `nil`이거나 스팟이 없어도 크래시 없이 빈 상태 카드가 표시된다
  - 지도 영역(EmptyView)은 리스트를 스크롤해도 함께 움직이지 않는다
  - 스팟 목록은 항상 `dayIndex`로 필터링 + `order` 오름차순 정렬 상태로 렌더링된다

## 무엇이 잘못될 수 있는가
- `travelPlanDetailUseCase.removeSpot(planId:spotId:)` 실패(SwiftData 삭제 실패) → `AppLogger.view.log(.error, ...)`로 로깅만 하고 화면 State는 그대로 유지(카드가 사라지지 않음, 재시도 UI 없음)
- `state.travelPlanDetail`이 `nil`(아직 생성된 적 없는 일정) → 스팟 없음과 동일하게 취급해 빈 상태 카드 표시, 크래시 없음
- 존재하지 않는 `spotId`로 삭제 시도(이미 삭제된 항목을 재탭 등) → Repository에서 조회되는 레코드가 없으므로 삭제 동작 없이 조용히 종료(에러 throw 없음)

## 무엇에 의존하는가
### 의존성
- `Domain/Sources/Entity/TravelPlanDetailSpot.swift` (신규) — `id`, `dayIndex`(0-based), `order`, `category: CategoryType`, `title`, `subtitle`, `startTime`, `durationMinutes`
- `Domain/Sources/Entity/TravelPlanDetail.swift` — `spots: [TravelPlanDetailSpot]` 필드 추가(기본값 `[]`, 기존 `init(planId:)` 시그니처 유지)
- `TravelPlanDetailRepositoryProtocol`/`TravelPlanDetailUseCaseProtocol` — `removeSpot(planId:spotId:) async throws` 신규 추가
- `TestTravelPlanDetailUseCase`(Domain) — `removeSpot` 구현 추가, 기존 `public var details` 그대로 재사용
- `Data/Sources/SwiftData/TravelPlanDetailSpotModel.swift` (신규) — `TravelPlanDetailModel`과 동일하게 `@Relationship` 없이 `planId` 평면 참조, `TravelPlanModelContainer`의 `Schema`에 등록
- `Data/Sources/Extension/TravelPlanDetailSpotModel+.swift` (신규) — `toDomain`/`init(spot:planId:)` 매핑
- `TravelPlanDetailRepository`(Data) — `fetch(planId:)`에서 스팟 모델까지 조회해 매핑, `removeSpot(planId:spotId:)` 신규 구현
- `CategoryType`(Domain) + `CategoryType+.swift`(Presentation/Home/Model) — 기존 `icon`/`color`/`label` 확장 재사용, 새 카테고리 추가하지 않음
- `TabiCard`, `TabiTag`, `TabiLabel`(DesignSystem) — 스팟 카드/태그/텍스트 재사용
- `Presentation/Sources/PlanDetail/PlanDetailFeature.swift` — `spotDeleteButtonTapped(id:)`/삭제 결과 Action 추가, 선택 Day 스팟 필터링 로직
- `Presentation/Sources/PlanDetail/PlanDetailView.swift` — 기존 `Spacer()` 자리에 Day 헤더/지도(EmptyView)/리스트 구조 추가
- `Presentation/Sources/PlanDetail/Sub/PlanDetailSpotEmptyState.swift` (신규), `Presentation/Sources/PlanDetail/Sub/PlanDetailSpotRow.swift` (신규)
- `Presentation/Sources/PlanDetail/Model/TravelPlanDetailSpot+.swift` (신규) — `startTimeTitle`, `durationTitle` 계산 프로퍼티
- `Presentation/Sources/Extension/Date+.swift` — "M月d日（E）"(전각 괄호) 포맷 프로퍼티 신규
- `Resource/Sources/Strings/Strings.swift`의 `Strings.Plan` — 빈 상태 제목/설명, 스팟 개수 안내 문자열 신규
- `Presentation/Sources/PlanDetail/PlanDetailMock.swift` (신규, Preview용) — `DetailMock.swift` 패턴 참고

### 제약
- 지도 영역은 실제로 `EmptyView()`만 배치한다 — 이미지의 지도 카드 UI(핀, 마커, "スポットを追加するとマップに表示されます" 등)는 재현하지 않음(추후 별도 기능)
- 드래그 재정렬 핸들(⠿)은 그리지 않는다 — 순서 변경 UI는 별도 편집모드 기능에서 추가 예정
- 삭제 버튼 아이콘(휴지통)은 그리지 않는다 — `.swipeActions(edge: .trailing)`으로만 삭제 동작 제공
- `AddTravelPlanFeature`(일정 생성 플로우) 등 스팟 생성 관련 코드는 이번 범위에 없음 — 건드리지 않는다
- `TravelPlanUseCaseProtocol` 등 이번 기능과 무관한 다른 Repository/UseCase는 수정하지 않는다
- 새 `.swift` 파일 추가 시 `tuist generate` 필수

## Acceptance Criteria
- [x] 선택된 Day에 스팟이 없으면 점선 테두리의 빈 상태 카드("まだスポットがありません")가 표시된다
- [x] 선택된 Day에 스팟이 있으면 시간+타임라인+카드 형태의 로우가 `order` 순으로 표시된다
- [x] Day 탭 버튼 전환 시 해당 Day의 스팟만 필터링되어 표시된다
- [x] 지도(EmptyView) 영역은 리스트를 스크롤해도 함께 움직이지 않는다(헤더/지도 고정, 리스트만 스크롤)
- [x] 스팟 카드를 오른쪽에서 왼쪽으로 스와이프 → 삭제 버튼 탭 → 카드가 사라지고 SwiftData에서도 삭제되어 재조회 시 복원되지 않는다
- [x] `removeSpot` 실패 시 크래시 없이 `AppLogger.view`로 로깅만 되고 화면은 그대로 유지된다
- [x] `tuist generate` 후 `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` BUILD SUCCEEDED

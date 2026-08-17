# plan_detail_map

## 무엇을 하는가
PlanDetail(일정 상세) 화면에서 플랜 자체(이름/날짜)를 수정할 수 있게 하고, 편집모드 취소 버튼의 스타일을 정리하며, 스팟 타임라인에 순번을 표시하고, 선택된 일자의 스팟 위치를 지도로 보여준다. 사용자가 일정을 세울 때 날짜/이름을 손쉽게 고치고, 하루 동선을 시각적으로 파악할 수 있게 하는 것이 목적이다.

## 동작 명세

### 1. 플랜 자체 수정 메뉴
- 트리거: PlanDetailView `"..."` 메뉴에서 신규 항목("予定を編集" 등, 기존 스팟 편집용 "編集"과는 별도) 탭
- 결과: 이름(`title`)과 날짜 범위(`startDate`/`endDate`)를 수정하는 시트가 열린다(`AddTravelPlanView` 구조 참고, region/emoji 입력 없음). 저장 시:
  - 새 `dayCount` == 기존 `plan.dayCount` → day 배정 유지, 즉시 저장
  - 새 `dayCount` > 기존 `plan.dayCount` → 데이터 손실 없음, 즉시 저장
  - 새 `dayCount` < 기존 `plan.dayCount` → 확인 알럿 표시. 확인 시 새 `dayCount` 이상인 `dayIndex`의 스팟을 전부 삭제("뒤에서부터 자름") 후 저장, 취소 시 시트 유지하고 아무 변경 없음
- 사이드이펙트: `TravelPlan` 영속 데이터 갱신(SwiftData), 날짜 축소 시 `TravelPlanDetailSpot` 일괄 삭제
- 불변 조건: 저장 실패 시 기존 플랜/스팟 데이터는 변경되지 않아야 한다. 알럿 취소 시 스팟은 삭제되지 않아야 한다.

### 2. 편집모드 취소 버튼 스타일
- 트리거: PlanDetailView 편집모드 진입(스팟 순서 편집)
- 결과: 취소 버튼이 보더 없이 non-bold로 표시됨(`TabiButton` `.ghost` 스타일 재사용)
- 사이드이펙트: 없음(순수 UI)
- 불변 조건: 다른 화면의 `.secondary` 버튼(RegionSpot 재시도 버튼 등) 표시는 변경되지 않아야 한다.

### 3. 타임라인 원 안 순번 표시
- 트리거: PlanDetail 스팟 리스트 렌더링
- 결과: `PlanDetailSpotRow`의 타임라인 원 안에 해당 스팟의 리스트 순번(1부터 시작)이 표시됨
- 사이드이펙트: 없음(순수 UI)
- 불변 조건: 원 크기가 커져도 리스트 레이아웃(시간 라벨, 카드) 정렬이 깨지지 않아야 한다.

### 4. 선택된 일자 스팟 지도 표시
- 트리거: PlanDetail day 헤더 아래 지도 영역 렌더링 / day 탭 전환
- 결과: `selectedDaySpots` 중 좌표가 유효한 스팟이 마커로 표시되고, 각 마커에 리스트 순번이 표시된다. day 전환 시 카메라가 해당 일자 마커들에 맞춰 재조정된다
- 사이드이펙트: 없음(순수 UI, 지도 렌더링)
- 불변 조건: 좌표가 유효한 스팟이 하나도 없으면 지도 영역이 표시되지 않아야 한다. 다른 화면(`AddCustomPlaceView`/`MapView`/`DetailMapTabView`)의 마커 표시는 기존과 동일하게 유지되어야 한다.

## 무엇이 잘못될 수 있는가
- 플랜 수정 저장(update) 중 네트워크/DB 오류 → `TabiError.persistenceFailed`, 저장 실패 알럿 표시, 시트는 유지
- 날짜 축소 확인 후 스팟 삭제(`removeSpots`) 실패 → 플랜 저장을 진행하지 않고 실패 알럿 표시(부분 삭제로 인한 데이터 불일치 방지)
- 시작일이 종료일보다 늦게 입력됨 → 저장 버튼 비활성화(기존 `AddTravelPlanFeature.isConfirmEnabled` 패턴과 동일하게 처리)
- 좌표가 유효하지 않은 스팟만 있는 날 → 지도 영역 미표시(에러 아님, 정상 케이스)
- `TabiMapMarker`에 index 추가 후 캐시 키 미반영 → 다른 순번의 마커가 잘못된(이전 캐시) 이미지로 표시될 수 있음 → `TabiMapMarkerImageFactory`의 `reuseIdentifier`에 index 포함 필수

## 무엇에 의존하는가
### 의존성
- `TravelPlanUseCaseProtocol`/`TravelPlanRepositoryProtocol`에 신규 `update(_ plan: TravelPlan) async throws` 필요 (현재 fetch/add/remove만 존재)
- `TravelPlanDetailUseCaseProtocol`/`TravelPlanDetailRepositoryProtocol`에 신규 `removeSpots(planId:fromDayIndex:) async throws` 필요 (현재 removeSpot 단건, saveEditedSpots만 존재)
- `AddPlanDateRangeView`(Presentation 내부 재사용), `TabiButton` `.ghost` 스타일(기존 재사용, DesignSystem 변경 없음)
- `TabiMapMarker`/`TabiMapMarkerPinView`/`TabiMapMarkerImageFactory`에 optional `index` 필드 추가 필요
- `TravelPlanDetailSpot.coordinate`(`Coordinate.isValid`)로 지도 마커 좌표 확보
- `Strings.Plan`에 메뉴/화면/알럿 문구 신규 추가

### 제약
- `TabiMapMarker` 변경은 기존 호출부(`AddCustomPlaceView`, `MapView`, `DetailMapTabView`) 3곳에 회귀가 없어야 함 (index 기본값 `nil`로 하위 호환)
- `TabiButton` 자체는 수정하지 않고 기존 `.ghost` 스타일만 재사용
- 새 Presentation 폴더(`PlanDetailEdit`) 및 새 `.swift` 파일 추가 후 `tuist generate` 필요
- Domain은 Data를 참조하지 않는 기존 계층 구조를 유지해야 함

## Acceptance Criteria
- [x] `"..."` 메뉴에서 플랜 이름/날짜를 수정할 수 있고, 날짜 개수가 같거나 늘어나면 확인 없이 저장된다
- [x] 날짜 개수가 줄어들면 확인 알럿이 뜨고, 확인 시 초과 dayIndex의 스팟이 삭제된 뒤 저장되며, 취소 시 아무 변경도 발생하지 않는다
- [x] 편집모드 취소 버튼이 보더 없이 non-bold로 표시되고, 다른 화면의 `.secondary` 버튼은 기존과 동일하다
- [x] 스팟 타임라인의 원 안에 1부터 시작하는 순번이 표시된다
- [x] 선택된 일자에 좌표가 유효한 스팟이 있으면 지도가 표시되고, 마커에 순번이 보이며 day 전환 시 카메라가 재조정된다
- [x] 좌표가 유효한 스팟이 하나도 없는 날에는 지도 영역이 보이지 않는다
- [x] `AddCustomPlaceView`/`MapView`/`DetailMapTabView`의 기존 지도/마커 동작에 회귀가 없다

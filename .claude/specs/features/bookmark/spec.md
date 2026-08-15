# bookmark

## 무엇을 하는가
DetailView 상단 하트 버튼 또는 다른 화면의 하트 버튼을 눌러 저장한 관광지를 모아보는 화면. 사용자가 관심있는 장소를 나중에 다시 찾아볼 수 있도록 한다.

## 동작 명세
- 트리거: 탭바 "保存"(Bookmark) 탭 진입 / DetailView 등에서 하트 버튼 탭 시 저장·해제
- 결과:
  - BookmarkView 진입 시 상단부터 타이틀("保存済み") → 카테고리 필터 → 저장 개수 타이틀("N件のスポットを保存中") → Cell 리스트 순으로 표시
  - 카테고리 필터 칩 선택 시 해당 카테고리로 목록 필터링 + 선택된 칩 강조 표시(DesignSystem `TabiChip`의 `isSelected` 스타일 재사용)
  - Cell은 MapView의 검색 결과 Cell(`MapView.swift` `searchResultRow(_ spot: TouristSpot)` — 썸네일, 제목, `TabiTag`, 거리 라벨 구성)을 그대로 재사용
  - Cell을 오른쪽으로 스와이프하면 삭제 버튼이 노출되고, 삭제 시 목록에서 즉시 제거 + SwiftData에서도 삭제
  - DetailView 하트 버튼 탭 시 SwiftData에 저장/삭제되고 `isSaved` 상태가 영속화됨 (현재는 메모리 토글만 존재하여 재실행 시 리셋됨 → 이번 스코프에서 영속화로 교체)
- 사이드이펙트: SwiftData read/write (북마크 추가/삭제)
- 불변 조건: 특정 관광지는 최대 1개의 북마크 레코드만 존재(중복 저장 불가), 필터 선택 여부와 무관하게 저장 개수 표시는 전체 북마크 개수를 반영

## 무엇이 잘못될 수 있는가
- SwiftData 저장/조회 실패 → 에러 타입 정의 필요(TabiError 확장 여부는 plan 단계에서 결정), `AppLogger.core`로 로그
- 스와이프 삭제 중 대상 레코드가 이미 삭제된 상태 → 에러 없이 목록만 갱신(no-op)
- 북마크 목록이 비어있는 경우 → Empty 상태 UI 필요 (기존 Empty 컴포넌트 존재 여부 plan 단계에서 확인)

## 무엇에 의존하는가
### 의존성
- DesignSystem: `TabiNavigationBar`(타이틀), `TabiChip`(필터 칩, `isSelected` 지원 — 기존 no-op 커스텀 캡슐이 아닌 이 컴포넌트로 강조 표시 구현)
- Presentation(Map): `MapView.searchResultRow(_ spot: TouristSpot)` 셀 뷰 재사용 — 현재 `MapView.swift` 내부 private 뷰이므로 재사용 가능한 형태(예: DesignSystem 승격 또는 공용 함수 추출)로 분리 필요 여부는 plan 단계에서 결정
- Domain: `CategoryType`(필터 데이터소스), `TouristSpot`(Cell에 표시할 엔티티)
- 신규 Domain: `BookmarkUseCase`(추가/삭제/조회), Bookmark Entity
- 신규 Data: SwiftData 스택(`ModelContainer`), Bookmark `@Model` 클래스, `BookmarkRepository`
- 신규 Resource: "保存済み" 타이틀 문자열, "N件のスポットを保存中" 포맷 문자열 (`Strings.swift`에 미존재, 신규 추가 필요 — 기존 `Strings.Tabbar.bookmark`="保存"과는 별개)
- 기존 `DetailFeature.saveButtonTapped` 액션 — 현재 메모리 토글만 존재, `BookmarkUseCase` 연동 필요

### 제약
- 프로젝트 내 SwiftData 최초 도입 (CoreData 포함 영속화 스택 전무) → 이번 스코프는 최초 스키마만 다루며 마이그레이션 전략은 불필요. 배포 타겟 iOS 26.0 + Swift 6 strict concurrency 환경이라 CoreData 대신 SwiftData 채택
- 테스트 타겟 미구성 상태이므로 `BookmarkUseCase`의 `testValue`만 우선 정의 (`test-style.md` 패턴)
- MapView의 기존 카테고리 필터 칩은 현재 선택 로직이 없는 no-op 버튼(커스텀 캡슐 스타일) — 북마크 화면에서는 그대로 복제하지 않고 `TabiChip`으로 대체. 필터 칩 관련 MapView 자체는 이번 스코프에서 수정하지 않음 (단, 검색 결과 Cell은 중복 제거를 위해 `TabiSpotRow` 위임으로 소폭 리팩터링)
- 스와이프 삭제는 프로젝트 전체에 선례가 없는 패턴(최근 검색어는 별도 xmark 버튼 방식) → `List`+`.swipeActions` 또는 커스텀 제스처 여부는 plan.md 단계에서 결정

## Acceptance Criteria
- [x] BookmarkView 진입 시 타이틀/필터/총 개수/Cell 리스트가 순서대로 표시된다
- [x] 카테고리 필터 칩을 탭하면 해당 카테고리로 목록이 필터링되고 칩이 강조 표시된다
- [x] Cell을 오른쪽으로 스와이프하면 삭제할 수 있고, 삭제 시 SwiftData와 목록에서 함께 제거된다
- [x] DetailView 등에서 하트 버튼을 탭하면 SwiftData에 저장/삭제되며 앱 재실행 후에도 상태가 유지된다
- [x] 저장 개수 타이틀이 실제 북마크 총 개수와 항상 일치한다

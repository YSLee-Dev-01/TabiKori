# Photo Viewer (사진 확대 뷰)

## 무엇을 하는가
앱 어디서든 사진 목록을 보여주는 화면(Detail Photo 탭 등)에서 사진을 탭하면, 풀스크린으로 전환되어 여러 장을 스와이프로 넘겨보고 핀치 제스처로 확대/축소하며 자세히 볼 수 있는 공용 화면을 제공한다. 특정 화면에 종속되지 않고, 사진 목록 + 시작 인덱스 + 타이틀을 전달받으면 어느 화면에서든 재사용할 수 있어야 한다.

## 동작 명세
- 트리거: 사진 목록을 그리드/캐러셀 등으로 보여주는 임의의 화면에서 사진 셀 탭 (현재 첫 적용 대상은 Detail의 Photo 탭)
- 결과:
  - 새 화면(`PhotoViewerFeature`)이 `StackPath`에 push되어 전체 화면으로 전환된다
  - 호출한 화면이 전달한 이미지 목록(`[TouristSpotImage]`)과 시작 인덱스, 타이틀 문자열을 초기 State로 받는다
  - 탭한 인덱스의 사진부터 시작하며, 좌우 스와이프로 다른 사진으로 이동할 수 있다 (기존 `DetailHeroView`의 `TabView(.page)` 페이징 패턴을 구현 참고용으로 활용)
  - 상단에는 Back 버튼과, 호출 화면이 전달한 타이틀 문자열이 기존 기본 컴포넌트(Back 버튼, `TabiLabel` 등)로 표시된다 — 타이틀을 어떤 값으로 만들지는 호출하는 화면이 결정하고, `PhotoViewerFeature`는 전달받은 문자열을 그대로 표시만 한다
  - 각 사진은 `MagnificationGesture` 기반 핀치 줌으로 확대/축소 가능하다
  - Back 버튼을 탭하면 스택에서 pop되어 호출한 화면으로 복귀한다
- 사이드이펙트: 없음 — 네트워크 요청 없이 호출 화면이 push 시점에 전달한 데이터만 사용한다
- 불변 조건:
  - 사진을 넘기면(페이지 전환) 확대 배율은 1.0(기본값)으로 초기화된다
  - 이 화면의 진입/이탈이 호출한 화면(예: `DetailFeature`)의 기존 상태를 변경하지 않는다

## 무엇이 잘못될 수 있는가
- push 시 전달된 초기 인덱스가 이미지 목록 범위를 벗어남 → 인덱스 clamp 처리 필요 (범위를 벗어나면 크래시 위험)
- 이미지 원본(`imageURL`)이 nil이거나 로드 실패 → Kingfisher 로 로드, 기존 Photo 탭(`DetailPhotosTabView`)과 동일한 방식으로 처리
- 핀치 줌 배율에 상/하한이 없음 → 과도한 확대/축소로 레이아웃이 깨질 수 있음 → 배율 clamp 필요

## 무엇에 의존하는가
### 의존성
- Domain: `TouristSpotImage` Entity (`imageURL`, `thumbnailURL`, `name`)
- Presentation: `PhotoViewerFeature`(독립된 신규 화면, 특정 Feature에 종속되지 않음), `StackPath`(신규 케이스 추가), 호출하는 쪽(첫 적용 대상: `DetailPhotosTabView`의 탭 제스처 추가 지점, `DetailFeature`가 이미지/타이틀을 push 시 전달)
- DesignSystem: 기존 Back/아이콘 버튼, `TabiLabel`, `TabiAnimation` 등 재사용 (신규 컴포넌트 최소화)

### 제약
- 핀치 줌 제스처는 프로젝트 내 선례가 없어 신규 작성 필요 (DesignSystem에 줌/라이트박스 컴포넌트 없음)
- 프로젝트는 `sheet`/`fullScreenCover` 사용 사례가 없음 — 컨벤션에 맞춰 `StackPath` push 방식만 사용
- 비동기 UseCase 의존성 불필요 — 호출 화면으로부터 전달받은 데이터만 사용하므로 별도 `testValue`/`liveValue` DI 등록 없음
- 특정 화면(Detail 등)의 State/Entity를 직접 참조하지 않는다 — 이미지 목록·시작 인덱스·타이틀 문자열만 파라미터로 받아 재사용성을 보장

## Acceptance Criteria
- [x] 사진 목록을 보여주는 화면에서 사진 셀을 탭하면 탭한 사진부터 시작하는 풀스크린 화면으로 전환된다
- [x] 상단에 Back 버튼과 호출 화면이 전달한 타이틀이 표시된다
- [x] Back 버튼을 탭하면 호출한 화면으로 되돌아간다
- [x] 좌우 스와이프로 다른 사진으로 이동할 수 있다
- [x] 핀치 제스처로 확대/축소할 수 있고, 다른 사진으로 넘어가면 배율이 초기화된다
- [x] 확대/축소 배율에 상/하한이 적용되어 과도하게 늘어나거나 줄어들지 않는다
- [x] Detail 외 다른 화면에서도 동일한 방식(이미지 목록 + 인덱스 + 타이틀 전달)으로 호출할 수 있다

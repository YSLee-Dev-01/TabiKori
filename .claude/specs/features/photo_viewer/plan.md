# Plan: Photo Viewer (사진 확대 뷰)

## 참조 Spec
- @specs/features/photo-viewer/spec.md

## 참조 Skill
신규 화면 생성 시
- @skills/feature/SKILL.md (프로젝트에 `create-feature` 스킬은 없고 `feature` 스킬이 spec→plan→tasks→구현 흐름을 담당)

## 현재 상태 파악
- 신규:
  - `Projects/Presentation/Sources/PhotoViewer/PhotoViewerFeature.swift` — 독립 TCA Reducer (특정 Feature 비종속)
  - `Projects/Presentation/Sources/PhotoViewer/PhotoViewerView.swift` — 루트 뷰 (페이징 + 상단 바)
  - `Projects/Presentation/Sources/PhotoViewer/Sub/ZoomableImageView.swift` — 핀치 줌 개별 이미지 뷰 (선례 없어 신규)
  - (선택) `Projects/Presentation/Sources/PhotoViewer/PhotoViewerMock.swift` — Preview용 목 데이터
- 재사용:
  - Domain `TouristSpotImage` Entity (`imageURL`, `thumbnailURL`, `name`) — 그대로 사용, 수정 없음
  - `KFImage`(Kingfisher) + placeholder 패턴 — `DetailHeroView`/`DetailPhotosTabView`와 동일 방식
  - 페이징: `TabView(selection:)` + `.tabViewStyle(.page(indexDisplayMode: .never))` — `DetailHeroView.imagePager` 참고
  - DesignSystem: `TabiLabel`(타이틀 표시), `TabiGlassIconButton`(Back 버튼, `systemName: "chevron.left"`), `Animation.tabiStandard/tabiFast`(줌 리셋 애니메이션), `TabiColor`
  - 뒤로가기: `@Environment(\.dismiss)` — `DetailView`의 back 버튼과 동일 패턴
- 수정:
  - `Projects/Presentation/Sources/Navigation/StackPath.swift` — `case photoViewer(PhotoViewerFeature)` 추가
  - `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift` — 자식 delegate 액션 가로채 `path.append(.photoViewer(...))`
  - `Projects/Presentation/Sources/Tabbar/TabBarView.swift` — `destination` switch에 `.photoViewer` 케이스 추가
  - `Projects/Presentation/Sources/Detail/DetailFeature.swift` — Action에 `photoCellTapped(index: Int)` 추가 (State 변경 없이 부모로 전파)
  - `Projects/Presentation/Sources/Detail/DetailView.swift` — `DetailPhotosTabView`에 탭 콜백 전달
  - `Projects/Presentation/Sources/Detail/Sub/DetailPhotosTabView.swift` — 셀에 `onImageTapped: (Int) -> Void` 추가, `ForEach`에 인덱스 부여
- 삭제:
  - 없음

## 기술적 결정사항
- 스택 push 위치는 부모(`TabBarFeature`): `StackState`를 `TabBarFeature`가 소유하고 `DetailFeature`는 스택 요소일 뿐이므로, `DetailFeature`가 직접 push 불가. `DetailFeature`는 `photoCellTapped(index:)` 액션만 방출하고 `TabBarFeature`가 `.path(.element(id:, action: .detail(.photoCellTapped(index))))`를 가로채 `state.path[id: id]`에서 이미지/타이틀을 읽어 `PhotoViewerFeature.State`를 만들어 append. 대안(자식이 `@Dependency(\.dismiss)`/직접 stack 조작)은 TCA StackState 소유 구조상 불가하며, 기존 `.home(.nearbySpotTapped)` 인터셉트 패턴과 일관됨.
- 타이틀은 호출 화면이 결정: `TabBarFeature`가 인터셉트 시 `detailState.detail.japaneseTitle`을 문자열로 넘김. `PhotoViewerFeature`는 전달받은 `title: String`을 `TabiLabel`로 표시만 함 (Detail State/Entity 미참조 → 재사용성 보장).
- 뒤로가기: `PhotoViewerView`에서 `@Environment(\.dismiss)` 사용 (`DetailView`와 동일). 별도 pop 액션/Reducer 로직 불필요.
- 네비게이션 방식: 기존 `NavigationStack` + `StackPath` push만 사용. `sheet`/`fullScreenCover` 미사용 (spec 제약).
- 시작 인덱스 clamp: `PhotoViewerFeature.State.init`에서 `startIndex`를 `images.indices`(빈 배열이면 0) 범위로 clamp하여 out-of-range 크래시 방지.
- 핀치 줌: `MagnificationGesture` 기반, `scale`을 하한/상한(예: 1.0 ~ 4.0)으로 clamp. 선례 없어 `Sub/ZoomableImageView`로 신규 작성, `Sub/` 폴더 규칙 준수.
- 배율 초기화: 페이지 전환(`currentIndex` 변경) 시 배율 1.0으로 리셋. `PhotoViewerView`에서 `.onChange(of: currentIndex)`로 리셋 트리거하거나 각 페이지 `ZoomableImageView`를 `.id(index)`로 재생성. 리셋 시 `Animation.tabiFast` 적용.
- 이미지 로드: `KFImage(image.imageURL)` + `photo` placeholder (`DetailHeroView`와 동일). `imageURL`이 nil이면 placeholder 표시로 안전 처리.
- DI/UseCase 없음: 비동기 의존성 불필요 (spec 제약) → `testValue`/`liveValue`/`DependencyValues` 확장 등록 없음.
- 신규 문자열 없음: 타이틀은 호출자 전달, Back 버튼은 아이콘 → `Strings` 추가 불필요. (줌 힌트 등 문자열이 필요해지면 `Resource/Sources/Strings/Strings.swift`에만 정의)

## 구현 순서

### Phase 1. Presentation - PhotoViewerFeature (Reducer)
- `PhotoViewerFeature` 신규 작성 (`@Reducer`, `public`):
  - `@ObservableState State`: `images: [TouristSpotImage]`, `title: String`, `currentIndex: Int` (spec의 State 순서/스타일 준수), `init(images:startIndex:title:)`에서 `startIndex` clamp
  - `Action`: `BindableAction` 채택 — `binding`, (필요 시) 생명주기 `onAppear`. Back은 뷰의 `dismiss`로 처리하므로 별도 액션 최소화
  - `body`: `BindingReducer()` 우선, 부가 로직 없으면 `Reduce`는 `.none` 반환 골격
- 사이드이펙트/네트워크 없음, 의존성 주입 없음

### Phase 2. Presentation - Navigation 연결
- `StackPath.swift`에 `case photoViewer(PhotoViewerFeature)` 추가 (`State: Equatable`, `Action: Equatable` extension은 기존대로 유지)
- `TabBarFeature`:
  - `DetailFeature`에 `photoCellTapped(index: Int)` Action 추가 (State 불변)
  - `TabBarFeature.body`의 `Reduce`에서 `.path(.element(id: id, action: .detail(.photoCellTapped(let index))))` 케이스 추가 → `state.path[id: id]`에서 `.detail(detailState)` 언랩(`guard case`) → `PhotoViewerFeature.State(images: detailState.images, startIndex: index, title: detailState.detail.japaneseTitle)`를 `state.path.append(.photoViewer(...))`
- `TabBarView`의 `destination` switch에 `case .photoViewer(let store): PhotoViewerView(store: store)` 추가

### Phase 3. Presentation - PhotoViewerView & ZoomableImageView (UI)
- `ZoomableImageView` (Sub/):
  - `KFImage` + placeholder, `MagnificationGesture`로 `scale` 갱신 및 clamp(하한 1.0, 상한 상수)
  - 외부에서 배율 리셋 가능하도록 설계 (바인딩 or `.id` 재생성 중 택1, 기술 결정 참조)
- `PhotoViewerView`:
  - `@Bindable store`, `@Environment(\.dismiss)`
  - `TabView(selection: $store.currentIndex.sending 또는 binding)` + `.tabViewStyle(.page(indexDisplayMode: .never))`로 페이징, 각 페이지에 `ZoomableImageView`
  - 상단 오버레이: Back `TabiGlassIconButton(systemName: "chevron.left") { dismiss() }` + `TabiLabel`(`store.title`) — 기존 컴포넌트 재사용
  - 배경 풀스크린, `.ignoresSafeArea`, `.navigationBarBackButtonHidden(true)`
  - `currentIndex` 변경 시 배율 리셋 처리
- (선택) `#Preview` + `PhotoViewerMock`

### Phase 4. Detail 호출부 연결
- `DetailPhotosTabView`: `onImageTapped: (Int) -> Void` 프로퍼티 추가, `ForEach(Array(images.enumerated()), id: \.element.imageURLString)`로 인덱스 확보 후 `photoCell`에 `.onTapGesture { onImageTapped(index) }` (이미 `.contentShape(Rectangle())` 존재)
- `DetailView.tabContentSection`: `DetailPhotosTabView(images: store.images, onImageTapped: { store.send(.photoCellTapped($0)) })`

### Phase 5. 프로젝트 재생성 & 검증
- 신규 `.swift` 파일 추가로 인해 `tuist install && tuist generate` 필수 (stale 프로젝트 방지)
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`로 빌드 확인
- 시뮬레이터에서 Detail Photo 탭 셀 탭 → 풀스크린 전환/스와이프/핀치 줌/배율 리셋/clamp/Back pop 수동 확인

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
- [ ] 사진 셀 탭 시 탭한 인덱스부터 시작하는 풀스크린 `PhotoViewerFeature`가 스택에 push
- [ ] 상단에 Back 버튼(`TabiGlassIconButton`) + 호출 화면 전달 타이틀(`TabiLabel`) 표시
- [ ] Back 탭 시 호출 화면으로 pop, `DetailFeature` 상태 불변
- [ ] 좌우 스와이프 페이징 동작
- [ ] 핀치 줌 확대/축소 + 배율 상/하한 clamp + 페이지 전환 시 배율 1.0 초기화
- [ ] 시작 인덱스 범위 초과 시 clamp 처리 (크래시 없음)
- [ ] Detail 외 화면에서도 이미지 목록 + 인덱스 + 타이틀 전달만으로 재사용 가능 (Detail State/Entity 미참조)
- [ ] `tuist generate` 후 빌드 성공

---

### Critical Files for Implementation
- /Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Navigation/StackPath.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Tabbar/TabBarFeature.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Tabbar/TabBarView.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Detail/Sub/DetailPhotosTabView.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Detail/Sub/DetailHeroView.swift (페이징/`KFImage` 구현 참고용)

## 프로젝트 개요

한국관광공사 다국어 관광정보 API(EngService2) 기반으로 관광지·환율·위치 정보를 제공하는 iOS 여행 정보 앱

---

## 빌드 명령어

```bash
# 앱 빌드
xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Tuist 프로젝트 생성 (새 파일/타겟 추가 후 필수)
tuist install
tuist generate
```

> 테스트 타겟은 아직 구성되어 있지 않음. 추가 시 `.claude/rules/test-style.md` 규칙(TCA TestStore)을 따를 것

---

## 규칙 문서 참조

세부 컨벤션은 아래 규칙 문서를 참조

| 문서 | 경로 | 내용 |
|------|------|------|
| Swift 스타일 | `.claude/rules/swift-style.md` | 네이밍, 코드 구조, TCA 패턴, 접근 제어 등 |
| 폴더 구조 | `.claude/rules/folder-structure.md` | 모듈별 디렉토리 구조, 파일 배치 규칙 |
| 테스트 스타일 | `.claude/rules/test-style.md` | TCA TestStore 작성 규칙 |
| Git 컨벤션 | `.claude/rules/git-style.md` | 커밋 키워드, 메시지 규칙 |

---

## 아키텍처 개요

**Tuist 멀티모듈 + TCA + SwiftUI**

### 모듈 구성

`Projects/{App, Domain, Data, Core, DesignSystem, Presentation, Resource}` — 의존성 방향은 `Tuist/ProjectDescriptionHelpers/Dependency/DependencyInformation.swift`가 source of truth

- **App** — 앱 진입점, DI 조립(각 UseCase의 `liveValue` 등록)
- **Presentation** — 화면(Feature) 계층, TCA + SwiftUI
- **Domain** — UseCase, Entity, RepositoryProtocol, DependencyKey의 `testValue`
- **Data** — Repository 구현체, 네트워킹, DTO
- **Core** — 로거 등 앱 전역 유틸리티, 다른 모든 모듈이 의존 가능한 최하위 레이어
- **DesignSystem** — 공용 UI 컴포넌트
- **Resource** — 문자열/컬러/폰트/이미지 에셋

세부 하위 폴더 규칙은 `.claude/rules/folder-structure.md` 참조

### TCA 의존성 등록 패턴

`testValue`(Domain)와 `liveValue`(App)를 계층 분리하여 등록:

- `Domain/Sources/Dependency/Keys/{Name}UseCaseDependencyKey.swift` — `TestDependencyKey` 채택, `testValue`만 정의 (Test 더블 반환)
- `App/Sources/Dependency/{Name}UseCaseDependencyKey.swift` — 같은 타입에 `@retroactive DependencyKey` extension으로 `liveValue` 정의 (Data Repository 주입)
- `DependencyValues` 프로퍼티 확장은 `Domain/Sources/Dependency/DependencyValues.swift`에 모아서 선언

Domain이 Data를 직접 참조하지 않도록, 실제 구현체 조립은 항상 App 레이어에서만 수행

### 시크릿 관리

- API 키는 `Projects/Data/Sources/Secret.xcconfig`(gitignored)를 통해 Info.plist에 주입, `Data/Sources/Network/Secret/Secret.swift`에서 `Bundle.main`으로 읽음
- 시크릿 값 하드코딩 금지, `Secret.xcconfig`는 절대 커밋하지 않음

---

## 주의사항

- IMPORTANT 문자열·DesignSystem 컴포넌트·Font/Animation은 새로 만들기 전에 `Resource`/`DesignSystem`에 기존 항목이 있는지 먼저 확인 후 재사용 (`swift-style.md` 9번 규칙)
- IMPORTANT 새 `.swift` 파일 추가 후에는 `tuist generate` 없이 빌드하면 stale 프로젝트로 오탐 에러 발생
- IMPORTANT `Secret.xcconfig`는 커밋 대상 아님, 관련 git 작업 금지

- 불확실한 정보는 추측하지 말고 반드시 질문하라
- 요청이 모호하면 작업 전에 질문으로 명확히 해라

- API, 라이브러리 버전, 메서드 시그니처는 절대 추측하지 마라
- 현재 태스크와 무관한 코드는 절대 수정하지 마라
- 우회책보다 근본 원인을 수정하라. 임시 방편은 쓰지 마라
- 기존 코드를 삭제하기 전에 왜 존재하는지 먼저 설명하라

- 에러 로그가 있으면 추론하지 말고 해당 데이터에서 직접 추적하라
- 작업을 멈출 때는 완료된 것, 막힌 것, 수정한 파일을 명시하라

---

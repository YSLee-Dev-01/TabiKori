---
name: folder-structure
description: 프로젝트 폴더 구조 규칙을 정의한 문서
---

## 모듈 구성

```
Projects/
├── App/            # 앱 진입점, DI 조립 (liveValue 등록)
├── Presentation/    # 화면(Feature) 계층 — TCA + SwiftUI
├── Domain/          # UseCase, Entity, RepositoryProtocol, testValue
├── Data/            # Repository 구현체, 네트워킹, DTO
├── DesignSystem/    # 공용 UI 컴포넌트
├── Resource/        # 문자열/컬러/폰트/이미지 에셋
└── Core/            # 로거 등 전역 유틸리티 (최하위 레이어)
```

## 모듈 의존성

`Tuist/ProjectDescriptionHelpers/Dependency/DependencyInformation.swift`가 source of truth이며, 아래 방향을 벗어나는 의존성 추가 금지:

| 모듈 | 의존 대상 |
|------|----------|
| `App` | `Domain`, `Data`, `Presentation` |
| `Presentation` | `DesignSystem`, `Core`, `Domain`, `Resource` |
| `Data` | `Domain`, `Core` |
| `Domain` | `Core` |
| `DesignSystem` | `Core`, `Resource` |
| `Core` / `Resource` | 없음 (최하위) |

- `Domain`은 `Data`를 참조하지 않음 — 실제 구현체 조립은 항상 `App`에서만 수행
- 새 모듈 간 의존이 필요하면 코드에서 바로 import하지 말고 `DependencyInformation.swift`부터 수정

---

## Domain/

```
Domain/Sources/
├── Entity/                        # 도메인 모델, 기능 구분 없이 평평하게 배치
├── Error/
│   └── TabiError.swift            # 공통 에러 타입
├── RepositoryProtocol/
│   └── {Name}RepositoryProtocol.swift
├── UseCase/{FeatureName}/
│   ├── {Name}UseCase.swift
│   ├── {Name}UseCaseProtocol.swift
│   ├── Test{Name}UseCase.swift    # TestDependencyKey.testValue용 더블
│   └── (기타 헬퍼, 예: RegionClassifier.swift)
└── Dependency/
    ├── DependencyValues.swift     # DependencyValues 프로퍼티 확장 전부 모아서 선언
    └── Keys/
        └── {Name}UseCaseDependencyKey.swift   # TestDependencyKey 채택 + testValue만 정의
```

## Data/

```
Data/Sources/
├── DTO/{FeatureName}/
│   └── {Name}DTO.swift
├── Network/
│   ├── EndPoint/
│   │   ├── Protocol/EndPoint.swift
│   │   └── {Name}Endpoint.swift
│   ├── Service/
│   │   ├── NetworkService.swift
│   │   └── NetworkServiceProtcol.swift
│   ├── Session/
│   │   ├── URLSession+.swift
│   │   └── URLSessionProtocol.swift
│   ├── Secret/Secret.swift        # Info.plist 키를 통해 시크릿 값 읽기
│   ├── HTTPMethod.swift
│   └── NetworkError.swift
├── Repository/{FeatureName}/
│   └── {Name}Repository.swift     # RepositoryProtocol 구현체
├── UserDefault/
│   ├── TabiUserDefault.swift
│   ├── TabiUserDefaultKey.swift
│   └── TabiUserDefaultProtocol.swift
├── Extension/
│   └── {Type}+.swift
├── Secret.xcconfig                # gitignored, 실제 API 키
└── Secret.xcconfig.sample         # 커밋 대상, 키 목록 템플릿
```

## Presentation/

```
Presentation/Sources/
├── {FeatureName}/
│   ├── {Name}Feature.swift        # TCA Reducer (State/Action/body)
│   ├── {Name}View.swift           # SwiftUI 루트 뷰
│   ├── {Name}Mock.swift           # SwiftUI Preview용 목 데이터 (선택)
│   ├── Sub/                       # 서브 뷰 (body 50줄 초과 시 분리)
│   ├── Model/                     # 화면 전용 변환/헬퍼 타입
│   └── Entity/                    # 화면 전용 모델 (예: Tabbar/Entity/AppTab.swift)
│
├── Root/                          # 앱 루트 Feature (최초 진입 분기)
├── Tabbar/                        # 탭바 Feature
├── Navigation/
│   └── StackPath.swift            # TCA 네비게이션 스택 경로 정의
└── Extension/
    └── {Type}+.swift
```

- 화면 하나 = `Presentation/{FeatureName}/` 폴더 하나
- 서브 뷰는 재사용 여부와 무관하게 `Sub/`에 위치 (해당 화면에서만 쓰는 것이 기본 전제)
- 다른 화면에서도 재사용해야 하는 컴포넌트로 판단되면 `DesignSystem/`으로 승격

## DesignSystem/

```
DesignSystem/Sources/
├── Button/
├── Card/
├── Chip/
├── Label/
├── NavigationBar/
├── Tag/
├── Font/
│   └── FontStyle.swift
└── Style/                         # Alignment, Animation, Radius 등 공용 상수
```

- 컴포넌트 종류별 폴더, 실제 컴포넌트 파일명은 `Tabi{ComponentName}.swift`
- 토큰/스타일 정의 파일(`FontStyle.swift`, `TypographyStyle.swift` 등)은 `Tabi` 접두사 없이 `{Name}Style.swift`로 명명

## Resource/

```
Resource/
├── Sources/
│   ├── Color/TabiColor.swift
│   ├── Image/TabiImage.swift
│   └── Strings/Strings.swift
└── Resources/
    ├── Assets.xcassets/
    └── Fonts/
```

| 파일 종류 | 위치 |
|----------|------|
| 문자열 | `Resource/Sources/Strings/Strings.swift` |
| 컬러 (코드 접근용) | `Resource/Sources/Color/TabiColor.swift` (+ `Assets.xcassets/Colors`) |
| 이미지 (코드 접근용) | `Resource/Sources/Image/TabiImage.swift` (+ `Assets.xcassets/Images`) |
| 폰트 파일 | `Resource/Resources/Fonts/` |

## Core/

```
Core/Sources/
├── Config/
│   └── AppConfig.swift
├── Extension/
│   └── String+.swift
└── Logger/
    └── AppLogger.swift            # AppLogger.{network,core,view}
```

---

## 파일 배치 규칙

1. **여러 화면에서 재사용되는 UI**인가? → `DesignSystem/Sources/{ComponentType}/`
2. **특정 화면 전용 UI/모델**인가? → `Presentation/{FeatureName}/{Sub,Model,Entity}/`
3. **네트워크 응답 DTO**인가? → `Data/Sources/DTO/{FeatureName}/`
4. **Repository 구현체**인가? → `Data/Sources/Repository/{FeatureName}/`
5. **UseCase / 도메인 모델**인가? → `Domain/Sources/UseCase/{FeatureName}/` 또는 `Domain/Sources/Entity/`
6. **TCA 의존성 등록**인가?
   - `testValue` → `Domain/Sources/Dependency/Keys/`
   - `liveValue` → `App/Sources/Dependency/`
   - `DependencyValues` 프로퍼티 확장 → `Domain/Sources/Dependency/DependencyValues.swift`
7. **문자열 / 컬러 / 이미지 / 폰트**인가? → `Resource/`
8. **전역 유틸리티 / 로깅**인가? → `Core/Sources/`

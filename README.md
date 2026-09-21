<img src="https://github.com/user-attachments/assets/632cc5ca-b7a2-4b45-9112-24e6775c8690" height="150"/>

# タビコリ (타비코리)

### 한국 여행을, 더욱 나답게
한국관광공사의 공식 데이터와 일본인 여행객을 위한 기능 설계로 한국 여행을 책임지는 앱입니다.

[![App Store](https://img.shields.io/badge/App%20Store-Download-0066cc?style=for-the-badge&logo=apple&logoColor=white)](https://apps.apple.com/kr/app/%ED%83%80%EB%B9%84%EC%BD%94%EB%A6%AC/id6805470024)

### 📆 개발 기간

`v1.0.0` 2026.06.07 ~ 2026.09.07 </br>
`v1.0.1` 2026.06.07 ~ 2026.09.14 </br>
`v1.0.2` 2026.09.14 ~ 2026.09.15 </br>

<br/>

## 📋 주요 기능
<div align=left>
<img src="https://github.com/user-attachments/assets/c6aaedc2-f5fc-4168-88e2-4c223c4d9a33" height="350" />
<img src="https://github.com/user-attachments/assets/76edf303-0722-42cb-8a43-fcfd72575051" height="350" />
<img src="https://github.com/user-attachments/assets/b22fecb9-6f31-4450-a247-4978715c0fea" height="350" />
<br>
<img src="https://github.com/user-attachments/assets/5dc3fea9-8ff7-46a6-9b0f-8ee9dde7daad" height="350" />
<img src="https://github.com/user-attachments/assets/5b366a5f-69f5-4c25-868b-bc090720f55d" height="350" />
<img src="https://github.com/user-attachments/assets/550de104-a66f-41f8-9135-3118f04526a1" height="350" />
<br/>
<br/>

<b>현 위치에서 검색하는 주변 관광지·맛집</b>
- 현 위치를 중심으로 주변 관광 장소 및 음식점을 카테고리별로 검색할 수 있습니다.

<b>관광지 검색부터 일정 등록까지 한 번에 이어지는 여행 계획 기능</b>
- 검색부터 상세 정보 확인, 일정 등록까지 앱을 벗어나지 않고 한번에 등록할 수 있습니다.

<b>진행 중인 이벤트·축제 정보</b>
- 지역 축제나 지자체 행사 정보를 한눈에 확인할 수 있습니다.

<b>한국어 회화, 환율 계산, 준비물 등 여행에서 필요한 기능을 모아놓은 툴박스 기능</b>
- 여행에 필요한 도구를 한 화면에 모아, 여러 앱을 사용하지 않고 바로 이용할 수 있습니다.

<b> 홈 화면에서 바로 확인하는 한국어 회화와 일정 정보</b>
- 위젯을 통해 한국어 회화 및 진행 중인 일정 정보를 확인하고 바로 접근할 수 있습니다.

<br/>

## 🛠 사용된 라이브러리 / 프레임워크
- UIKit, SwiftUI, WidgetKit
- TCA(ComposableArchitecture), Lottie, Kingfisher, NMapsMap
- Firebase/Crashlytics, Firebase/Analytics, Firebase/Database
<br/>

## 🤖 AI 활용
### ✅ Claude Code
- 이번 프로젝트는 클로드 코드와 함께 개발을 진행했습니다.
- 전체 637개의 커밋 중 499개(78%)를 AI와 함께 작업했습니다.
```
- 네이밍, 의존성, 컨벤션 등을 rules로 정의하여 일관성을 유지했습니다.
- 커밋 메시지, 요구사항 정리 등을 skill로 표준화 했습니다.
- swift-code-reviewer, feature 등 다양한 스킬/에이전트를 통해 코드 품질 및 개발 생산성을 높였습니다.
```

### 🌄 Figma
- 타비코리의 디자인 시스템은 피그마의 "Make" 도구를 기반으로 만들어졌습니다.
```
- 컨셉과 화면 구성을 프롬프트로 전달해 초기 시안을 만든 후 이를 기준으로 디자인 시스템을 개발했습니다.
- 반복되는 UI는 공통 컴포넌트로 분리하여 일관성을 유지했습니다.
```

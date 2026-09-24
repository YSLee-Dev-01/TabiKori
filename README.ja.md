<img src="https://github.com/user-attachments/assets/632cc5ca-b7a2-4b45-9112-24e6775c8690" height="150"/>

[한국어](README.md) | **日本語**

# タビコリ

### 韓国旅行を、もっと自分らしく
韓国観光公社の公式データと、日本人旅行者のための機能設計で韓国旅行をサポートするアプリです。

[![App Store](https://img.shields.io/badge/App%20Store-Download-0066cc?style=for-the-badge&logo=apple&logoColor=white)](https://apps.apple.com/kr/app/%ED%83%80%EB%B9%84%EC%BD%94%EB%A6%AC/id6805470024)

### 📆 開発期間

`v1.0.0` 2026.06.07 ~ 2026.09.07 </br>
`v1.0.1` 2026.06.07 ~ 2026.09.14 </br>
`v1.0.2` 2026.09.14 ~ 2026.09.15 </br>

<br/>

## 📋 主な機能
<div align=left>
<img src="https://github.com/user-attachments/assets/bd420520-b866-4636-a573-3cf87cba7990" height="350" />
<img src="https://github.com/user-attachments/assets/674abe19-d605-40f3-8c86-416e48f827ba" height="350" />
<img src="https://github.com/user-attachments/assets/ae3e5111-5616-423d-8401-95eedc895ff0" height="350" />
<br>
<img src="https://github.com/user-attachments/assets/1c8844d5-53b9-433c-8ba0-e571900f1140" height="350" />
<img src="https://github.com/user-attachments/assets/feec1a01-cbf7-44af-a3c9-a01147584df7" height="350" />
<img src="https://github.com/user-attachments/assets/032d7488-7390-4508-af1c-88d3b0174a5f" height="350" />
<br/>
<br/>

<b>現在地から探す、近くの観光地・グルメ</b>
- 現在地を中心に、周辺の観光スポットや飲食店をカテゴリー別に検索できます。

<b>日程ごとの旅行プランを作成</b>
- 行きたいスポットを追加して、日程ごとのプランを作成できます。地図で全体のルートを確認しながら、時間の調整やスポットの並び替えも自由に行えます。

<b>開催中のイベント・お祭り情報</b>
- 月ごとのおすすめイベントや、現在開催中のお祭り情報をチェックできます。

<b>為替レート計算をリアルタイムで</b>
- 両替のたびに計算する手間はありません。最新の為替レートをアプリ内でいつでも確認できます。

<b>買い物リスト・持ち物リストで準備もスムーズに</b>
- お土産の買い物リストと持ち物チェックリストで、出発前の準備を効率よく進められます。

<b>現地で役立つ韓国語フレーズ</b>
- 「これください」「トイレはどこですか」など、現地ですぐ使える実用フレーズを収録しています。

<b>ホームですぐに確認できる韓国語フレーズとスケジュール情報</b>
- ウィジェットを通じて、韓国語フレーズや進行中のスケジュール情報をすぐに確認できます。

<br/>

## 🛠 使用ライブラリ / フレームワーク
- UIKit, SwiftUI, WidgetKit
- TCA(ComposableArchitecture), Lottie, Kingfisher, NMapsMap
- Firebase/Crashlytics, Firebase/Analytics, Firebase/Database
<br/>

## 🤖 AIの活用
### ✅ Claude Code
- 本プロジェクトはClaude Codeと共に開発を進めました。
- 全637コミットのうち499コミット(78%)をAIと共同で作業しました。
```
- ネーミングや依存関係、コーディング規約などをrulesとして定義し、一貫性を維持しました。
- コミットメッセージや要件整理などをskillとして標準化しました。
- swift-code-reviewer、featureなど様々なスキル・エージェントを活用し、コード品質と開発生産性を向上させました。
```

### 🌄 Figma
- タビコリのデザインシステムは、Figmaの「Make」機能をベースに作成されました。
```
- コンセプトと画面構成をプロンプトとして伝え、初期案を作成した上でデザインシステムを開発しました。
- 繰り返し使用されるUIは共通コンポーネントとして分離し、一貫性を維持しました。
```

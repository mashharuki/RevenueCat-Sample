# Breakout Game (SpriteKit + SwiftUI)

Swift / iOS アプリ開発の練習用に作った、ブロック崩し (Breakout) の iOS アプリです。ゲームシーンは SpriteKit、メニューや HUD などのアプリシェルは SwiftUI で実装しています。

## セットアップ

Xcode プロジェクトは [XcodeGen](https://github.com/yonaskolb/XcodeGen) の `project.yml` から生成しています。`project.yml` を編集したり `Sources/` にファイルを追加・削除した場合は、以下を実行してプロジェクトを再生成してください。

```bash
brew install xcodegen   # 未インストールの場合のみ
xcodegen generate
open BreakoutGame.xcodeproj
```

## ビルド・テスト

```bash
xcodebuild -project BreakoutGame.xcodeproj -scheme BreakoutGame \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build

xcodebuild -project BreakoutGame.xcodeproj -scheme BreakoutGame \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' test
```

日常的な開発は Xcode で `BreakoutGame.xcodeproj` を開いて ⌘R が簡単です。

## 実機ビルド・署名

Team / Bundle Identifier の設定や実機での動作確認手順は、同リポジトリ内の [`docs/ios-setup.md`](../docs/ios-setup.md) を参照してください（別ゲーム用に書かれたガイドですが、Xcode 側の署名手順はそのまま流用できます）。

## 現在のスコープ (MVP)

パドル・ボール・ブロック・スコア・ライフ・勝敗判定という Breakout のコアループを実装済みです。パワーアップ・複数レベル・効果音・ハプティクスなどは今後の拡張候補です。

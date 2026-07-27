# Memo App (SwiftUI + Firebase Auth + RevenueCat)

Google Sign-In(Firebase Authentication)・自前バックエンドAPI(`../api`)・RevenueCatによる課金を組み合わせたメモ帳アプリ。認証 + 課金 + 自前APIの3つを1つのアプリで連携させる練習用フルスタックアプリ。

## 構成リソース

| リソース | 名前 | 用途 |
|---|---|---|
| Firebaseプロジェクト | `memo-app-shipaton` | 認証基盤(Google Sign-In) |
| iOSアプリ登録 | BUNDLE_ID `com.haruki.MemoApp` | `GoogleService-Info.plist`の発行元 |
| RevenueCatエンタイトルメント | `memo_premium` | 課金による無制限メモ解放 |

## セットアップ

```bash
brew install xcodegen   # 未インストールの場合のみ
xcodegen generate
open memo_app.xcodeproj
```

`project.yml`を編集したり`Sources/`にファイルを追加・削除した場合は`xcodegen generate`を再実行すること。**`GIDClientID`/`CFBundleURLTypes`/`GoogleService-Info.plist`は`project.yml`に恒久的に宣言済み**なので再生成しても消えない(詳細は`.kiro/specs/memo-app/tasks.md`のImplementation Notes 8.3参照)。

## ビルド・テスト

```bash
xcodebuild -project memo_app.xcodeproj -scheme MemoApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' build

xcodebuild -project memo_app.xcodeproj -scheme MemoApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' test
```

## Firebaseリソースのデプロイ手順

Firebase側で管理しているのは認証プロバイダ設定(`firebase.json`)のみ(Firestoreやその他のFirebaseサービスは未使用)。

```bash
# (初回のみ) Firebaseプロジェクトの作成
npx -y firebase-tools@latest login
npx -y firebase-tools@latest projects:create memo-app-shipaton

# firebase.json の auth.providers を編集後、認証設定を反映
npx -y firebase-tools@latest deploy --only auth
```

反映後は以下で確認する:

```bash
npx -y firebase-tools@latest apps:sdkconfig ios com.haruki.MemoApp
```

**注意**: `firebase.json`の`authorizedDomains`にはプロトコル・ポート番号を含めないこと(例: `localhost`であって`http://localhost:9090`ではない)。含めると`[firebase_auth/unauthorized-domain]`エラーでGoogle Sign-Inが即座に失敗する。

## Firebaseリソースのデストロイ手順

**注意**: いずれも取り消しが困難、または既存ユーザーのサインインができなくなる破壊的操作。

```bash
# Google Sign-Inプロバイダのみ無効化(プロジェクト自体は残す)
# firebase.json の googleSignIn を削除するか anonymous/emailPassword 同様に false 相当にしてから
npx -y firebase-tools@latest deploy --only auth

# Firebaseプロジェクト自体を削除する場合(認証情報・全ユーザーが完全に消失する)
npx -y firebase-tools@latest projects:delete memo-app-shipaton
```

iOSアプリ側の登録(`GoogleService-Info.plist`)は、Firebaseプロジェクトを削除する前に[Firebase Console](https://console.firebase.google.com/)でアプリ登録を削除するか、プロジェクト削除と同時に無効化される点に留意する。

## バックエンド(api/)との関係

このアプリは`../api`(Cloudflare Workers)へHTTPリクエストを送る。`api/`のデプロイ・デストロイ手順は[`../api/README.md`](../api/README.md)を参照。

## 実機ビルド・署名

Team / Bundle Identifierの設定や実機での動作確認手順は、同リポジトリ内の[`docs/ios-setup.md`](../docs/ios-setup.md)を参照(別ゲーム用に書かれたガイドだが、Xcode側の署名手順はそのまま流用できる)。

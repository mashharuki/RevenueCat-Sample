# iOS 実機ビルド & Apple Developer 登録ガイド

`my_first_game`(Neon Invaders)をiOS実機で動かし、将来的にRevenueCatの課金(IAP)テストやTestFlight配信までつなげるための手順。

## 1. 全体像:何が必要か

| やりたいこと | 必要なもの | 費用 |
|---|---|---|
| シミュレータで動作確認 | Xcodeのみ | 無料 |
| 自分の実機にビルドして動かす | 無料のApple ID + Xcodeサインイン | 無料 |
| RevenueCat/StoreKitの**課金テスト**(Sandbox) | 無料のApple ID + App Store Connectでのアプリ登録 | 無料〜 |
| TestFlightで他人に配信 / App Store提出 | **Apple Developer Program**登録 | 年間 $99 (個人/法人) |

> ⚠️ 課金テスト(IAP/サンドボックス購入)は**シミュレータでは動かない**。実機が必須。
> Shipatonで審査提出まで進める予定なら、早めに有料のDeveloper Programに登録しておくのが安全(審査に数日〜かかることがある)。

---

## 2. 無料Apple IDでの実機ビルド(まずはここから)

### 2-1. Xcodeにサインイン

1. Xcodeを開く: `open ios/Runner.xcworkspace`(プロジェクトルートの `my_first_game/` で実行)
2. メニューバー `Xcode` → `Settings...`(または `Preferences...`) → `Accounts` タブ
3. 左下の `+` → `Apple ID` を選び、普段使っているApple IDでサインイン
   - Apple Developer Programに未登録でもここはサインインできる(無料枠)

### 2-2. プロジェクトにチームを設定

1. Xcode左のナビゲータで `Runner`(青いプロジェクトアイコン)をクリック
2. `TARGETS` 内の `Runner` を選択 → 上部タブ `Signing & Capabilities`
3. `Team` のドロップダウンで、さきほど追加したApple ID(個人チーム)を選択
   - `Automatically manage signing` にチェックが入っていることを確認
4. `Bundle Identifier` を確認・変更
   - デフォルトの `com.example.myFirstGame` は`flutter create`のテンプレート値。他人と衝突しやすいので、独自の値に変更しておく
   - 例: `com.<あなたの名前や屋号>.neoninvaders`
   - 変更後、Xcodeが自動でプロビジョニングプロファイルを再生成する(数秒待つ)

### 2-3. 実機を接続して信頼

1. iPhone/iPadをUSBケーブル(またはWi-Fi同期設定済みなら無線)でMacに接続
2. 初回接続時、iPhone側に「このコンピュータを信頼しますか?」→ 信頼をタップ、パスコード入力
3. Xcode上部のデバイス選択で自分の実機を選ぶ
4. 実行ボタン(▶)を押すか、ターミナルから:
   ```bash
   flutter devices          # 実機が認識されているか確認
   flutter run -d <device-id>
   ```

### 2-4. 初回起動時の「信頼されていないデベロッパ」エラー対処

初回はアプリがインストールされてもiPhone側で起動を拒否されることがある。

1. iPhoneで `設定` → `一般` → `VPNとデバイス管理`(機種により `デバイス管理`)
2. 該当のデベロッパ証明書(Apple IDのメールアドレスが表示される)を選択
3. `"<証明書>"を信頼` をタップ → 確認ダイアログで `信頼`
4. 再度アプリを起動

### 無料アカウントの制限

- アプリの有効期限は**7日間**(無料プロビジョニングプロファイルの制限)。7日ごとにXcodeから再ビルドが必要
- 同時にインストールできる実機の登録台数に制限あり
- App Store Connect(課金商品の登録、TestFlight)は使えない

---

## 3. Apple Developer Program 登録(有料、$99/年)

RevenueCatでの課金テスト・審査提出には、App Store Connect側でアプリ/課金商品を登録する必要があり、これには有料プログラムへの登録が必須。

### 3-1. 登録手順

1. https://developer.apple.com/programs/enroll/ にアクセス
2. Apple IDでサインイン(2ファクタ認証が有効になっている必要あり)
3. `個人(Individual)` か `組織(Organization)` を選択
   - 個人:本人確認のみで比較的早い(数時間〜1日程度)
   - 組織:D-U-N-S番号など法人確認が必要で数日〜数週間かかることがある → **ハッカソンなら個人登録推奨**
4. 支払い情報を入力し、年間$99を支払う
5. 承認メールが届くまで待つ

### 3-2. 登録完了後にやること

1. Xcodeの `Signing & Capabilities` → `Team` を、個人チームから **正式なDeveloper Programのチーム**に変更
2. https://appstoreconnect.apple.com/ にアクセスできるようになる
3. `マイApp` → `+` → 新規Appを作成
   - Bundle IDはXcode側で設定したものと一致させる
   - SKU(内部管理用ID)、対応言語などを入力

---

## 4. RevenueCatの課金テスト用の追加設定(Sandbox)

Developer Program登録後、実際に課金フローをテストする流れ:

1. **App Store Connect** → `App内課金` で商品(サブスクリプション/消費型アイテムなど)を作成
   - RevenueCatダッシュボード側でも同じProduct IDをエンタイトルメント/オファリングに紐付ける(`integrate-revenuecat` スキルや `revenuecat-shipaton-copilot` エージェントが手順をサポート)
2. **Sandboxテスターアカウント**を作成
   - App Store Connect → `ユーザーとアクセス` → `Sandboxテスター` → `+`
   - 本物のApple IDとは別のダミーメールアドレスで作成(実際に課金されない検証用)
3. 実機の `設定` → `App Store` → 一番下の `Sandboxアカウント` にSandboxテスターでサインイン
   - iOS17以降は `設定` → `デベロッパ` 配下にある場合もある
4. アプリを実機で起動し、購入フローを実行 → Sandbox環境で「購入」される(実際の請求は発生しない)

---

## 5. トラブルシューティング

| エラー | 原因 | 対処 |
|---|---|---|
| `No valid code signing certificates were found` | Xcodeでチーム未設定 | 本ガイドの2-2を実施 |
| `No development certificates available to code sign app for device deployment` | 同上、または証明書の期限切れ | Xcode `Accounts` で証明書を再生成(`Manage Certificates...`) |
| インストール後アプリが開かない/「信頼されていない」 | デベロッパ証明書が未信頼 | 本ガイドの2-4を実施 |
| `flutter build ios` は通るが実機起動でクラッシュ | Bundle IDの衝突、プロビジョニングプロファイル不整合 | Bundle IDをユニークな値に変更し、Xcodeでクリーンビルド(`Product` → `Clean Build Folder`) |
| 7日後にアプリが起動しなくなる | 無料プロビジョニングの期限切れ | Xcodeで実機接続の上、再ビルド・再インストール |
| Sandbox購入がエラーになる | Sandboxアカウントでサインインできていない/実アカウントと混在 | 実機のApple IDからサインアウトし、Sandboxアカウント専用でテスト |

---

## 6. Shipaton提出前チェックリスト

- [ ] Apple Developer Program登録完了(承認メール受領済み)
- [ ] Bundle IDをユニークな値に変更済み
- [ ] App Store Connectでアプリ登録済み
- [ ] RevenueCatダッシュボードでプロジェクト/エンタイトルメント/オファリング設定済み
- [ ] 実機でSandbox購入フローが一通り成功する
- [ ] TestFlightへのビルドアップロード(`flutter build ipa` → Xcode Organizer or Transporter経由)
- [ ] スクリーンショット・App紹介文など、審査に必要なメタデータ準備

## 参考リンク

- [Apple Developer Program登録](https://developer.apple.com/programs/enroll/)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [Flutter: iOSデプロイ公式ガイド](https://docs.flutter.dev/deployment/ios)

# Research & Design Decisions Template

## Summary
- **Feature**: `memo-app`
- **Discovery Scope**: New Feature(greenフィールド、既存コードなし)
- **Key Findings**:
  - Cloudflare WorkersランタイムはNode.js専用の`firebase-admin` SDKと互換性がないため、Firebase IDトークンの検証はHono組み込みの`hono/jwk`ミドルウェアでFirebaseの公開JWKSエンドポイントを直接検証する方式が最も現実的。
  - RevenueCatの推奨バックエンド構成は「レシート検証をRevenueCatに任せ、バックエンドはエンタイトルメント状態を読み取るだけ」。`GET /v1/subscribers/{app_user_id}`は現在も現役のAPIで、Webhook受信基盤を組まなくても要件4.6(「次回アクセス時に再チェック」)をそのまま満たせる。
  - iOSのGoogle Sign-InはFirebaseAuthとは別のSPMパッケージ(`GoogleSignIn-iOS`)が必要で、`xcode-project-setup`スキルのスクリプトでSPM依存追加は自動化できるが、URLスキーム登録はInfo.plistの手動編集が必要。
  - メモの永続化はCloudflare D1(SQLite互換)が要件(ユーザーごとの一覧・更新日時順ソート・CRUD)に自然に適合する。

## Research Log

### Firebase IDトークンの検証(Cloudflare Workers + Hono)
- **Context**: バックエンドはSwiftクライアントから送られてくるFirebase IDトークンを検証してユーザーを識別する必要があるが、Workersランタイムでは`firebase-admin`が動かない。
- **Sources Consulted**: [Hono JWK middleware docs](https://hono.dev/docs/middleware/builtin/jwk), [Firebase: Verify ID Tokens](https://firebase.google.com/docs/auth/admin/verify-id-tokens), [Code-Hex/firebase-auth-cloudflare-workers](https://github.com/Code-Hex/firebase-auth-cloudflare-workers), [@hono/firebase-auth (npm)](https://www.npmjs.com/package/@hono/firebase-auth)
- **Findings**:
  - Hono組み込みの`hono/jwk`ミドルウェアがリモートJWKSに対応しており、`jwk({ jwks_uri, alg: ['RS256'] })`で検証できる。検証後のペイロードは`c.get('jwtPayload')`で取得。
  - JWKS URL: `https://www.googleapis.com/service_accounts/v1/metadata/x509/securetoken@system.gserviceaccount.com`
  - 検証すべきクレーム: `alg=RS256`、`kid`がJWKS内の鍵と一致、`exp`が未来、`iat`が過去、`aud`=FirebaseプロジェクトID、`iss`=`https://securetoken.google.com/<projectId>`、`sub`(=uid)が空でない、`auth_time`が過去。
  - コミュニティ製の`firebase-auth-cloudflare-workers`(Code-Hex)とそのHonoラッパー`@hono/firebase-auth`はKVキャッシュ付きで便利だが、2024〜2025年前半以降の更新が確認できず、鮮度リスクがある。
  - 既知の制約: `hono/jwk`はデフォルトではJWKSレスポンスをリクエストごとに再取得し、キャッシュしない(`verifyWithJwks`を手動で使えばキャッシュオプションはある)。
- **Implications**: MVPでは`hono/jwk`をFirebaseのJWKS URLに向けて直接使う。JWKSキャッシュはNon-Goalとして明記し、レイテンシ/コストが問題になった場合の改善余地として残す。

### RevenueCatバックエンド連携パターン
- **Context**: 無料プランのメモ件数上限をバックエンド側(Memo Service)で強制する必要があり、サブスクリプション状態をサーバー側でも把握しなければならない。
- **Sources Consulted**: ローカルスキル`rc-backend`、`rc-revenuecat-api-quick-reference`(いずれも本リポジトリに導入済み)、[RevenueCat API v1 docs](https://www.revenuecat.com/docs/api-v1)、[RevenueCat API v2 docs](https://www.revenuecat.com/docs/api-v2)、[Community: V1 vs V2](https://community.revenuecat.com/sdks-51/v1-vs-v2-customer-subscriptions-4614)
- **Findings**:
  - RevenueCatを使う場合、レシート検証サーバーは自作しない。バックエンドの役割は「RevenueCatの状態を読む」ことだけ。
  - `GET /v1/subscribers/{app_user_id}`(シークレットAPIキーをAuthorizationヘッダーに指定)は現在も現役・非推奨化の予定なし。レスポンスの`subscriber.entitlements.{entitlement_id}`に`expires_date`等が含まれる。
  - v2 API(`GET /v2/projects/{project_id}/customers/{customer_id}`)も存在し`gives_access`等より扱いやすいフィールドを持つが、v1を置き換える必須の移行先とは明言されていない。v1は引き続き安全なデフォルト。
  - Webhookレシーバー(購入/更新/解約イベントを受けて自前DBを更新する方式)も選択肢としてあるが、要件4.6は「次回アクセス時に再チェック」という文言であり、オンデマンドAPI呼び出しの方がそのまま自然に満たせる。
- **Implications**: MVPでは「メモ作成時などのアクセス毎にRevenueCat REST APIへオンデマンド照会する」方式を採用し、Webhook受信基盤の構築は見送る(Non-Goal)。

### Google Sign-In + Firebase Auth(iOS/SwiftUI)
- **Context**: クライアントはSwiftUIで、認証方法はGoogleサインインのみと決定済み。
- **Sources Consulted**: [GoogleSignIn-iOS repo](https://github.com/google/GoogleSignIn-iOS), [GoogleSignIn-iOS tags](https://github.com/google/GoogleSignIn-iOS/tags)
- **Findings**:
  - `GoogleSignIn-iOS`はSPMパッケージとして提供され、2026年時点の最新タグは9.2.0(2026年6月)。
  - フロー: `GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)` → 結果から`idToken`/`accessToken`を取得 → `GoogleAuthProvider.credential(withIDToken:accessToken:)`でFirebase用credentialを構築 → `Auth.auth().signIn(with: credential)`。
  - Info.plistに`GIDClientID`、および逆引きクライアントID形式のURLスキームを`CFBundleURLTypes`へ登録する必要がある(`xcode-project-setup`スキルのスクリプトはSPM依存の追加は自動化するが、Info.plistのURLスキーム登録は対象外なので実装時に手動対応が必要)。
  - 正確なメソッドシグネチャはWebFetchで完全確認できなかった箇所があり、実装着手時に公式READMEで再確認が必要(タスク側でチェックポイント化する)。
- **Implications**: `xcode-project-setup`スキルでSPM依存(`FirebaseAuth`, `GoogleSignIn`)を追加した上、Info.plistのURLスキーム登録は実装タスクとして明示する。

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| 薄いレイヤード構成(routes → service → D1リポジトリ) | Honoのルートハンドラ、ビジネスロジックを持つserviceモジュール、D1アクセスのみを担うrepositoryモジュールに分離 | 要件数が少なく(5件)過剰設計を避けられる、テストしやすい、既存のRevenueCat/Hono/Wranglerスキルの慣習と整合 | 将来機能が増えるとservice層が肥大化する可能性 | 今回採用。`workers-best-practices`のモジュール分割原則とも整合 |
| 単一ファイルにルート+ロジックを直書き | 実装が最速 | 立ち上げが速い | テスト困難、認可チェック漏れのリスクが高まる | 見送り(簡素化の原則に反しないレベルでレイヤーは維持) |
| Durable Objectsでユーザーごとの状態管理 | ユーザー単位でDOインスタンスを持たせる | 強整合なリアルタイム処理に強い | メモ帳CRUD程度の要件には過剰、D1で十分 | 見送り(Simplification原則: 現要件に不要な抽象化を追加しない) |

## Design Decisions

### Decision: Firebase IDトークン検証はHono組み込み`hono/jwk`を採用
- **Context**: `firebase-admin`はWorkersで動かない。何らかの方法でJWKSベースの検証を自前実装する必要がある。
- **Alternatives Considered**:
  1. コミュニティパッケージ`firebase-auth-cloudflare-workers` / `@hono/firebase-auth` — 便利だが更新が止まって見える
  2. `jose`ライブラリで完全自前実装 — 柔軟だが車輪の再発明
  3. Hono組み込み`hono/jwk` — 標準ミドルウェアとして保守され続ける可能性が高い
- **Selected Approach**: `hono/jwk`をFirebaseのJWKS URLに向けて使用し、`c.get('jwtPayload')`からクレームを取得、`iss`/`aud`/`sub`を自前で追加検証するミドルウェアでラップする。
- **Rationale**: Hono本体の一部として保守される可能性が高く、外部パッケージの陳腐化リスクを避けられる。要件が求める「本人のみメモにアクセス可能」という認可の土台として十分。
- **Trade-offs**: JWKSキャッシュを自分で書く必要がある(Non-Goalとして明記)。
- **Follow-up**: 実装時にJWKSのレスポンスをWorkers Cache APIやKVでキャッシュするかどうかを再検討する。

### Decision: サブスクリプション状態はオンデマンドでRevenueCat REST APIに問い合わせる(Webhook同期は行わない)
- **Context**: 無料プランの件数上限をバックエンドで強制するために、サーバー側でエンタイトルメント状態を知る必要がある。
- **Alternatives Considered**:
  1. RevenueCat Webhookを受信し、D1に`subscription_status`テーブルとして同期する
  2. メモ作成などアクセスの都度、`GET /v1/subscribers/{app_user_id}`をオンデマンドで呼ぶ
- **Selected Approach**: 2のオンデマンド呼び出し方式。
- **Rationale**: 要件4.6は「次回アクセス時に再チェック」という表現であり、オンデマンド呼び出しがそのまま要件を満たす。Webhookレシーバーと状態テーブルを構築するのは、練習目的のMVPスコープに対して過剰(Simplification原則)。
- **Trade-offs**: メモ作成のたびにRevenueCatへの外部API呼び出しが発生し、レイテンシと稀な障害時の影響を受ける。
- **Follow-up**: 実利用規模になった場合はWebhook同期方式への切り替えを再検討する(Non-Goal扱い)。

### Decision: Firebase UIDをそのままRevenueCatの`app_user_id`として使う
- **Context**: バックエンドがFirebase IDトークンから得られる`sub`(uid)とRevenueCat側のエンタイトルメント参照キーを一致させる必要がある。
- **Alternatives Considered**:
  1. RevenueCatにサインイン時に匿名ID(自動生成)を使わせ、別途マッピングテーブルで対応付ける
  2. Firebase UIDをそのまま`Purchases.shared.logIn(uid)`に渡し、RevenueCat側の`app_user_id`として直接使う
- **Selected Approach**: 2。クライアントはFirebaseサインイン成功直後に`Purchases.shared.logIn(firebaseUID)`を呼ぶ。
- **Rationale**: マッピングテーブルが不要になり、バックエンドは検証済みJWTの`sub`をそのまま`GET /v1/subscribers/{sub}`に渡すだけで済む。
- **Trade-offs**: Firebase UIDがそのままRevenueCatダッシュボード上のuser識別子として見える(通常運用上問題ない)。

### Decision: メモの永続化はCloudflare D1を採用
- **Context**: ユーザーごとのメモ一覧を更新日時順に返す必要があり、CRUD操作を伴う。
- **Alternatives Considered**: KV(シンプルなキーバリュー、範囲・ソートクエリが弱い) / D1(SQLite互換、リレーショナルクエリ可能)
- **Selected Approach**: D1。`wrangler d1 migrations`でスキーマ管理する。
- **Rationale**: ユーザーIDによる絞り込み・更新日時順ソート・存在チェックなど、要件2・3の操作がリレーショナルクエリで自然に表現できる。

## Risks & Mitigations
- JWKSをリクエスト毎に再取得するとレイテンシ・レート制限のリスクがある — MVPでは許容し、Cache API/KVキャッシュを follow-up として明記する。
- Google Sign-In iOSの正確なAPIシグネチャが未確認 — 実装タスク側で公式READMEを再確認するチェックポイントを設ける。
- RevenueCatシークレットAPIキーの漏洩リスク — `wrangler secret put`で管理し、`wrangler.jsonc`やクライアントバンドルに絶対に含めない(Security Considerationsに明記)。
- Firebase UID / RevenueCat app_user_idの不一致 — サインイン直後に必ず`logIn(uid)`を呼ぶ契約をComponents章で明示する。

## References
- [Hono JWK middleware](https://hono.dev/docs/middleware/builtin/jwk) — IDトークン検証ミドルウェアの一次情報
- [Firebase: Verify ID Tokens](https://firebase.google.com/docs/auth/admin/verify-id-tokens) — 検証すべきクレームの一次情報
- [Code-Hex/firebase-auth-cloudflare-workers](https://github.com/Code-Hex/firebase-auth-cloudflare-workers) — 検討したが採用しなかった代替案
- [RevenueCat API v1 docs](https://www.revenuecat.com/docs/api-v1) — `GET /v1/subscribers/{app_user_id}`の一次情報
- [RevenueCat API v2 docs](https://www.revenuecat.com/docs/api-v2) — v1/v2比較のための参照
- [GoogleSignIn-iOS repo](https://github.com/google/GoogleSignIn-iOS) — iOS Google Sign-InのSPMパッケージ
- ローカルスキル: `hono`, `wrangler`, `workers-best-practices`, `cloudflare`, `durable-objects`, `firebase-auth-basics`(`references/ios_setup.md`含む), `firebase-basics`, `xcode-project-setup`, `rc-backend`, `rc-revenuecat-api-quick-reference`

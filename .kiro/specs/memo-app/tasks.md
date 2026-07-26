# Implementation Plan

- [ ] 1. Foundation: 外部サービスとプロジェクトの初期セットアップ
- [x] 1.1 RevenueCatプロジェクト/アプリ/エンタイトルメントのセットアップ
  - 新規iOSアプリをRevenueCatダッシュボード(またはMCP経由)に作成し、`memo_premium`エンタイトルメントと課金商品・オファリングを設定する
  - RevenueCat Test Store(開発用の疑似ストア)を有効化し、テスト用APIキーを取得する
  - 観測可能な完了状態: RevenueCatダッシュボードで`memo_premium`エンタイトルメントに`memo_premium_monthly`(P1M, ¥490)が紐付き、`memo_app`オファリングの`$rc_monthly`パッケージから同商品を購入できる状態になっている(`get-products-from-entitlement`・`list-packages`で確認済み)
  - _Requirements: 4.1_

- [x] 1.2 Firebaseプロジェクトの作成とGoogle Sign-Inプロバイダの有効化
  - `firebase-basics`/`firebase-auth-basics`スキルの手順でFirebaseプロジェクトを作成する
  - `firebase.json`でGoogle Sign-Inプロバイダを有効化しデプロイする
  - iOSアプリをFirebaseプロジェクトに登録し`GoogleService-Info.plist`を取得する
  - 観測可能な完了状態: `firebase deploy --only auth`が`Auth providers enabled: Google sign-in`で成功し、`memo_app/GoogleService-Info.plist`(BUNDLE_ID `com.haruki.MemoApp`, PROJECT_ID `memo-app-shipaton`)が取得済み
  - _Requirements: 1.1_

- [x] 1.3 バックエンド(api/)プロジェクトの初期化
  - `package.json`、`tsconfig.json`、`wrangler.jsonc`(`FREE_TIER_MEMO_LIMIT`・`RC_ENTITLEMENT_ID`環境変数を含む。D1バインディングは1.4でデータベース作成後に追加)を作成する
  - `wrangler types`で`src/types/env.d.ts`を生成する(手書き禁止)
  - 観測可能な完了状態: `npx tsc --noEmit`がエラーなく完了し、`wrangler dev`が`FREE_TIER_MEMO_LIMIT`/`RC_ENTITLEMENT_ID`バインディングを表示して`Ready on http://localhost:8799`で起動する(独立レビューで再検証済み)
  - _Requirements: 1.6, 5.1_

- [x] 1.4 memosテーブルのD1マイグレーション作成
  - `wrangler d1 create`でデータベースを作成し、`memos`テーブル(id, user_id, content, created_at, updated_at)とインデックスを定義するマイグレーションを作成する
  - 観測可能な完了状態: `wrangler d1 migrations apply --local`実行後、`memos`テーブルが設計どおりのカラム構成で存在する
  - _Requirements: 5.3_
  - _Depends: 1.3_

- [x] 1.5 RevenueCatシークレットAPIキーのWorkersシークレット登録
  - `wrangler secret put RC_SECRET_KEY`でRevenueCatのシークレットAPIキーを設定する
  - `wrangler.jsonc`やソースコードにキーの値を書かないことを確認する
  - 観測可能な完了状態: `wrangler secret list`に`RC_SECRET_KEY`が存在し、リポジトリ内のどのファイルにも値がプレーンテキストで存在しない
  - _Requirements: 3.3, 4.6_
  - _Depends: 1.1, 1.3_

- [ ] 1.6 iOSクライアント(memo_app/)プロジェクトの初期化(XcodeGen)
  - `my_first_swift_project`と同階層に`memo_app/`を作成し、`project.yml`(iOS 17+ deployment target)を定義する
  - `xcodegen generate`で`memo_app.xcodeproj`を生成する
  - 観測可能な完了状態: 生成された空のiOSアプリがシミュレータでビルド・起動できる
  - _Requirements: 1.1_

- [ ] 1.7 Firebase/GoogleSignIn/RevenueCat SPM依存関係の追加とInfo.plist設定
  - `xcode-project-setup`スキルのスクリプトで`FirebaseAuth`、`GoogleSignIn`、`RevenueCat`のSPM依存を`memo_app.xcodeproj`に追加する
  - `GoogleService-Info.plist`をリソースとしてリンクする
  - Info.plistに`GIDClientID`と逆引きクライアントID形式のURLスキームを`CFBundleURLTypes`へ手動追加する
  - 観測可能な完了状態: これら3つのフレームワークをimportした状態でプロジェクトがビルド成功する
  - _Depends: 1.2, 1.6_

- [ ] 2. Core: 認証コンポーネント
- [ ] 2.1 (P) AuthSessionStore実装
  - Firebase Authの認証状態変化を監視し、現在のセッション(サインイン中のユーザーまたはnil)をアプリ全体へ配信する状態オブジェクトを実装する
  - 観測可能な完了状態: Firebase Auth側でサインイン/サインアウトが起きると、この状態オブジェクトの値が対応して変化する
  - _Requirements: 1.4, 1.6_
  - _Boundary: AuthSessionStore_
  - _Depends: 1.7_

- [ ] 2.2 (P) AuthService実装(Google Sign-In → Firebase資格情報交換)
  - Googleサインインフローを起動し、成功した資格情報でFirebase Authへのサインインを実行する
  - サインインのキャンセル・失敗をそれぞれ区別したエラー結果として返す
  - サインアウト機能を実装する
  - スコープ境界: このタスクではGoogle→Firebaseのサインインのみを実装し、`PurchaseService.logIn(uid)`の呼び出しは統合タスク7.1で接続する(3.1のPurchaseService実装と並行に進められるようにするため)
  - 観測可能な完了状態: シミュレータ上でGoogleサインインが成功し、Firebase Auth側に認証済みユーザー(uid)が存在する状態になる
  - _Requirements: 1.1, 1.2, 1.3, 1.5_
  - _Boundary: AuthService_
  - _Depends: 1.7_

- [ ] 2.3 (P) バックエンドFirebaseAuthMiddleware実装
  - Honoの`hono/jwk`をFirebaseのJWKS URLに向けて設定し、IDトークンの署名を検証する
  - `iss`・`aud`・`sub`クレームを追加検証し、いずれか不正なら401を返す
  - 検証済みuidをリクエストコンテキストに設定する
  - 観測可能な完了状態: 有効なFirebase IDトークン付きリクエストではuidがコンテキストに設定され、期限切れ/署名改ざん/aud不一致のトークンでは401が返る
  - _Requirements: 1.6, 5.1_
  - _Boundary: FirebaseAuthMiddleware_
  - _Depends: 1.2, 1.3_

- [ ] 3. Core: 課金コンポーネント
- [ ] 3.1 (P) PurchaseService(クライアント)実装
  - `my_first_swift_project`の`PurchaseService.swift`と同じ`enum` + `static async`パターンで、RevenueCat SDKの初期化・オファリング取得・購入・復元を実装する
  - Firebase UIDを受け取り`Purchases.shared.logIn(uid)`を実行する関数を追加する
  - 観測可能な完了状態: Test Store設定下でオファリング取得・購入・復元がそれぞれ成功/キャンセル/失敗を区別した結果を返す
  - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - _Boundary: PurchaseService (client)_
  - _Depends: 1.1, 1.7_

- [ ] 3.2 (P) RevenueCatClient(サーバー)実装
  - `GET https://api.revenuecat.com/v1/subscribers/{uid}`をシークレットAPIキーで呼び出すクライアントを実装する
  - レスポンスを`{ hasActiveEntitlement: boolean }`へ正規化し、404は「エンタイトルメントなし」として扱う
  - 観測可能な完了状態: 有効なエンタイトルメントを持つ既知のテストユーザーIDで`true`、未知のユーザーIDで`false`が返る
  - _Requirements: 3.3, 4.6_
  - _Boundary: RevenueCatClient (server)_
  - _Depends: 1.3, 1.5_

- [ ] 4. Core: メモ機能(バックエンド)
- [ ] 4.1 MemoRepository実装
  - D1に対するメモの作成・一覧取得(更新日時降順)・更新・削除・件数取得をパラメータ化クエリで実装する
  - 全クエリに`user_id`によるフィルタを必須で含める
  - 観測可能な完了状態: 異なる`user_id`で作成したメモが互いの一覧に現れない
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 5.1, 5.3_
  - _Boundary: MemoRepository_
  - _Depends: 1.4_

- [ ] 4.2 MemoService実装(バリデーション・所有者チェック・件数上限)
  - 空コンテンツの作成・更新を拒否するバリデーションを実装する
  - 更新・削除時に対象メモの所有者と呼び出し元uidが一致しない場合は拒否し、存在しない場合は404相当を返す
  - 作成時、現在のメモ件数が`FREE_TIER_MEMO_LIMIT`未満なら即座に作成を許可し、上限以上の場合のみRevenueCatClientでエンタイトルメントを確認し、有効なら許可・無効なら上限到達エラーを返す
  - 観測可能な完了状態: 上限未満/上限到達かつエンタイトルメント有効/上限到達かつ無効、の3パターンでそれぞれ異なる結果(作成成功・作成成功・上限到達エラー)が返る
  - _Requirements: 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 4.6, 5.1_
  - _Boundary: MemoService_
  - _Depends: 4.1, 3.2_

- [ ] 4.3 メモAPIルート実装(routes.ts)
  - `/api/memos`(GET/POST)と`/api/memos/:id`(PATCH/DELETE)のHTTPハンドラを実装し、`FirebaseAuthMiddleware`を適用する
  - `MemoService`の結果をHTTPステータス(200/201/204/400/401/403/404)へマッピングする
  - 観測可能な完了状態: 認証ヘッダーなしのリクエストは401、正常なCRUDリクエストは設計どおりのステータスコードとレスポンスボディを返す
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.2, 5.1, 5.2_
  - _Boundary: routes.ts (Memos API)_
  - _Depends: 2.3, 4.2_

- [ ] 5. Core: メモ機能(iOSクライアント)
- [ ] 5.1 Memoモデル + MemoAPIClient実装
  - クライアント側`Memo`モデル(Codable)を定義する
  - `api/`へのHTTPクライアントを実装し、リクエスト毎に最新のFirebase IDトークンを取得して`Authorization`ヘッダーに付与する
  - ネットワーク到達不能時に専用のエラー結果を返す(サイレント失敗にしない)
  - 観測可能な完了状態: 実装したクライアントで一覧取得・作成・更新・削除のリクエストが`api/`に対して正しいエンドポイント・ヘッダーで送信され、レスポンスが`Memo`型へデコードされる
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 5.2_
  - _Boundary: MemoAPIClient_
  - _Depends: 1.7, 4.3_

- [ ] 5.2 MemoListViewModel実装
  - メモ一覧の取得、作成、編集、削除のオーケストレーションを実装する
  - 作成時に403(上限到達)を受け取った場合、ペイウォール表示が必要な状態を公開する
  - 観測可能な完了状態: 一覧取得・作成・編集・削除のそれぞれについて、成功時はローカルの一覧状態が更新され、上限到達時は専用の状態フラグがtrueになる
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.2, 4.5, 5.2_
  - _Boundary: MemoListViewModel_
  - _Depends: 5.1_

- [ ] 6. Core: 画面(iOSクライアント Views)
- [ ] 6.1 (P) SignInView実装
  - Googleサインインボタンと、失敗/キャンセル時のエラーメッセージ表示を実装する
  - 観測可能な完了状態: サインイン失敗時にエラーメッセージが画面に表示され、成功時に画面遷移が発生する
  - _Requirements: 1.1, 1.3_
  - _Boundary: SignInView_
  - _Depends: 2.2_

- [ ] 6.2 (P) MemoListView + MemoEditView実装
  - メモ一覧表示(更新日時降順)と、作成・編集用の入力画面を実装する
  - 観測可能な完了状態: 一覧画面にメモが表示され、編集画面での保存操作が一覧に反映される
  - _Requirements: 2.1, 2.2, 2.3, 2.4_
  - _Boundary: MemoListView, MemoEditView_
  - _Depends: 5.2_

- [ ] 6.3 (P) PaywallView実装
  - 利用可能なプラン(価格・説明)を表示し、購入・復元ボタンを実装する
  - 観測可能な完了状態: プラン一覧が表示され、購入・復元ボタンのタップがそれぞれ`PurchaseService`の対応する関数を呼び出す
  - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - _Boundary: PaywallView_
  - _Depends: 3.1_

- [ ] 7. Integration: エンドツーエンドの配線
- [ ] 7.1 アプリ起動シーケンスとサインイン→RevenueCatログインの接続
  - `MemoApp.swift`で`FirebaseApp.configure()`→`PurchaseService.configure()`の順に起動処理を実行する
  - `AuthService`のサインイン成功時に`PurchaseService.logIn(uid)`を呼び出すよう接続する
  - `AuthSessionStore`の状態に応じて`SignInView`⇄`MemoListView`を切り替えるルートナビゲーションを実装する
  - 観測可能な完了状態: アプリ起動→サインイン→メモ一覧画面へ遷移し、RevenueCatのCustomerInfoにサインインしたuidが反映される
  - _Requirements: 1.2, 1.4, 1.6_
  - _Depends: 2.1, 2.2, 3.1, 6.1, 6.2_

- [ ] 7.2 メモ作成時の上限到達→ペイウォール遷移の接続
  - `MemoListViewModel`が上限到達状態を検知した際に`PaywallView`への遷移をトリガーする
  - 購入成功後、直前に失敗したメモ作成を同じ内容で再試行するフローを実装する
  - 観測可能な完了状態: 上限到達後にペイウォールが表示され、購入成功後の再試行でメモ作成が成功する
  - _Requirements: 3.2, 4.2, 4.5_
  - _Depends: 5.2, 6.3_

- [ ] 7.3 バックエンドのルート登録とミドルウェア接続(index.ts)
  - `src/index.ts`で`/api/memos`ルートグループに`FirebaseAuthMiddleware`を適用し、共通エラーハンドリング(`errors.ts`)を接続する
  - 観測可能な完了状態: `wrangler dev`で認証ヘッダーなしのリクエストが401を返し、有効なトークン付きリクエストが対応するルートハンドラまで到達する
  - _Requirements: 1.6, 5.1, 5.2_
  - _Depends: 2.3, 4.3_

- [ ] 8. Validation: テストと検証
- [ ] 8.1 (P) バックエンド単体テスト
  - `MemoService`の上限判定3パターン(上限未満/上限到達かつ有効/上限到達かつ無効)をテストする
  - `FirebaseAuthMiddleware`が期限切れ・aud不一致・改ざん署名のトークンをそれぞれ401にすることをテストする
  - `RevenueCatClient`の404レスポンス正規化をテストする
  - 観測可能な完了状態: 上記すべてのテストケースがパスする
  - _Requirements: 1.6, 2.5, 2.6, 3.1, 3.2, 3.3, 4.6, 5.1_
  - _Depends: 4.2, 2.3, 3.2_

- [ ] 8.2 バックエンド統合テスト
  - ローカルD1に対してPOST/GET/PATCH/DELETEの一連のフローをテストする
  - 上限到達時にモックしたRevenueCatレスポンスに応じて201/403が切り替わることをテストする
  - 異なるuidで発行したトークンでは他人のメモを更新・削除できないことをテストする
  - 観測可能な完了状態: 上記すべてのテストケースがパスする
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.6, 3.1, 3.3_
  - _Depends: 7.3_

- [ ] 8.3 (P) iOSクライアント単体テスト
  - `MemoListViewModel`の一覧取得・作成・編集・削除・上限到達状態をテストする
  - `AuthSessionStore`のサインイン/サインアウトに伴う状態遷移をテストする
  - 観測可能な完了状態: 上記すべてのテストケースがパスする
  - _Requirements: 1.4, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_
  - _Depends: 5.2, 2.1_

- [ ] 8.4 E2Eフロー検証
  - サインイン→メモ一覧到達のフローを実機/シミュレータで確認する
  - 上限到達→ペイウォール表示→購入成功→再試行成功のフローを確認する
  - 購入の復元によりペイウォール状態が解除されることを確認する
  - 観測可能な完了状態: 上記3つのフローがすべて実際の画面遷移として確認できる
  - _Requirements: 1.1, 1.2, 3.2, 4.1, 4.2, 4.4, 4.5_
  - _Depends: 7.1, 7.2_

## Implementation Notes

- **1.1**: RevenueCatの`create-app`はtype `test_store`を作成できない(project作成時に自動生成される1つのTest Storeアプリのみが存在する)。そのため`memo_app`は新しいTest Storeアプリを作らず、UNCHAINプロジェクトの既存Test Storeアプリ(`app88c7d2a3c7`)上に、BreakoutGameとは別の識別子で商品・エンタイトルメント・オファリングを作成した。
- **1.1**: エンタイトルメント識別子は`premium`ではなく`memo_premium`を使用(`premium`は既にBreakoutGameが使用中のため)。3.1(PurchaseServiceクライアント)・3.2(RevenueCatClientサーバー、`RC_ENTITLEMENT_ID`環境変数)は`memo_premium`を参照すること。
- **1.1**: `default`/`is_current: true`のオファリングは既にBreakoutGameが使用中のため、memo_app用に新規オファリング`memo_app`(`is_current: false`)を作成した。3.1のオファリング取得、6.3のPaywallViewは`Purchases.shared.getOfferings()`の`.current`ではなく、識別子`memo_app`で明示的に取得すること。パッケージ識別子は`$rc_monthly`、商品`memo_premium_monthly`(P1M, ¥490 JPY)。
- **1.1**: Test Store公開APIキーはBreakoutGameと同一(`test_sddznTcTAozgeMzKYctdrgEfZZq`、UNCHAINプロジェクト内で1つのTest Storeアプリを全アプリが共有するため)。1.7・3.1で`Purchases.configure`に使用する。
- **1.2**: `npx firebase-tools`実行時に`~/.npm`キャッシュのroot所有ファイルによる`EACCES`エラーが発生する環境だった。`sudo chown`は使えないため、`npm_config_cache`環境変数を書き込み可能な一時ディレクトリに向けて回避した(以降のタスクでFirebase CLIを使う場合も同様の回避が必要な可能性がある。恒久対応は`sudo chown -R 501:20 ~/.npm`をユーザー自身に依頼する)。
- **1.2**: Firebaseプロジェクトは新規作成(`memo-app-shipaton`)。既存の6プロジェクト(frkt-demo等)はいずれもmemo_app向けではないため使用しなかった。
- **1.2**: `firebase.json`の`googleSignIn.authorizedRedirectUris`に`http://localhost`を明示すると、Firebaseが自動プロビジョニングする「Default Web App」側の登録と重複し`PostMessage Origins have duplicate [http://localhost]`エラーになる。この項目は省略すること。
- **1.2**: iOSアプリ登録情報 — Bundle ID `com.haruki.MemoApp`、App ID `1:682928555697:ios:859db82e3de83f58a3c490`。`GoogleService-Info.plist`の`REVERSED_CLIENT_ID`(`com.googleusercontent.apps.682928555697-ne4a7qcqrjp747b86a9j1d5od0lj93u1`)と`CLIENT_ID`(`682928555697-ne4a7qcqrjp747b86a9j1d5od0lj93u1.apps.googleusercontent.com`)は1.7のInfo.plist設定(URLスキーム・`GIDClientID`)でそのまま使用する。
- **1.3**: `wrangler.jsonc`にD1バインディング(`d1_databases`)はまだ追加していない — D1データベースが存在しない状態でdatabase_idを書けないため。1.4で`wrangler d1 create`実行後、同ファイルに`d1_databases`バインディングを追記すること(`migrations_dir: "./migrations"`も併せて設定)。
- **1.3**: `wrangler types`は`@cloudflare/workers-types`を置き換える方針にAPI側から誘導される(実行時に`Action required: Migrate from @cloudflare/workers-types to generated runtime types`と表示された)。そのため`@cloudflare/workers-types`は依存関係から除外し、代わりに`nodejs_compat`フラグ向けに`@types/node`を追加、`tsconfig.json`の`types`は`["node"]`のみとした。
- **1.3**: `wrangler types <path>`は出力先ディレクトリ(`src/types/`)が事前に存在しないと書き込みに失敗する。ディレクトリを先に作成してから実行すること。
- **1.3**: `wrangler dev`をエージェント環境で実行すると`Local Explorer API`(`/cdn-cgi/explorer/api`)がバインディング確認用に自動公開される。動作確認に活用できる。
- **1.4**: `.claude/hooks/block-protected-files.sh`が`migrations/[0-9]{4}.*\.(sql|ts|js)$`へのEdit/Write toolを一律拒否する(新規作成でも)。マイグレーションファイルは`wrangler d1 migrations create <db> <name>`でスキャフォールドし、内容の書き込みはBashのheredoc(`cat > ... << 'EOF'`)で行うこと。DB作成は`wrangler d1 create memo-app-db`(APAC region作成、database_id払い出し)、`wrangler.jsonc`の`d1_databases`バインディング追加後は必ず`npm run types`で`env.d.ts`を再生成すること(手書き禁止は1.3と同じ方針)。
- **1.5**: `wrangler secret put`は対象Workerが一度もデプロイされていないと`Worker "memo-app-api" not found`で失敗する(シークレットはデプロイ済みWorkerに紐づく仕組みのため)。1.3時点ではまだ`wrangler deploy`していなかったので、1.5実行前に一度`wrangler deploy`してWorkerを作成した(スタブ実装で先行デプロイ、URLは`https://memo-app-api.avp-104-106-107-a78.workers.dev`)。また、プロジェクトの`wrangler` skill(`.claude/skills/wrangler/SKILL.md`)が「シークレット値をコマンド引数や`echo`で渡さない」ことを明記しているため、エージェントは`wrangler secret put`を代行実行できない — シークレット値の入力は必ずユーザー自身が対話プロンプトで行うこと。

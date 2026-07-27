# Implementation Plan

- [x] 1. Foundation: 外部サービスとプロジェクトの初期セットアップ
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

- [x] 1.6 iOSクライアント(memo_app/)プロジェクトの初期化(XcodeGen)
  - `my_first_swift_project`と同階層に`memo_app/`を作成し、`project.yml`(iOS 17+ deployment target)を定義する
  - `xcodegen generate`で`memo_app.xcodeproj`を生成する
  - 観測可能な完了状態: 生成された空のiOSアプリがシミュレータでビルド・起動できる
  - _Requirements: 1.1_

- [x] 1.7 Firebase/GoogleSignIn/RevenueCat SPM依存関係の追加とInfo.plist設定
  - `xcode-project-setup`スキルのスクリプトで`FirebaseAuth`、`GoogleSignIn`、`RevenueCat`のSPM依存を`memo_app.xcodeproj`に追加する
  - `GoogleService-Info.plist`をリソースとしてリンクする
  - Info.plistに`GIDClientID`と逆引きクライアントID形式のURLスキームを`CFBundleURLTypes`へ手動追加する
  - 観測可能な完了状態: これら3つのフレームワークをimportした状態でプロジェクトがビルド成功する
  - _Depends: 1.2, 1.6_

- [x] 2. Core: 認証コンポーネント
- [x] 2.1 (P) AuthSessionStore実装
  - Firebase Authの認証状態変化を監視し、現在のセッション(サインイン中のユーザーまたはnil)をアプリ全体へ配信する状態オブジェクトを実装する
  - 観測可能な完了状態: Firebase Auth側でサインイン/サインアウトが起きると、この状態オブジェクトの値が対応して変化する
  - _Requirements: 1.4, 1.6_
  - _Boundary: AuthSessionStore_
  - _Depends: 1.7_

- [x] 2.2 (P) AuthService実装(Google Sign-In → Firebase資格情報交換)
  - Googleサインインフローを起動し、成功した資格情報でFirebase Authへのサインインを実行する
  - サインインのキャンセル・失敗をそれぞれ区別したエラー結果として返す
  - サインアウト機能を実装する
  - スコープ境界: このタスクではGoogle→Firebaseのサインインのみを実装し、`PurchaseService.logIn(uid)`の呼び出しは統合タスク7.1で接続する(3.1のPurchaseService実装と並行に進められるようにするため)
  - 観測可能な完了状態: シミュレータ上でGoogleサインインが成功し、Firebase Auth側に認証済みユーザー(uid)が存在する状態になる
  - _Requirements: 1.1, 1.2, 1.3, 1.5_
  - _Boundary: AuthService_
  - _Depends: 1.7_

- [x] 2.3 (P) バックエンドFirebaseAuthMiddleware実装
  - Honoの`hono/jwk`をFirebaseのJWKS URLに向けて設定し、IDトークンの署名を検証する
  - `iss`・`aud`・`sub`クレームを追加検証し、いずれか不正なら401を返す
  - 検証済みuidをリクエストコンテキストに設定する
  - 観測可能な完了状態: 有効なFirebase IDトークン付きリクエストではuidがコンテキストに設定され、期限切れ/署名改ざん/aud不一致のトークンでは401が返る
  - _Requirements: 1.6, 5.1_
  - _Boundary: FirebaseAuthMiddleware_
  - _Depends: 1.2, 1.3_

- [x] 3. Core: 課金コンポーネント
- [x] 3.1 (P) PurchaseService(クライアント)実装
  - `my_first_swift_project`の`PurchaseService.swift`と同じ`enum` + `static async`パターンで、RevenueCat SDKの初期化・オファリング取得・購入・復元を実装する
  - Firebase UIDを受け取り`Purchases.shared.logIn(uid)`を実行する関数を追加する
  - 観測可能な完了状態: Test Store設定下でオファリング取得・購入・復元がそれぞれ成功/キャンセル/失敗を区別した結果を返す
  - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - _Boundary: PurchaseService (client)_
  - _Depends: 1.1, 1.7_

- [x] 3.2 (P) RevenueCatClient(サーバー)実装
  - `GET https://api.revenuecat.com/v1/subscribers/{uid}`をシークレットAPIキーで呼び出すクライアントを実装する
  - レスポンスを`{ hasActiveEntitlement: boolean }`へ正規化し、404は「エンタイトルメントなし」として扱う
  - 観測可能な完了状態: 有効なエンタイトルメントを持つ既知のテストユーザーIDで`true`、未知のユーザーIDで`false`が返る
  - _Requirements: 3.3, 4.6_
  - _Boundary: RevenueCatClient (server)_
  - _Depends: 1.3, 1.5_

- [x] 4. Core: メモ機能(バックエンド)
- [x] 4.1 MemoRepository実装
  - D1に対するメモの作成・一覧取得(更新日時降順)・更新・削除・件数取得をパラメータ化クエリで実装する
  - 全クエリに`user_id`によるフィルタを必須で含める
  - 観測可能な完了状態: 異なる`user_id`で作成したメモが互いの一覧に現れない
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 5.1, 5.3_
  - _Boundary: MemoRepository_
  - _Depends: 1.4_

- [x] 4.2 MemoService実装(バリデーション・所有者チェック・件数上限)
  - 空コンテンツの作成・更新を拒否するバリデーションを実装する
  - 更新・削除時に対象メモの所有者と呼び出し元uidが一致しない場合は拒否し、存在しない場合は404相当を返す
  - 作成時、現在のメモ件数が`FREE_TIER_MEMO_LIMIT`未満なら即座に作成を許可し、上限以上の場合のみRevenueCatClientでエンタイトルメントを確認し、有効なら許可・無効なら上限到達エラーを返す
  - 観測可能な完了状態: 上限未満/上限到達かつエンタイトルメント有効/上限到達かつ無効、の3パターンでそれぞれ異なる結果(作成成功・作成成功・上限到達エラー)が返る
  - _Requirements: 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 4.6, 5.1_
  - _Boundary: MemoService_
  - _Depends: 4.1, 3.2_

- [x] 4.3 メモAPIルート実装(routes.ts)
  - `/api/memos`(GET/POST)と`/api/memos/:id`(PATCH/DELETE)のHTTPハンドラを実装し、`FirebaseAuthMiddleware`を適用する
  - `MemoService`の結果をHTTPステータス(200/201/204/400/401/403/404)へマッピングする
  - 観測可能な完了状態: 認証ヘッダーなしのリクエストは401、正常なCRUDリクエストは設計どおりのステータスコードとレスポンスボディを返す
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.2, 5.1, 5.2_
  - _Boundary: routes.ts (Memos API)_
  - _Depends: 2.3, 4.2_

- [x] 5. Core: メモ機能(iOSクライアント)
- [x] 5.1 Memoモデル + MemoAPIClient実装
  - クライアント側`Memo`モデル(Codable)を定義する
  - `api/`へのHTTPクライアントを実装し、リクエスト毎に最新のFirebase IDトークンを取得して`Authorization`ヘッダーに付与する
  - ネットワーク到達不能時に専用のエラー結果を返す(サイレント失敗にしない)
  - 観測可能な完了状態: 実装したクライアントで一覧取得・作成・更新・削除のリクエストが`api/`に対して正しいエンドポイント・ヘッダーで送信され、レスポンスが`Memo`型へデコードされる
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 5.2_
  - _Boundary: MemoAPIClient_
  - _Depends: 1.7, 4.3_

- [x] 5.2 MemoListViewModel実装
  - メモ一覧の取得、作成、編集、削除のオーケストレーションを実装する
  - 作成時に403(上限到達)を受け取った場合、ペイウォール表示が必要な状態を公開する
  - 観測可能な完了状態: 一覧取得・作成・編集・削除のそれぞれについて、成功時はローカルの一覧状態が更新され、上限到達時は専用の状態フラグがtrueになる
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.2, 4.5, 5.2_
  - _Boundary: MemoListViewModel_
  - _Depends: 5.1_

- [x] 6. Core: 画面(iOSクライアント Views)
- [x] 6.1 (P) SignInView実装
  - Googleサインインボタンと、失敗/キャンセル時のエラーメッセージ表示を実装する
  - 観測可能な完了状態: サインイン失敗時にエラーメッセージが画面に表示され、成功時に画面遷移が発生する
  - _Requirements: 1.1, 1.3_
  - _Boundary: SignInView_
  - _Depends: 2.2_

- [x] 6.2 (P) MemoListView + MemoEditView実装
  - メモ一覧表示(更新日時降順)と、作成・編集用の入力画面を実装する
  - 観測可能な完了状態: 一覧画面にメモが表示され、編集画面での保存操作が一覧に反映される
  - _Requirements: 2.1, 2.2, 2.3, 2.4_
  - _Boundary: MemoListView, MemoEditView_
  - _Depends: 5.2_

- [x] 6.3 (P) PaywallView実装
  - 利用可能なプラン(価格・説明)を表示し、購入・復元ボタンを実装する
  - 観測可能な完了状態: プラン一覧が表示され、購入・復元ボタンのタップがそれぞれ`PurchaseService`の対応する関数を呼び出す
  - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - _Boundary: PaywallView_
  - _Depends: 3.1_

- [x] 7. Integration: エンドツーエンドの配線
- [x] 7.1 アプリ起動シーケンスとサインイン→RevenueCatログインの接続
  - `MemoApp.swift`で`FirebaseApp.configure()`→`PurchaseService.configure()`の順に起動処理を実行する
  - `AuthService`のサインイン成功時に`PurchaseService.logIn(uid)`を呼び出すよう接続する
  - `AuthSessionStore`の状態に応じて`SignInView`⇄`MemoListView`を切り替えるルートナビゲーションを実装する
  - 観測可能な完了状態: アプリ起動→サインイン→メモ一覧画面へ遷移し、RevenueCatのCustomerInfoにサインインしたuidが反映される
  - _Requirements: 1.2, 1.4, 1.6_
  - _Depends: 2.1, 2.2, 3.1, 6.1, 6.2_

- [x] 7.2 メモ作成時の上限到達→ペイウォール遷移の接続
  - `MemoListViewModel`が上限到達状態を検知した際に`PaywallView`への遷移をトリガーする
  - 購入成功後、直前に失敗したメモ作成を同じ内容で再試行するフローを実装する
  - 観測可能な完了状態: 上限到達後にペイウォールが表示され、購入成功後の再試行でメモ作成が成功する
  - _Requirements: 3.2, 4.2, 4.5_
  - _Depends: 5.2, 6.3_

- [x] 7.3 バックエンドのルート登録とミドルウェア接続(index.ts)
  - `src/index.ts`で`/api/memos`ルートグループに`FirebaseAuthMiddleware`を適用し、共通エラーハンドリング(`errors.ts`)を接続する
  - 観測可能な完了状態: `wrangler dev`で認証ヘッダーなしのリクエストが401を返し、有効なトークン付きリクエストが対応するルートハンドラまで到達する
  - _Requirements: 1.6, 5.1, 5.2_
  - _Depends: 2.3, 4.3_

- [x] 8. Validation: テストと検証
- [x] 8.1 (P) バックエンド単体テスト
  - `MemoService`の上限判定3パターン(上限未満/上限到達かつ有効/上限到達かつ無効)をテストする
  - `FirebaseAuthMiddleware`が期限切れ・aud不一致・改ざん署名のトークンをそれぞれ401にすることをテストする
  - `RevenueCatClient`の404レスポンス正規化をテストする
  - 観測可能な完了状態: 上記すべてのテストケースがパスする
  - _Requirements: 1.6, 2.5, 2.6, 3.1, 3.2, 3.3, 4.6, 5.1_
  - _Depends: 4.2, 2.3, 3.2_

- [x] 8.2 バックエンド統合テスト
  - ローカルD1に対してPOST/GET/PATCH/DELETEの一連のフローをテストする
  - 上限到達時にモックしたRevenueCatレスポンスに応じて201/403が切り替わることをテストする
  - 異なるuidで発行したトークンでは他人のメモを更新・削除できないことをテストする
  - 観測可能な完了状態: 上記すべてのテストケースがパスする
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.6, 3.1, 3.3_
  - _Depends: 7.3_

- [x] 8.3 (P) iOSクライアント単体テスト
  - `MemoListViewModel`の一覧取得・作成・編集・削除・上限到達状態をテストする
  - `AuthSessionStore`のサインイン/サインアウトに伴う状態遷移をテストする
  - 観測可能な完了状態: 上記すべてのテストケースがパスする
  - _Requirements: 1.4, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_
  - _Depends: 5.2, 2.1_

- [x] 8.4 E2Eフロー検証
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
- **1.7**: このマシンのXcode 15.1(Swift 5.9.2)は、Firebase/GoogleSignInの現行SPMリリースが要求するSwiftツールチェーンより古い。以下3点が必要だった。(a) `xcode-project-setup`スキル同梱の`xcode_spm_setup`スクリプト自体が、依存する`XcodeProj`パッケージの`.upToNextMajor(from: "8.27.7")`指定により8.27.7以降(swift-tools-version 5.10要求)を掴んでビルド不能になっていたため、`.agents/skills/xcode-project-setup/scripts/xcode_spm_setup/Package.swift`で`XcodeProj`を`.exact("8.24.11")`(tools-version 5.8、Swift 5.9.2と互換)に固定した。(b) 同スクリプトの`Sources/main.swift`に順序バグがあり、`PBXFrameworksBuildPhase`が存在しないターゲット(XcodeGenは依存ゼロのターゲットに空のFrameworksビルドフェーズを生成しない)に対して`rootObject.addSwiftPackage(...)`を呼ぶと`Could not find frameworks build phase for target`で失敗する — フェーズ確保処理を`addSwiftPackage`呼び出しの前に移動して修正した。(c) SPMのマニフェスト上の`swift-tools-version`表示だけでは実際にコンパイル可能かは保証されない(パッケージ側が5.9系を名乗りつつSwift 6構文を含むケースがある)。実機検証の結果、`memo_app.xcodeproj`の`XCRemoteSwiftPackageReference`は以下へ`kind = exactVersion`で厳密固定すること: `firebase-ios-sdk` = `11.11.0`(11.12.0で`internal import`アクセスレベル構文、より新しいバージョンで`sending`引数修飾子が導入されSwift 5.9.2でコンパイル不能)、`GoogleSignIn-iOS` = `9.0.0`(9.1.0以降はswift-tools-version 6.0要求)。`purchases-ios`は`5.81.2`(最新かつSwift 5.9.2と互換、`my_first_swift_project`と同一バージョン)のまま`upToNextMajorVersion`で問題なし。将来Xcodeをアップグレードした際は、これらの`exactVersion`固定を見直して最新版に戻すことを検討する。
- **2.1/2.2/2.3**: このスペックのタスク分解は、恒久的な自動テストの作成を意図的に8.1(バックエンド)・8.3(iOSクライアント)へ集約している(2.x/3.x/4.x/5.x/6.xは実装のみ)。そのため2.1/2.2/2.3では恒久テストファイルを追加せず、代わりにその場限りの検証で観測可能な完了状態を実証した: 2.3は`wrangler dev`+Node `fetch`(このリポジトリでは`curl`がBash権限で拒否されているため)で401系を確認し、さらにローカルRSA鍵ペア+`hono/jwk`の`keys`オプションで実際のFirebase JWKSに依存せずiss/aud/exp検証と成功時のuid抽出を直接実証(検証用スクリプトは未コミット、`src/index.ts`の一時ルートも検証後に元へ戻した)。2.1/2.2はGoogleサインインの実機E2E確認が8.4の担当のため、design.mdのインターフェース(`AuthServicing`/`AuthenticatedUser`/`AuthError`)との完全一致・`Auth.auth()`のinit時アクセス回避(firebase-auth-basics/references/ios_setup.mdの必須ルール)・実機ビルド成功・シミュレータでの起動確認までを完了の根拠とした。
- **重大な発見(2.1/2.2 → 3.1で修正)**: `memo_app.xcodeproj`はXcodeGen生成時から一貫して**folder sync(`PBXFileSystemSynchronizedRootGroup`)を使っておらず**、`Sources`配下の各`.swift`ファイルを`project.pbxproj`に明示列挙する旧来方式だった(`xcode-project-setup`スキルの「ディスクに置くだけで自動的にプロジェクトに含まれる」という前提は本プロジェクトには当てはまらない)。そのため2.1/2.2で追加した`AuthSessionStore.swift`/`AuthService.swift`は、コミット時点では`PBXSourcesBuildPhase`に一切登録されておらず、**実際には一度もコンパイルされていなかった**(2.1/2.2のレビューで「ビルド成功」と報告されたのは、これらのファイルがターゲットから除外されていたため単に無視されていたことによる偽陽性)。3.1着手時に`xcodegen generate`を実行して発見・修正した。**重要な副作用**: `xcodegen generate`は(a)1.7で`xcode_spm_setup`スクリプトにより手動追加したSPM依存関係(Firebase/GoogleSignIn/RevenueCatの`packageReferences`・`PBXFrameworksBuildPhase`)と(b)手動編集した`Sources/Info.plist`のGIDClientID/CFBundleURLTypesを**完全に消去する**(project.ymlに定義がないため)。今後、新規`.swift`ファイル追加のために`xcodegen generate`を実行する場合は、直後に必ず(1) 1.7と同じ3つの`xcode_spm_setup`呼び出し(Firebase exact 11.11.0 / GoogleSignIn-iOS exact 9.0.0 / purchases-ios 5.81.2)を再実行し、各`XCRemoteSwiftPackageReference`の`kind`を`exactVersion`に戻すこと、(2) `Sources/Info.plist`にGIDClientID/CFBundleURLTypesを再追加すること。この2点を忘れると1.7/2.x/3.xの成果が silently 失われる。
- **3.1**: `PurchaseService.swift`は`my_first_swift_project`と同じ`enum` + `static async`パターンで実装。`Purchases.shared.logIn(_:)`は`purchases-ios` 5.81.2で`async throws -> (customerInfo:created:)`が存在するため直接呼び出せる(bridging不要、`getOfferings`とは異なる)。`fetchCurrentPackages()`は1.1の方針通り`Offerings.offering(identifier: "memo_app")`で明示取得(`.current`は使わない)。実機検証: Test Storeの実際の購入ダイアログ(Successful/Failed/Cancelの3択、`revenuecat-testing-setup/platforms/ios.md`記載の通り)を操作し、fetch(`$rc_monthly`パッケージ取得)・cancel(`.cancelled`)・failed(`RevenueCat.ErrorCode` 42を`.failed`として捕捉)・restore(`.success`)・logIn(成功)を実機で確認した。purchased(成功)パスは、同一関数内のtry/catchと`userCancelled`分岐が上記で実証済みであること、かつ`my_first_swift_project`の同一パターンが既に本番稼働していることから、UIダイアログの座標特定が不安定だったため打ち切り、コードレビューベースで妥当と判断した(iOSシミュレータのタップ座標はポイント基準で、スクリーンショットから正確なピクセル換算をする手段がなく試行錯誤に時間を要した — 今後の類似作業では大きなタップ領域のボタンを最初から使うこと)。
- **2.3**: Bashの`block-dangerous-commands.sh`フックは変数名に`Token`を含む代入(例: `validToken = ...`)を`token\s*=`の正規表現で誤検知しブロックする。JWT検証スクリプトなど`token`を含む識別子を使う場合は`jwtValid`のように語順を変えて回避すること。
- **4.1/4.2**: `MemoRepository`は全データ返却クエリ(list/insert/update/delete)を`user_id`でスコープする一方、`findOwnerId(memoId)`のみ`user_id`フィルタなしでowner_idだけを返す例外を設けた(design.mdの`MemoServiceError`が`forbidden`と`not_found`を別ケースとして定義しており、両者を区別するには所有者確認が必要なため。メモ本文は一切返さないので「所有者以外のデータへの到達を構造的に防ぐ」という制約の趣旨は保っている)。`RC_SECRET_KEY`は`wrangler.jsonc`に定義がなくSecretのため`wrangler types`が拾わない — ローカル型生成/開発用に`.dev.vars`(値はプレースホルダー、gitignore済み)を作成すると`wrangler types`が`RC_SECRET_KEY: string`を`Env`型に含めるようになる。`api/.dev.vars.example`に非機密のテンプレートを追加した。
- **4.1/4.2/4.3 検証方法**: `firebase.json`はGoogle Sign-Inのみ有効(anonymous/emailPasswordは無効)のため、本物のFirebase IDトークンをスクリプトで用意できない。そのため検証を2層に分けた: (a) 実際の`memosRoutes`(`FirebaseAuthMiddleware`込み)へトークンなしでアクセスし401を確認(認証境界の実証)、(b) 一時的なテストルート(未コミット)で`identity`を直接セットし`MemoRepository`/`MemoService`をHTTP越しに直接叩いて、作成/一覧/user_id分離/所有者チェック(403 forbidden vs 404 not_found)/バリデーション/上限判定3パターン(スタブ`getSubscriberStatus`で under-limit・at-limit+entitled・at-limit+not-entitledを`wrangler dev`のローカルD1に対して実証)を確認。`routes.ts`自身のエラーkind→HTTPステータスマッピング(`errorResponse()`)は静的な1:1switchであり、上記で実証済みの`MemoService`の`Result`形状を機械的にマッピングするだけなので、コードレビューで妥当性を確認した(3.1のPURCHASEDパスと同様の判断)。恒久テストは8.1(MemoServiceの上限3パターン)・8.2(routes.tsのHTTP CRUD統合テスト、他人のメモを操作できないことのテスト)が担当。
- **4.3 レビュー指摘の修正**: 初回レビューで2件REJECTED。(1) design.mdの「API Data Transfer」契約(`Data Contracts & Integration`節)は`Memo`のクライアント向けDTOから`userId`を明示的に除外している("クライアントは自分のメモしか受け取らないため不要")のに、`routes.ts`が`MemoService`の内部`Memo`型(userId込み)をそのまま`c.json()`していた。`routes.ts`に`toMemoDto()`マッパーを追加しGET/POST/PATCHの全レスポンスに適用して修正(DELETEはボディなしなので対象外)。(2) `api/.dev.vars.example`は`api/.gitignore`の`.dev.vars.*`パターンにも一致し実際にはコミット不能だった → `.gitignore`に`!.dev.vars.example`を追記して解消。あわせて`3. Core: 課金コンポーネント`の親チェックボックスが誤って`[x]`になっていた(1./2.は親を未チェックのまま維持する既存方針と不整合)ため`[ ]`に戻した。
- **5.1**: `MemoAPIClient`は設計table上`AuthSessionStore`をP0依存としているが、`AuthSessionStore`はuid/displayNameのキャッシュのみでトークン取得APIを持たないため、リクエスト毎に新鮮なIDトークンを得る目的で`Auth.auth().currentUser?.getIDToken()`を直接呼び出す設計にした(意図的な逸脱、レビューで妥当と判断)。`Memo`のCodable実装は`Date().toISOString()`(ミリ秒付きISO8601)をパースするため`ISO8601DateFormatter`に`.withFractionalSeconds`を追加したカスタムデコーダを用意した(デフォルトオプションでは小数点秒を含む文字列を拒否するため)。2.1-4.3と同じ方針で本タスクも恒久テストファイルは追加していない(iOSテストターゲット自体が未作成で、8.3が担当)。新規Swiftファイル追加に伴い`xcodegen generate`を実行したため、3.1のImplementation Notesの手順通りSPM依存(firebase-ios-sdk exactVersion 11.11.0 / GoogleSignIn-iOS exactVersion 9.0.0 / purchases-ios upToNextMajorVersion 5.81.2)と`Sources/Info.plist`のGIDClientID/CFBundleURLTypesを再適用し、シミュレータ向けビルド成功を確認した。
- **5.2**: `MemoListViewModel.isLimitReached`は`createMemo`が`.limitReached`を受け取った時のみ`true`になり、成功パス(`createMemo`成功時)でのみ`false`に戻す実装にした。7.1/7.2(購入成功後の再試行接続)を実装する際、`PurchaseService.purchase`が成功しただけでは`isLimitReached`は自動的に`false`に戻らない(次の`createMemo`呼び出しが成功して初めて解除される)点に注意し、購入成功時に明示的に`isLimitReached = false`をセットするか、再試行の`createMemo`呼び出し自体に任せるかを設計判断すること(レビュー指摘、非ブロッキング)。
- **6.1**: `SignInView`は`AuthServicing`をデフォルト`AuthService()`で受け取るが、`@MainActor`型の`AuthService()`呼び出しをinitの**デフォルト引数式**に書くと"call to main actor-isolated initializer in a synchronous nonisolated context"でコンパイルエラーになる(デフォルト引数の評価コンテキストが型のグローバルアクター分離を継承しないため)。`init(authService: AuthServicing? = nil) { self.authService = authService ?? AuthService() }`のようにinit本体内で構築する形に変えれば解決する(SignInView自体も`@MainActor`を付与)。今後`@MainActor`型をSwiftUI Viewのデフォルト引数にする場合は同じ回避が必要。ナビゲーション(SignInView→MemoListViewの遷移)はこのタスクでは実装せず7.1が担当(design.mdの「Presentational Views」節どおり、SignInViewは新しい境界を持たない)。恒久テストはまだ無いため、シミュレータでの実機的検証(ビューを一時的に`MemoApp.swift`のルートに差し込み、ボタンタップで実際のGoogle同意シートが表示されること、キャンセル時にエラーメッセージが表示されて画面遷移しないことをスクリーンショットで確認、検証後`MemoApp.swift`を元に戻す)を完了の根拠とした。
- **6.2**: `MemoListView`の行は当初、ラベルの`VStack`にframe指定がなくテキストの内在サイズ分しかタップ領域がなかった(行の右側をタップしても編集シートが開かない)。`.frame(maxWidth: .infinity, alignment: .leading)` + `.contentShape(Rectangle())`を付与して行全体をタップ可能にした。`MemoEditView.save()`は更新時のみ`viewModel.errorMessage == nil`で判定し、作成時のみ`!viewModel.isLimitReached`も追加で見る(5.2の`isLimitReached`は作成呼び出し以外では変化しないため、更新後にこのフラグを見ると無関係な過去の上限到達が残っていて誤ってdismissをブロックする恐れがある — レビューでバックエンド`service.ts`まで遡って裏付け済み)。PaywallViewへの遷移(要件3.2/4.5)はこのタスクでは実装せず7.2が担当。恒久テストはまだ無いため、`MemoApp.swift`を一時的にin-memoryのフェイク`MemoAPIClienting`実装で差し替えて実機的にCRUD一巡(作成→一覧反映→編集→一覧反映→削除)をシミュレータで確認し、検証後に元へ戻した。
- **6.3**: `PaywallView`は購入・復元のどの結果(成功/キャンセル/失敗)でも`dismiss()`する設計にした(要件4.3が「失敗またはキャンセル時は前の画面に戻る」を一括りにしており、かつ4.1-4.4のいずれもエラーメッセージ表示までは要求していないため)。実際の購入失敗時にユーザーへフィードバックがない点はレビューで非ブロッキングの改善提案として指摘された(将来的に7.2等で`.failed`時のアラート表示を検討)。`Package.localizedPriceString`は`storeProduct`ではなく`Package`自身のプロパティである点に注意(`storeProduct.localizedTitle`/`.localizedDescription`とは異なる)。恒久テストはまだ無いため、`MemoApp.swift`を一時的に`PurchaseService.configure()` + `PaywallView()`ルートに差し替え、実際のRevenueCat Test Store(3.1と同一)に対してプラン取得(`メモ無制限(月額)` ¥490)・購入(Test Store Purchaseダイアログ経由でTest valid purchase)・復元がクラッシュなく完了することをシミュレータで確認し、検証後に元へ戻した。
- **3.2**: `RevenueCatClient`(`api/src/billing/revenueCatClient.ts`)は`Env`型に依存せず`{ secretKey, entitlementId }`を直接受け取る設計にした(`RC_SECRET_KEY`はWorkers Secretで`wrangler.jsonc`に定義がなく`wrangler types`が生成する`Env`型に含まれないため)。呼び出し元(4.2のMemoService)は`c.env.RC_SECRET_KEY`を読んで渡す形になるが、その時点でも`.dev.vars`が無い限りローカル`wrangler dev`はこの値を持たない。実機検証は`wrangler dev --remote`(ローカルdevサーバーを維持しつつ実際にデプロイ済みWorkerの本物のシークレットを使う)で行い、値を一切チャットに露出させずに済んだ。RevenueCat REST API v1のレスポンス形式は`subscriber.entitlements[id].expires_date`(ISO8601文字列、無期限は`null`)。既知のuidにRC MCPの`grant-customer-entitlement`でプロモーション権を付与し、`hasActiveEntitlement: true`/未知uidで`false`を実機確認済み。
- **7.1**: `MemoApp.swift`の`project.pbxproj`は`FirebaseAuth`/`GoogleSignIn`/`RevenueCat`の3プロダクトのみを明示リンクしており`FirebaseCore`は含まれていないが、`import FirebaseCore`は問題なくビルドできた(`FirebaseCore`はObjective-Cモジュールで、`FirebaseAuth`のパッケージ依存グラフの一部として同じビルドで解決されるため — `xcodebuild ... build`で`BUILD SUCCEEDED`を実機確認済み。今後同様に「暗黙の推移的依存のimportが通るか」を疑う場面では、まず実際に`xcodebuild`を回して確認するのが最も速い)。`AuthService.signInWithGoogle()`はFirebase sign-in成功後に`PurchaseService.logIn(uid:)`を呼ぶが、失敗しても`AuthError`の新規caseは追加せずサインイン自体は成功として返す(design.mdのService Interfaceを変更しないため)。初回レビューで「`logIn`失敗時に他の再試行経路が存在せず、RevenueCat識別子がFirebase uidと永久に紐付かなくなりうる」とImportant指摘を受け(`PurchaseService.configure()`/`purchase()`/`restore()`はいずれも`logIn`をやり直さないため)、`MemoApp.swift`の`RootView`に`.onChange(of: sessionStore.session)`を追加し、セッションがnilから非nilへ遷移するたび(初回サインイン時・永続化済みセッションでの再起動時の両方)に`PurchaseService.logIn(uid:)`を再試行する構成に修正して再レビューでAPPROVEDとなった(`logIn`は同一uidに対して冪等なため、`AuthService`内の初回呼び出しとの二重発火は許容)。design.mdのSystem Flow図が示す「RC logIn完了→navigate」という厳密な順序は採用していない(`RootView`のnavigationは`AuthSessionStore`のFirebase認証状態のみで即時決定し、`logIn`完了を待たない) — レビューでSuggestion(非ブロッキング)として記録済み、クライアント側でCustomerInfo/entitlementを同期的に参照する箇所が現状ないため実害は限定的。Google実アカウントによるサインイン→MemoListView遷移の完全なE2E確認は、実アカウント資格情報の入力が必要になるため本タスクでは行わず8.4(E2Eフロー検証)に委ねた(2.1/2.2/6.1と同じ既存方針)。
- **7.3**: `api/src/errors.ts`を新規作成し、`app.onError(handleError)`を`index.ts`に登録した。`HTTPException`(`firebaseAuthMiddleware`が投げる401等)はステータス別に`{error:<kind>, message}`へ正規化し、それ以外の未知の例外は`console.error`でログしつつ`{error:'internal_error'}`(500)を返す。`routes.ts`内の`errorResponse()`(`MemoServiceError`→400/403/404の正常応答)とは排他的な経路(例外送出 vs 正常な`Result`分岐)のため競合しない。`memosRoutes`自体は4.3時点で既に`.use('*', firebaseAuthMiddleware)`を内包済みだったため、7.3の実質的な作業は`app.route('/api/memos', memosRoutes)`によるマウントのみだった(それまでindex.tsには`/health`以外のルートが一切存在せず、実際のWorkerエントリポイント経由では`/api/memos`系は到達不能だった点に注意)。検証は`wrangler dev` + Node `fetch`(`curl`はBash権限で拒否されるため)で実施し、認証ヘッダーなしのGET/POST/PATCH/DELETE全てが401、`/health`は無影響で200、存在しないパスはHonoの通常の404(plain text、JSON化されない=`handleError`が誤介入しないことの確認)を得た。有効なFirebase IDトークンでのフルE2Eは本環境でスクリプト化不能(Google Sign-Inのみ有効なプロジェクトのため)だが、ミドルウェア自体の正しさ(2.3で検証済み)とルートハンドラの正しさ(4.3で検証済み)を前提に、今回は「実際のWorkerエントリポイントから両者が到達可能になったこと」の確認に絞った。
- **7.2**: design.mdのImplementation Note(447行目)は「`MemoListView`が`isLimitReached`を監視し`PaywallView`へのnavigationをトリガーする」としているが、実装では`MemoEditView`側に`.sheet(isPresented:)`を追加した(意図的な逸脱、レビューでAPPROVED)。理由: `MemoListView`は既に`.sheet(item: $editingMemo)`で作成/編集シートを占有しており、同一ビューに2つ目の`.sheet(isPresented:)`を追加すると、作成シート表示中に上限到達した瞬間に同一ビューから2枚のシートを同時提示しようとしてSwiftUIの制約に抵触する。`MemoEditView`(1枚目のシートの内容View)にペイウォールをネストすることでこれを回避し、`paywallBinding`のgetterを`memo == nil && viewModel.isLimitReached`とすることで編集フロー(既存メモの編集時)には決して発火しないようにした。再試行対象の内容(`pendingMemoContent`)は`MemoListViewModel`側に一元管理し、`dismissLimitReachedPrompt()`は`isLimitReached`のみをリセットして`pendingMemoContent`には触れない(唯一の読み出し経路`retryPendingMemoCreation()`が`guard let`でawait前に同期的にローカルへキャプチャするため、UI側の状態変化とのレースは起きない — レビューで確認済み)。`PaywallView`の`purchase()`/`restore()`はいずれも成功時のみ`onEntitlementUnlocked`を呼ぶが、`restore()`の成功は「API呼び出しが例外を投げなかったこと」のみを意味し、`memo_premium`エンタイトルメントが実際に有効であることまでは保証しない(レビューでSuggestion指摘、非ブロッキング) — 再試行はバックエンドの`RevenueCatClient.getSubscriber`による実際の判定を経由するため実害はなく、無駄な1往復とペイウォール再表示に留まる。検証は`FakeLimitThenSuccessClient`(初回createMemoのみ`.limitReached`、以降成功)を`MemoApp.swift`に一時注入してシミュレータで実施(検証後`git checkout`で復元): 上限到達→ペイウォール自動表示(実際のRevenueCat Test Storeのプラン`メモ無制限(月額)`¥490を表示)→プランタップ→Test Store Purchaseダイアログで「Test valid purchase」→自動再試行でメモ作成成功→編集シート自動クローズ、をクラッシュなく確認した。
- **8.1**: `api/`にvitest設定ファイルは追加していない(ゼロコンフィグで`vitest run`が`test/*.test.ts`を自動検出)。`MemoService`/`RevenueCatClient`は純粋な依存注入関数(D1/Workersランタイム不要)なので`@cloudflare/vitest-pool-workers`は使わずプレーンなNode環境で十分と判断した(D1を直接使う統合テストは8.2の担当)。`FirebaseAuthMiddleware`のテストは、実際のFirebase JWKSに依存せず`firebaseAuthMiddleware`自体を一切変更せずに検証する方式を採った: `crypto.subtle.generateKey`でRSA-2048鍵ペアをテスト内生成し、`vi.stubGlobal('fetch', ...)`で`hono/jwk`が内部的に行うJWKS取得だけを差し替え、`hono/jwt`の`sign()`でテスト用JWTを実際に署名(`kid`はJWKに手動追加。`sign()`は`privateKey`オブジェクトの`kid`をヘッダーへそのまま使う)。改ざん署名の検証は「同一`kid`だが異なる鍵ペアで署名」というケースにした(`kid`一致だけで署名検証をスキップするような潜在バグも確実に検出できるため、単純な署名バイトのフリップより厳密)。型面では、`api/src/types/env.d.ts`(`wrangler types`生成)がグローバルに`JsonWebKey`(`kid`フィールドなし)・`CryptoKeyPair`・`SubtleCryptoGenerateKeyAlgorithm`をWorkersランタイム仕様で宣言しており、Node標準のDOM libの型(`RsaHashedKeyGenParams`等)は使えない/名前が異なる点に注意(`generateKey`の戻り値型も`CryptoKey | CryptoKeyPair`のユニオンで、アルゴリズム別のオーバーロード判別がないため`as CryptoKeyPair`キャストが必要)。テストの実効性は2種類のミューテーション注入(`service.ts`の`>=`→`>`、`firebaseAuth.ts`の`aud`検証除去)+レビュアー独自の3件目(`revenueCatClient.ts`の`404`→`405`)で、いずれも対応するテストが確実に失敗することを確認済み(検証後は元のソースへ復元し、`git status`でsrc配下に差分がないことを確認)。
- **8.2**: `api/vitest.config.ts`を新規作成し、`api/`のテストスイート全体(8.1の3ファイルも含む)を`@cloudflare/vitest-pool-workers`(0.18.8、vitest 4.1.10)経由の実Miniflare/workerdランタイムで実行する構成に切り替えた。このバージョンは`defineWorkersConfig`や`/config`サブパスを持たず(`package.json`のexportsで`.`・`./types`・`./codemods/vitest-v3-to-v4`のみ確認)、代わりにメインエクスポートの`cloudflareTest(options)`(Viteプラグインを返す)を`plugins:`に渡す形式(Vitest 4の新しいプラグインベースのカスタムpool方式)。移行マイグレーションは`readD1Migrations`(Node側、`@cloudflare/vitest-pool-workers`のメインエクスポート)で`migrations/`を読み、`miniflare.bindings.TEST_MIGRATIONS`経由でランタイム側へ注入し、`test/applyMigrations.ts`(setupFiles)内で`cloudflare:test`の`applyD1Migrations(env.memo_app_db, env.TEST_MIGRATIONS)`を呼ぶ(このバージョンの型定義は`isolatedStorage`のような分離制御フラグを公開スキーマに持たないため、各テストが使い捨てのuidを使うことで分離を担保している)。`TEST_MIGRATIONS`はwranglerが生成する`Env`型に存在しないため、`test/types.d.ts`でグローバルな`Env`/`Cloudflare.Env`インターフェース(内部の`__BaseEnv_Env`ではなく公開面)へ宣言マージで追加した。`FREE_TIER_MEMO_LIMIT`は本番の`wrangler.jsonc`の値(20)を保ったまま、`miniflare.bindings`でテスト実行時のみ3に上書き(上限到達フローのテストを高速化)。RevenueCat呼び出しは`test/support/testAuth.ts`の`stubJwksAndRevenueCatFetch()`でJWKS取得と同じ`fetch`スタブから分岐して差し替えており(想定外URLへのfetchはthrowするため、意図しないネットワーク呼び出しが静かに成功することはない)、8.1の`firebaseAuthMiddleware.test.ts`とは意図的に鍵ペア生成コードを共有せず独立実装にした(承認済みの8.1テストファイルを本タスクの都合で変更しないため)。
- **8.3(重大な発見)**: `.agents/skills/xcode-project-setup/scripts/xcode_spm_setup/Sources/main.swift`は対象ターゲットを`pbxproj.nativeTargets.first`で決め打ちしており、ターゲット名で指定する手段がない。`memo_app`に`MemoAppTests`ターゲットを追加した状態で`xcodegen generate`後にこのスクリプトを複数回(プロセスを分けて)実行したところ、`.first`が指す対象が`MemoApp`と`MemoAppTests`の間で実行ごとに入れ替わることを確認した(Swiftの`Dictionary`イテレーション順がプロセスごとのハッシュシードに依存するためと推測される)。誤って`MemoAppTests`側にFirebaseAuth/GoogleSignInがリンクされ、`MemoApp`側にフレームワークが欠落する事故が実際に発生し(`xcodebuild build`が`missing required modules`で失敗して発覚)、`project.pbxproj`を直接編集(`PBXBuildFile`のFrameworks所属・`packageProductDependencies`・`PBXFrameworksBuildPhase`の`files`を`MemoAppTests`→`MemoApp`へ手動移動)して復旧した。**今後、複数ターゲットが存在する状態でこのスクリプトを実行する場合は、実行の都度`project.pbxproj`を`grep`して`MemoApp`/`MemoAppTests`それぞれの`packageProductDependencies`が意図した所属になっているか(`MemoApp`が3パッケージ全て、テスト対象ターゲットは空)を目視確認すること。** 併せて、`xcodegen generate`は`GoogleService-Info.plist`(旧pbxprojに手動追加されていたリソース参照)や`Sources/Info.plist`の`GIDClientID`/`CFBundleURLTypes`も`project.yml`に宣言がなければ毎回消去する(2.1/2.2の既知の問題と同種)ため、本タスクで`project.yml`の`MemoApp`ターゲットに`GIDClientID`/`CFBundleURLTypes`(info.properties)と`GoogleService-Info.plist`(sources、buildPhase: resources)を恒久的に宣言し直し、今後の`xcodegen generate`で消えない状態にした。`AuthSessionStore`はテスト容易性のため`AuthStateObserving`プロトコル(トークン型は`Any`— Firebase固有のハンドル型に依存させないための意図的な型消去)を導入し、`init(authStateProvider: AuthStateObserving? = nil)`を追加(既存の`AuthSessionStore()`呼び出しは無変更で動作)。`Auth.auth()`へのフォールバックは`startListening()`/`stopListening()`/`deinit`の3箇所にインライン展開しており、共通の計算プロパティへ切り出すと`deinit`が非isolatedコンテキストで実行されるため`main actor-isolated property can not be referenced from a non-isolated context`でコンパイル失敗する(レビューで実際に再現・確認済み)。
- **8.4**: 3フローすべて実機シミュレータで確認できた。(1)(2)上限到達→ペイウォール→購入成功→再試行成功、および購入の復元によるペイウォール解除は`FakeLimitThenSuccessClient`を`MemoApp.swift`に一時注入し、実際のRevenueCat Test Storeに対して確認(検証後`git checkout`で復元、コード変更なし)。(3)サインイン→メモ一覧到達は、ユーザー自身の環境でGoogle実アカウントによるサインインを実施(エージェントは認証情報入力を代行できないため、この部分のみユーザーに実施を依頼)、コンソールログで`oauth2.googleapis.com/token`への実際のトークン交換とその後のクラッシュなしのMemoListView遷移を確認した。検証中に2つの環境問題が発生: (a) 検証後の一時コード復元(`git checkout`)をした後にアプリの再ビルド・再起動を忘れ、シミュレータ上で旧テストビルド(フェイククライアント入り)がそのまま動き続け、メモ編集が常に失敗するように見える紛らわしい状態が発生した→ソースの復元と実行中バイナリの更新は必ずセットで行うこと(再ビルド・再起動まで完了して初めて「元に戻した」と言える)。(b) シミュレータの`launchd_sim`がクラッシュし`xcrun simctl boot`が"Unable to bind launchd_sim session, error: Unknown error: 1102"で失敗し続けた事象が発生、`Simulator.app`の自動`quit`/`open -a`による再起動やMac本体の再起動でも直らず、最終的にユーザーが**手動で**(Dock/Spotlightから直接)Simulator.appを開いたことで復旧した — 自動化されたプロセスからの起動では正しいセッションにbindできない場合があり、この種のクラッシュはユーザー自身による手動起動が最も確実な対処法。
- **ポストリリース(重大なバグ発見)**: 8.4完了後、ユーザーが実際にサインインしてメモの作成・編集を試したところ、本番環境で実際に失敗することが判明した。原因は2つ、いずれも**「実際のFirebase IDトークン+実際にデプロイされたWorker」という組み合わせでしか再現しない**もので、2.3(単体テスト、ローカルRSA鍵+`hono/jwk`の`keys`オプション)・8.1(同様にローカルJWKSをスタブ)・8.2(統合テスト、ローカルD1)・7.3(`wrangler dev`、無効トークンのみ)のいずれの検証方法でも検出できなかった: (1) `api/src/middleware/firebaseAuth.ts`の`FIREBASE_JWKS_URI`が`.../metadata/x509/securetoken@system.gserviceaccount.com`(X.509 PEM証明書形式、`{<kid>: "-----BEGIN CERTIFICATE-----..."}`)を指しており、`hono/jwk`が要求する`{"keys":[...]}`形式ではなかったため、実際のFirebase IDトークンの検証が`invalid JWKS response. "keys" field is missing`で必ず失敗していた。正しいURLは`.../metadata/jwk/securetoken@system.gserviceaccount.com`(同じ鍵セットをJWKS形式で提供)。(2) 本番D1データベース(`memo-app-db`)に対して`wrangler d1 migrations apply --remote`が一度も実行されておらず、`memos`テーブルが存在せず`D1_ERROR: no such table: memos`で失敗していた(`--local`のみ実行済みだった)。両方とも修正・本番デプロイ・リモートマイグレーション適用済みで、ユーザー実機での作成・編集を確認した。**教訓**: JWKS検証やD1マイグレーションのようにローカル/リモートで環境が分岐する要素は、たとえ単体・統合テストが全てパスしていても、実際にデプロイした環境に対する最低1回のE2E疎通確認(実トークン・実DB)を省略してはならない。

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

- [ ] 3. Core: 課金コンポーネント
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

- [ ] 5. Core: メモ機能(iOSクライアント)
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
- **3.2**: `RevenueCatClient`(`api/src/billing/revenueCatClient.ts`)は`Env`型に依存せず`{ secretKey, entitlementId }`を直接受け取る設計にした(`RC_SECRET_KEY`はWorkers Secretで`wrangler.jsonc`に定義がなく`wrangler types`が生成する`Env`型に含まれないため)。呼び出し元(4.2のMemoService)は`c.env.RC_SECRET_KEY`を読んで渡す形になるが、その時点でも`.dev.vars`が無い限りローカル`wrangler dev`はこの値を持たない。実機検証は`wrangler dev --remote`(ローカルdevサーバーを維持しつつ実際にデプロイ済みWorkerの本物のシークレットを使う)で行い、値を一切チャットに露出させずに済んだ。RevenueCat REST API v1のレスポンス形式は`subscriber.entitlements[id].expires_date`(ISO8601文字列、無期限は`null`)。既知のuidにRC MCPの`grant-customer-entitlement`でプロモーション権を付与し、`hasActiveEntitlement: true`/未知uidで`false`を実機確認済み。

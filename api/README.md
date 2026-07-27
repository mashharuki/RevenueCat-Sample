# memo-app-api (Cloudflare Workers + Hono)

`memo_app`(iOSクライアント)向けのバックエンドAPI。Cloudflare Workers上でHonoアプリケーションとして動作し、Firebase Authenticationで認証したユーザーのメモをD1に保存する。

## 構成リソース

| リソース | 名前 | 用途 |
|---|---|---|
| Worker | `memo-app-api` | このAPI本体(`https://memo-app-api.avp-104-106-107-a78.workers.dev`) |
| D1 Database | `memo-app-db` | メモデータ(`memos`テーブル) |
| Secret | `RC_SECRET_KEY` | RevenueCat REST APIのシークレットキー |
| 環境変数 | `FREE_TIER_MEMO_LIMIT` / `RC_ENTITLEMENT_ID` / `FIREBASE_PROJECT_ID` | `wrangler.jsonc`の`vars`で管理(非シークレット) |

## セットアップ(初回のみ)

```bash
npm install

# D1データベースの作成(初回のみ。実行結果のdatabase_idをwrangler.jsoncのd1_databasesへ反映する)
npx wrangler d1 create memo-app-db

# RevenueCatシークレットAPIキーの登録(値はプロンプトで入力。プレーンテキストでコミットしない)
npx wrangler secret put RC_SECRET_KEY

# wrangler typesが生成する型定義(手書き禁止)
npm run types
```

## ローカル開発

```bash
npm run dev              # wrangler dev (http://localhost:8787)
npm run typecheck
npm test                 # vitest (単体テスト + @cloudflare/vitest-pool-workers による統合テスト)

npm run db:migrate:local # ローカルD1にマイグレーションを適用
```

## デプロイ手順

コード変更(ルート追加、ミドルウェア変更等)は`npm run deploy`だけでは**D1のスキーマ変更を反映しない**。マイグレーションを追加した場合は、リモートDBへの適用を別途忘れずに行うこと(2026-07-27の障害はこれが未実施だったために発生した — `.kiro/specs/memo-app/tasks.md`のImplementation Notes「ポストリリース(重大なバグ発見)」参照)。

```bash
# 1. マイグレーションがある場合は先にリモートDBへ適用
npx wrangler d1 migrations apply memo-app-db --remote

# 2. Workerをデプロイ
npm run deploy            # = wrangler deploy
```

デプロイ後は最低限、認証ヘッダーなしでのアクセスが401を返すことを確認する:

```bash
curl -i https://memo-app-api.avp-104-106-107-a78.workers.dev/api/memos
```

## デストロイ(リソース削除)手順

**注意**: 以下はいずれも取り消しが困難な破壊的操作。実行前に本当に不要になったか確認すること。特にD1データベースの削除はメモデータの完全消失を意味する。

```bash
# Workerを削除(APIエンドポイント自体を停止する)
npx wrangler delete memo-app-api

# D1データベースを削除(メモデータを完全に削除する。Worker削除とは独立)
npx wrangler d1 delete memo-app-db

# シークレットのみ削除したい場合(Worker自体は残す)
npx wrangler secret delete RC_SECRET_KEY
```

D1データベースの削除前にバックアップが必要な場合は、事前にエクスポートしておく:

```bash
npx wrangler d1 export memo-app-db --remote --output memo-app-db-backup.sql
```

## テスト方針

- 単体テスト(`test/*.test.ts`): `MemoService`・`RevenueCatClient`・`FirebaseAuthMiddleware`をローカルRSA鍵/スタブ`fetch`で検証(実際のFirebase JWKSエンドポイントには依存しない)
- 統合テスト: `@cloudflare/vitest-pool-workers`経由でローカルD1に対するCRUDフローを検証

いずれも**実際にデプロイされたWorker・実際のFirebase JWKSエンドポイント・実際のリモートD1**までは検証範囲に含まれない。これらの経路特有の不具合(JWKS URLの誤り、リモートマイグレーション未適用など)は、実機での動作確認でしか発見できないことがある点に注意(詳細は`.kiro/specs/memo-app/tasks.md`のImplementation Notes参照)。

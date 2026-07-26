import { applyD1Migrations, env } from 'cloudflare:test'

/**
 * Runs once per isolated test (Miniflare snapshots storage as it exists right after setup, then
 * restores that snapshot before each test — see the D1 integration test's own comments in
 * `memos.routes.test.ts`), giving every test an empty `memos` table matching the real schema.
 */
await applyD1Migrations(env.memo_app_db, env.TEST_MIGRATIONS)

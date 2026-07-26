import path from 'node:path'
import { defineConfig } from 'vitest/config'
import { cloudflareTest, readD1Migrations } from '@cloudflare/vitest-pool-workers'

export default defineConfig(async () => {
  const migrations = await readD1Migrations(path.join(__dirname, 'migrations'))

  return {
    test: {
      setupFiles: ['./test/applyMigrations.ts'],
    },
    plugins: [
      cloudflareTest({
        wrangler: { configPath: './wrangler.jsonc' },
        miniflare: {
          bindings: {
            TEST_MIGRATIONS: migrations,
            // Keep the integration suite fast/readable — production's real limit (20) is a
            // business config value unrelated to exercising the limit-check code path itself.
            FREE_TIER_MEMO_LIMIT: 3,
            // RC_SECRET_KEY is a Workers Secret in production (not in wrangler.jsonc); tests stub
            // `fetch` for the RevenueCat call, so this placeholder never reaches a real network.
            RC_SECRET_KEY: 'test-secret',
          },
        },
      }),
    ],
  }
})

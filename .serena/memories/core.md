# RevenueCat-Sample — Core

Monorepo of practice apps for Shipaton 2026 prep (submission window 2026-08-01〜09-30). This repo's apps are learning exercises for the Flutter/Swift/RevenueCat/store-release workflow, not the Shipaton submission itself.

Sub-projects (independent, no shared build/deps):
- `memo_app/` + `api/` — fullstack practice app (SwiftUI + Firebase Auth + Cloudflare Workers + RevenueCat entitlement gating). Most mature, built via Kiro spec-driven workflow. See `mem:memo-app`.
- `my_first_game/` (Flutter, "Neon Invaders") and `my_first_swift_project/` (Swift SpriteKit+SwiftUI, "BreakoutGame") — RevenueCat SDK integration practice, both wired to the same RevenueCat dashboard project. See `mem:practice-games`.
- `my-first-react-native/` — unmodified Expo (`create-expo-app`) boilerplate, no RevenueCat/feature work started yet.
- `docs/ios-setup.md` — generic real-device signing + Apple Developer Program ($99/yr) + Sandbox IAP testing guide. Written against `my_first_game` but every Swift/Flutter subproject's README points here for the signing steps (reused as-is).

Dev workflow: Kiro-style spec-driven development — `.kiro/steering/` (project-wide policy), `.kiro/specs/<feature>/` (requirements.md → design.md → tasks.md, gated by approvals in spec.json). `memo-app` is the only spec built so far.

Repo also ships a large number of installed Claude Code / Codex skills and subagents (`.claude/`, `.agents/`, `.codex/`) for RevenueCat, Expo, Flutter, PM deliverables, etc. — these are tooling, not application code.

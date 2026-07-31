# Practice games — my_first_game / my_first_swift_project

Both are RevenueCat SDK integration practice apps sharing one RevenueCat dashboard project (separate from `mem:memo-app`'s setup):
- RevenueCat project `UNCHAIN` (project_id `proj4118d796`), Test Store app `app88c7d2a3c7`, reused by agreement rather than creating a new project.
- 3 products/entitlements shared by both apps' paywalls:
  - `unlock_all_content` (non-consumable, ¥980) → entitlement `premium` (Flutter: wave cap gate; Swift: BrickLayout level cap gate)
  - `continue_token` (consumable, ¥120) → no entitlement, tracked via local counter
  - `weekly_challenge` (weekly subscription, ¥300) → entitlement `weekly_challenge`
  - Offering `default` packages: `$rc_custom_unlock_all` / `$rc_custom_continue_token` / `$rc_weekly`
- `my_first_game`: Flutter, "Neon Invaders" vertical shooter (`lib/app/invader_app.dart`). Targets iOS+Android; RevenueCat calls are guarded to iOS/Android only (Web/macOS/Linux/Windows build for dev convenience only, no purchases).
- `my_first_swift_project`: Swift SpriteKit+SwiftUI, "BreakoutGame". Xcode project generated via XcodeGen (`project.yml`) — same regenerate-after-Sources-changes caveat as `memo_app` (see `mem:memo-app`).
- Both READMEs point to `docs/ios-setup.md` for real-device signing / Apple Developer Program / Sandbox IAP testing.
- `my-first-react-native` has no RevenueCat work yet — still unmodified `create-expo-app` boilerplate, not part of this practice pairing.

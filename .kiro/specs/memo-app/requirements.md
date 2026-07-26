# Requirements Document

## Project Description (Input)

**誰が困っているか**: このリポジトリの開発者(Shipaton参加に向けて練習中)。既存の `my_first_swift_project`(SwiftUI + SpriteKit、RevenueCatのみ）と `my_first_game`(Flutter + Flame、RevenueCatのみ）の2つでは、認証・自前バックエンドAPI・課金を組み合わせた「フルスタックアプリケーション」の実装パターンをまだ一度も practice できていない。

**現状**: RevenueCat単体の組み込みは2パターンとも経験済みだが、Firebase Authによるユーザー認証、Cloudflare Workers + Hono による自前APIサーバー、その3つ(認証・自前API・課金)を1つのアプリで連携させる構成は未経験。

**何を変えるか**: Swift(iOS)クライアント + Cloudflare Workers(Hono)API + Firebase Authentication + RevenueCat SDK を組み合わせた、認証機能付き・課金機能付きのフルスタックメモ帳アプリを新規に実装し、この未経験パターンを埋める。

## 確認済みの前提条件(ユーザーヒアリング結果)

- **目的**: Shipaton向けの実践練習が主目的。完成度よりも「認証 + 課金 + 自前バックエンドAPI」パターンの習得を優先する。
- **配置場所**: リポジトリ直下に新しいトップレベルフォルダ(例: `memo_app/`)を作成する。既存の `my_first_swift_project` / `my_first_game` と同じ並びに置く。バックエンドAPI(`api/`)も別途トップレベルに作る想定(既存の合意事項)。
- **技術スタック**:
  - クライアント: Swift(iOS ネイティブ、SwiftUIを想定)
  - バックエンド: Cloudflare Workers + Hono(TypeScript)
  - 認証: Firebase Authentication
  - 課金: RevenueCat SDK(iOS)
- **課金ゲートの対象機能**: メモの件数上限。無料プランは一定件数まで、課金プランで無制限にする(具体的な件数は要件定義フェーズで確定)。
- **サポートするサインイン方法**: Googleサインインのみ(現時点の合意)。
  - 補足: iOSアプリでGoogleサインインなどサードパーティのソーシャルログインを提供する場合、Appleの審査ガイドライン(4.8)により「Sign in with Apple」の並行提供が実質的に必須となるケースが多い。本番でのApp Store提出を見据える場合はこの点を要件定義フェーズで再確認する。

## Introduction

本仕様は、ユーザー認証・メモの管理・サブスクリプション課金を組み合わせたメモ帳アプリケーションの要件を定義する。これまでの練習用アプリでは経験していなかった「認証されたユーザーが自分のデータのみを操作でき、無料利用には制限があり、課金によってその制限が解除される」という一連の振る舞いを、フルスタック構成で実現することが目的である。

## Boundary Context (Optional)

- **In scope**: Googleアカウントによるサインイン/サインアウト、メモの作成・閲覧・編集・削除、無料プランのメモ件数上限、サブスクリプションの購入・復元、購入状態に応じた機能解放、他人のメモへのアクセス制御。
- **Out of scope（現時点の前提。要修正であれば指摘してください）**:
  - Google以外のサインイン方法(Sign in with Apple、メール/パスワード等)は本イテレーションでは扱わない。
  - オフライン時のローカルキャッシュ・オフライン編集は扱わない(ネットワーク接続時のみ動作する前提)。
  - 複数端末間のリアルタイム共同編集は扱わない。
  - メモの他ユーザーへの共有・公開機能は扱わない。
  - 画像・添付ファイル等のリッチコンテンツは扱わない(テキストメモのみ)。
- **Adjacent expectations**:
  - 本機能は外部の認証プロバイダに依存し、サインイン成功時に安定したユーザー識別子が得られることを前提とする。認証プロバイダ自体の内部実装はこの仕様の対象外。
  - 本機能は外部の課金/サブスクリプション基盤に依存し、購入・復元・失効の結果としてエンタイトルメント(利用権限)の状態を問い合わせられることを前提とする。課金基盤自体の内部実装(決済処理等)はこの仕様の対象外。
  - 本番でのApp Store提出を見据える場合、Sign in with Appleの追加提供が必要になる可能性がある(要再検討)。

## Requirements

### Requirement 1: ユーザー認証(サインイン/サインアウト)

**Objective:** As an app user, I want to sign in with my Google account, so that my memos are securely tied to my identity across sessions.

#### Acceptance Criteria
1. When an unauthenticated user opens the app, the Memo App shall present a sign-in screen offering Google sign-in.
2. When a user completes Google sign-in successfully, the Memo App shall establish an authenticated session and navigate to the memo list.
3. If Google sign-in fails or is cancelled, then the Memo App shall display an error message and remain on the sign-in screen.
4. While a user is authenticated, the Memo App shall persist the session across app restarts until the user signs out or the session becomes invalid.
5. When an authenticated user selects sign out, the Memo App shall end the session and return to the sign-in screen.
6. The Memo App shall prevent unauthenticated access to any user's memo data.

### Requirement 2: メモの作成・閲覧・編集・削除

**Objective:** As a signed-in user, I want to create, view, edit, and delete my memos, so that I can capture and manage notes over time.

#### Acceptance Criteria
1. When an authenticated user creates a new memo with non-empty content, the Memo Service shall save the memo and associate it with that user's account.
2. When an authenticated user opens the memo list, the Memo Service shall display only memos belonging to that user, ordered by most recently updated.
3. When an authenticated user edits an existing memo, the Memo Service shall save the updated content and update its last-modified time.
4. When an authenticated user deletes a memo, the Memo Service shall remove it from that user's memo list.
5. If a user attempts to create a memo with empty content, then the Memo Service shall reject the save and display a validation message.
6. If a user attempts to access, edit, or delete a memo that does not belong to them, then the Memo Service shall deny the operation.

### Requirement 3: 無料プランのメモ件数上限

**Objective:** As a product owner, I want free-tier users to be limited to a defined number of memos, so that upgrading to a paid subscription provides a clear, tangible benefit.

#### Acceptance Criteria
1. While a user does not have an active subscription, the Memo Service shall allow the user to store up to a defined maximum number of memos (default assumption: 20; subject to confirmation).
2. If a user without an active subscription attempts to create a memo beyond the maximum, then the Memo App shall block the creation and present an upgrade prompt.
3. When a user's subscription becomes active, the Memo Service shall remove the memo count restriction for that user.
4. Where the maximum memo count is configurable, the Memo App shall apply the currently configured value consistently across all free-tier accounts.

### Requirement 4: サブスクリプションの購入・復元

**Objective:** As a free-tier user, I want to view and purchase a subscription plan, so that I can remove the memo limit.

#### Acceptance Criteria
1. When a user views the upgrade screen, the Memo App shall display the available subscription plan(s) with price and benefit description.
2. When a user completes a purchase successfully, the Memo App shall unlock unlimited memo creation without requiring an app restart.
3. If a purchase fails or is cancelled by the user, then the Memo App shall return to the previous screen without changing the user's entitlement.
4. When a user selects "restore purchases," the Memo App shall re-check their subscription status and unlock the corresponding entitlement if a valid subscription exists.
5. While a subscription is active, the Memo App shall reflect the unlocked (unlimited) state on every screen that shows the memo count limit.
6. If a subscription expires or is cancelled, then the Memo Service shall re-apply the free-tier memo limit on the next access, without deleting memos that were created while the subscription was active.

### Requirement 5: データの保護と可用性

**Objective:** As a user, I want my memos to be reliably saved and accessible only to me, so that I can trust the app with my notes.

#### Acceptance Criteria
1. The Memo Service shall ensure that memo data is only readable and writable by the authenticated owner of that data.
2. If network connectivity is unavailable when the user attempts to save a change, then the Memo App shall inform the user that the change could not be saved rather than failing silently.
3. The Memo Service shall persist memo data durably such that a saved memo remains available across devices and sessions.

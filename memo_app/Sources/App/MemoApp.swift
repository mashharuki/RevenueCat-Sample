import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import RevenueCat
import SwiftUI

@main
struct MemoApp: App {
  @StateObject private var sessionStore = AuthSessionStore()

  init() {
    FirebaseApp.configure()
    PurchaseService.configure()
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(sessionStore)
        .onAppear {
          sessionStore.startListening()
        }
    }
  }
}

/// Switches between `SignInView` and `MemoListView` based on `AuthSessionStore`'s current
/// session, so the memo list is reachable only while authenticated (Requirements 1.2, 1.4, 1.6).
///
/// Also retries `PurchaseService.logIn(uid:)` whenever a session appears. `AuthService` already
/// calls `logIn` right after a successful sign-in, but that call has no dedicated `AuthError` case
/// and nothing else in the app re-attempts it — without this, a transient `logIn` failure would
/// permanently leave RevenueCat's identifier out of sync with the Firebase uid (design.md
/// AuthService Postcondition), since RevenueCat's own `configure()`/`purchase()`/`restore()` calls
/// do not re-run `logIn`. `logIn` is idempotent for an already-identified uid, so retrying here on
/// every session observation (fresh sign-in or a restored session on relaunch) is safe.
@MainActor
private struct RootView: View {
  @EnvironmentObject private var sessionStore: AuthSessionStore

  var body: some View {
    Group {
      if sessionStore.session != nil {
        MemoListView()
      } else {
        SignInView()
      }
    }
    .onChange(of: sessionStore.session) { _, newSession in
      guard let newSession else { return }
      Task {
        do {
          try await PurchaseService.logIn(uid: newSession.uid)
        } catch {
          print("PurchaseService.logIn retry failed: \(error)")
        }
      }
    }
  }
}

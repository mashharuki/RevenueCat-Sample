import FirebaseAuth
import Foundation

struct AuthenticatedSession: Equatable {
  let uid: String
  let displayName: String?
}

/// Abstracts Firebase Auth's state-change listener registration so `AuthSessionStore` is testable
/// without a real Firebase project (Requirement 1.4 unit tests, task 8.3). The token type is
/// intentionally opaque (`Any`, wrapping whatever `Auth.addStateDidChangeListener` returns) so a
/// test double can hand back any placeholder value without depending on FirebaseAuth's own handle
/// type.
protocol AuthStateObserving {
  func observeAuthState(_ listener: @escaping (AuthenticatedSession?) -> Void) -> Any
  func removeAuthStateObserver(_ token: Any)
}

extension Auth: AuthStateObserving {
  func observeAuthState(_ listener: @escaping (AuthenticatedSession?) -> Void) -> Any {
    addStateDidChangeListener { _, user in
      listener(user.map { AuthenticatedSession(uid: $0.uid, displayName: $0.displayName) })
    }
  }

  func removeAuthStateObserver(_ token: Any) {
    guard let handle = token as? AuthStateDidChangeListenerHandle else { return }
    removeStateDidChangeListener(handle)
  }
}

/// Mirrors FirebaseAuth's current sign-in state. `startListening()` must only be called after
/// `FirebaseApp.configure()` has completed (see firebase-auth-basics/references/ios_setup.md) —
/// this type never touches `Auth.auth()` at init time to avoid that crash. `authStateProvider`
/// defaults to `nil` and is resolved to `Auth.auth()` lazily inside `startListening()`/
/// `stopListening()`/`deinit` (never in `init`) to preserve that guarantee; tests inject a fake
/// provider instead.
@MainActor
final class AuthSessionStore: ObservableObject {
  @Published private(set) var session: AuthenticatedSession?

  private let authStateProvider: AuthStateObserving?
  private var authStateHandle: Any?

  init(authStateProvider: AuthStateObserving? = nil) {
    self.authStateProvider = authStateProvider
  }

  func startListening() {
    guard authStateHandle == nil else { return }
    authStateHandle = (authStateProvider ?? Auth.auth()).observeAuthState { [weak self] session in
      self?.session = session
    }
  }

  func stopListening() {
    guard let authStateHandle else { return }
    (authStateProvider ?? Auth.auth()).removeAuthStateObserver(authStateHandle)
    self.authStateHandle = nil
  }

  deinit {
    // Reads only stored properties and calls a plain (non-isolated) static factory + protocol
    // method on their result — `deinit` itself runs non-isolated, so it must not call any
    // MainActor-isolated member declared on `self` (e.g. a computed property or method).
    if let authStateHandle {
      (authStateProvider ?? Auth.auth()).removeAuthStateObserver(authStateHandle)
    }
  }
}

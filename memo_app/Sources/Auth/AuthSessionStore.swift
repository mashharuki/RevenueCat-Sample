import FirebaseAuth
import Foundation

struct AuthenticatedSession: Equatable {
  let uid: String
  let displayName: String?
}

/// Mirrors FirebaseAuth's current sign-in state. `startListening()` must only be called after
/// `FirebaseApp.configure()` has completed (see firebase-auth-basics/references/ios_setup.md) —
/// this type never touches `Auth.auth()` at init time to avoid that crash.
@MainActor
final class AuthSessionStore: ObservableObject {
  @Published private(set) var session: AuthenticatedSession?

  private var authStateHandle: AuthStateDidChangeListenerHandle?

  func startListening() {
    guard authStateHandle == nil else { return }
    authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.session = user.map { AuthenticatedSession(uid: $0.uid, displayName: $0.displayName) }
    }
  }

  func stopListening() {
    guard let authStateHandle else { return }
    Auth.auth().removeStateDidChangeListener(authStateHandle)
    self.authStateHandle = nil
  }

  deinit {
    if let authStateHandle {
      Auth.auth().removeStateDidChangeListener(authStateHandle)
    }
  }
}

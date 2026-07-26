@testable import MemoApp

/// In-memory `AuthStateObserving` test double — lets tests simulate Firebase Auth's state-change
/// listener firing (sign-in/sign-out) without a real Firebase project or network access.
final class FakeAuthStateObserving: AuthStateObserving {
  private var listener: ((AuthenticatedSession?) -> Void)?
  private(set) var observeCallCount = 0
  private(set) var removeCallCount = 0

  func observeAuthState(_ listener: @escaping (AuthenticatedSession?) -> Void) -> Any {
    observeCallCount += 1
    self.listener = listener
    return "fake-auth-state-token"
  }

  func removeAuthStateObserver(_ token: Any) {
    removeCallCount += 1
    listener = nil
  }

  /// Simulates Firebase Auth's listener firing with a new state (a session for sign-in, `nil` for
  /// sign-out). No-ops if nothing is currently observing (mirrors the real SDK never calling a
  /// removed listener).
  func emit(_ session: AuthenticatedSession?) {
    listener?(session)
  }
}

import FirebaseAuth
import GoogleSignIn
import UIKit

protocol AuthServicing {
  func signInWithGoogle() async -> Result<AuthenticatedUser, AuthError>
  func signOut() throws
}

struct AuthenticatedUser {
  let uid: String
  let displayName: String?
}

enum AuthError: Error {
  case cancelled
  case presentationFailed
  case firebaseSignInFailed(underlying: Error)
}

private struct MissingIDTokenError: Error {}

/// Google Sign-In -> Firebase credential exchange. After a successful Firebase
/// sign-in, ties the RevenueCat subscriber identity to the Firebase uid via
/// `PurchaseService.logIn(uid:)` (design.md AuthService Responsibilities;
/// `research.md` Decision) so the backend and RevenueCat agree on the same
/// identifier. A `logIn` failure does not fail the sign-in itself — there is
/// no dedicated `AuthError` case for it. `MemoApp`'s root view retries
/// `logIn` whenever `AuthSessionStore` observes a session (including this
/// same sign-in), so a transient failure here is not the only chance to
/// establish the identifier — see `RootView` in `MemoApp.swift`.
@MainActor
final class AuthService: AuthServicing {
  func signInWithGoogle() async -> Result<AuthenticatedUser, AuthError> {
    guard let presentingViewController = Self.topViewController() else {
      return .failure(.presentationFailed)
    }

    let signInResult: GIDSignInResult
    do {
      signInResult = try await withCheckedThrowingContinuation { continuation in
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
          if let error {
            continuation.resume(throwing: error)
            return
          }
          guard let result else {
            continuation.resume(throwing: MissingIDTokenError())
            return
          }
          continuation.resume(returning: result)
        }
      }
    } catch let signInError as GIDSignInError where signInError.code == .canceled {
      return .failure(.cancelled)
    } catch {
      return .failure(.firebaseSignInFailed(underlying: error))
    }

    guard let idToken = signInResult.user.idToken?.tokenString else {
      return .failure(.firebaseSignInFailed(underlying: MissingIDTokenError()))
    }

    let credential = GoogleAuthProvider.credential(
      withIDToken: idToken,
      accessToken: signInResult.user.accessToken.tokenString
    )

    do {
      let authResult = try await Auth.auth().signIn(with: credential)
      do {
        try await PurchaseService.logIn(uid: authResult.user.uid)
      } catch {
        print("PurchaseService.logIn failed after sign-in: \(error)")
      }
      return .success(AuthenticatedUser(uid: authResult.user.uid, displayName: authResult.user.displayName))
    } catch {
      return .failure(.firebaseSignInFailed(underlying: error))
    }
  }

  func signOut() throws {
    try Auth.auth().signOut()
  }

  private static func topViewController() -> UIViewController? {
    guard
      let scene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
      let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
    else {
      return nil
    }

    var top = root
    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }
}

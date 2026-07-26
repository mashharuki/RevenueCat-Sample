import SwiftUI

/// Presentational only: attempts Google sign-in and surfaces failure/cancellation as an error
/// message, remaining on this screen either way (Requirement 1.1, 1.3). The transition to the
/// memo list on success is driven by `AuthSessionStore` observing Firebase's auth state change —
/// this view does not navigate itself; root navigation is wired by the app's integration task.
@MainActor
struct SignInView: View {
  private let authService: AuthServicing

  @State private var isSigningIn = false
  @State private var errorMessage: String?

  init(authService: AuthServicing? = nil) {
    self.authService = authService ?? AuthService()
  }

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Text("Memo App")
        .font(.largeTitle)
        .bold()

      Button(action: signIn) {
        HStack {
          if isSigningIn {
            ProgressView()
          } else {
            Text("Googleでサインイン")
          }
        }
        .frame(maxWidth: .infinity)
        .padding()
      }
      .buttonStyle(.borderedProminent)
      .disabled(isSigningIn)
      .padding(.horizontal, 32)

      if let errorMessage {
        Text(errorMessage)
          .foregroundStyle(.red)
          .font(.footnote)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 32)
      }

      Spacer()
    }
  }

  private func signIn() {
    guard !isSigningIn else { return }
    isSigningIn = true
    errorMessage = nil

    Task {
      let result = await authService.signInWithGoogle()
      isSigningIn = false
      switch result {
      case .success:
        break
      case .failure(.cancelled):
        errorMessage = "サインインがキャンセルされました。"
      case .failure(.presentationFailed):
        errorMessage = "サインイン画面を表示できませんでした。もう一度お試しください。"
      case .failure(.firebaseSignInFailed):
        errorMessage = "サインインに失敗しました。もう一度お試しください。"
      }
    }
  }
}

#Preview {
  SignInView()
}

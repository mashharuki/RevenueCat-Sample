import SwiftUI

/// Placeholder screen unlocked by the `weekly_challenge` subscription
/// entitlement. Demonstrates gating a whole screen behind an active
/// RevenueCat subscription rather than a single feature toggle.
struct WeeklyChallengeView: View {
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("WEEKLY CHALLENGE")
                .font(.title.bold())
                .foregroundColor(.purple)
            Text("今週のお題: レベル3をノーミスでクリアせよ")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: onBack) {
                Text("HOME")
                    .font(.title3.bold())
                    .padding()
                    .frame(maxWidth: 220)
            }
            .overlay(Capsule().stroke(Color.white.opacity(0.4)))
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

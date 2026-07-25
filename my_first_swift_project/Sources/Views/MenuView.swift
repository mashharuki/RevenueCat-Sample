import SwiftUI

struct MenuView: View {
    @ObservedObject var viewModel: GameViewModel
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Breakout")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Button(action: onStart) {
                Text("Tap to Start")
                    .font(.title2.bold())
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
            }
            Button(action: { viewModel.showPaywall() }) {
                Text("⭐ Upgrade")
                    .font(.title3.bold())
                    .padding()
                    .frame(maxWidth: 220)
            }
            .overlay(Capsule().stroke(Color.white.opacity(0.5)))
            .foregroundColor(.white)
            Button(action: { viewModel.showWeeklyChallenge() }) {
                Text(viewModel.hasWeeklyChallenge ? "🗓 Weekly Challenge" : "🔒 Weekly Challenge")
                    .font(.title3.bold())
                    .padding()
                    .frame(maxWidth: 220)
            }
            .overlay(Capsule().stroke(Color.white.opacity(0.5)))
            .foregroundColor(.white)
        }
    }
}

import SwiftUI

struct GameOverView: View {
  @ObservedObject var viewModel: GameViewModel
  let onPlayAgain: () -> Void

  private var title: String {
    viewModel.state == .win ? "You Win!" : "Game Over"
  }

  var body: some View {
    VStack(spacing: 24) {
      Text(title)
        .font(.largeTitle.bold())
        .foregroundColor(.white)
      Text("Score: \(viewModel.score)")
        .font(.title2)
        .foregroundColor(.white)

      if viewModel.state == .gameOver {
        if viewModel.continueTokens > 0 {
          Button(action: viewModel.continueGame) {
            Text("▶ CONTINUE (残り\(viewModel.continueTokens)個)")
              .font(.title3.bold())
              .padding()
              .frame(maxWidth: 260)
              .background(Color.cyan)
              .foregroundColor(.black)
              .clipShape(Capsule())
          }
        } else {
          Button(action: {
            viewModel.showPaywall(
              banner: "コンティニュートークンを購入すると続きからプレイできます",
              returnTo: .gameOver
            )
          }) {
            Text("🪙 コンティニュートークンを購入")
              .font(.subheadline.bold())
              .padding()
              .frame(maxWidth: 260)
          }
          .overlay(Capsule().stroke(Color.white.opacity(0.5)))
          .foregroundColor(.white)
        }
      }

      Button(action: onPlayAgain) {
        Text("Play Again")
          .font(.title2.bold())
          .padding()
          .background(Color.white)
          .foregroundColor(.black)
          .clipShape(Capsule())
      }
    }
  }
}

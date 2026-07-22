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

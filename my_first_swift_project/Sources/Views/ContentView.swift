import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var viewModel: GameViewModel
    @State private var scene: GameScene

    init() {
        let viewModel = GameViewModel()
        let scene = GameScene(size: UIScreen.main.bounds.size, viewModel: viewModel)
        scene.scaleMode = .resizeFill
        _viewModel = StateObject(wrappedValue: viewModel)
        _scene = State(wrappedValue: scene)
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()

            if viewModel.state == .playing {
                HUDOverlay(viewModel: viewModel)
            }

            switch viewModel.state {
            case .menu:
                MenuView { startGame() }
            case .gameOver, .win:
                GameOverView(viewModel: viewModel) { startGame() }
            case .playing:
                EmptyView()
            }
        }
    }

    private func startGame() {
        viewModel.resetForNewGame()
        scene.resetGame()
    }
}

private struct HUDOverlay: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack {
            HStack {
                Text("Score: \(viewModel.score)")
                Spacer()
                Text("Lives: \(viewModel.lives)")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            Spacer()
        }
    }
}

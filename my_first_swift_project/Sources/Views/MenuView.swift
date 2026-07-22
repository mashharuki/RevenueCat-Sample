import SwiftUI

struct MenuView: View {
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
        }
    }
}

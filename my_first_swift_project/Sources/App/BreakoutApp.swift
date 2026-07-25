import SwiftUI

@main
struct BreakoutApp: App {
    init() {
        PurchaseService.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

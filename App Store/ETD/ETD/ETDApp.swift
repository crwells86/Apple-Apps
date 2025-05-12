import SwiftUI

@main
struct ETDApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [LifeModel.self, Goal.self])
    }
}

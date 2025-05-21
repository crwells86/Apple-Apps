import SwiftUI
import SwiftData

@main
struct Chore_ChartApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [ChoreTemplate.self])
        }
    }
}

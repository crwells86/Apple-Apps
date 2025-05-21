import SwiftUI
import SwiftData

@main
struct Simpler_Budget_Bill_OrganizerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Transaction.self])
        }
    }
}

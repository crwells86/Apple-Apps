import SwiftUI
import SwiftData

@main
struct Would_You_RatherApp: App {
    @State private var subscriptionController = SubscriptionController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Deck.self, Question.self])
        .environment(subscriptionController)
    }
}

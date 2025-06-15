import SwiftUI
import StoreKit
import SwiftData

@main
struct Everyday_Mood_TrackerApp: App {
    @State private var subscriptionController = SubscriptionController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [MoodEntry.self, MoodGoal.self])
                .environment(subscriptionController)
                .task {
                    await subscriptionController.sync()
                }
        }
    }
}

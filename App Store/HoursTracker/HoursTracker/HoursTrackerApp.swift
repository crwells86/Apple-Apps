import SwiftUI
import SwiftData

@main
struct HoursTrackerApp: App {
    @State private var subscriptionController = SubscriptionController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Job.self, WorkShift.self])
        .environment(subscriptionController)
    }
}

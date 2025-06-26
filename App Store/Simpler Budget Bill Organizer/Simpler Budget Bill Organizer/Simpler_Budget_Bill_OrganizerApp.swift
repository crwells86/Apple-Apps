import SwiftUI
import SwiftData

@main
struct Simpler_Budget_Bill_OrganizerApp: App {
    @State private var subscriptionController = SubscriptionController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Transaction.self, Expense.self, Income.self])
                .environment(subscriptionController)
        }
    }
}

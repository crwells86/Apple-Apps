import SwiftUI
import SwiftData

@main
struct Budget_App_AIApp: App {
    @State private var subController = SubscriptionController()
    
    var body: some Scene {
        WindowGroup {
            ExpenseTrackerView()
                .modelContainer(for: Expense.self)
                .environment(subController)
        }
    }
}

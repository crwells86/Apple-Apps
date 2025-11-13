import SwiftUI
import SwiftData

@main
struct HealthHabitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentViewWithOnboarding()
        }
        .modelContainer(for: [Goal.self, DailyGoalData.self])
    }
}

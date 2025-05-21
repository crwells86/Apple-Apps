import SwiftUI
import SwiftData

@main
struct Medication_TrackerApp: App {
    var body: some Scene {
        WindowGroup {
            MedicationListView()
                .modelContainer(for: [Medication.self])

        }
    }
}

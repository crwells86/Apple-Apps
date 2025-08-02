import Foundation

struct MonthlyEarnings: Identifiable {
    let id = UUID()
    let month: String
    let monthDate: Date
    let weeks: [WeeklyEarning]
}

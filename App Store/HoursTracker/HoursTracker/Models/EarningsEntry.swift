import Foundation

struct EarningsEntry: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
}

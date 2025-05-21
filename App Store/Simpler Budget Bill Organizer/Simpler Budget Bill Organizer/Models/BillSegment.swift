import Foundation

struct BillSegment: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

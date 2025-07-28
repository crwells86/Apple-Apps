import Foundation

struct CategorySpending: Identifiable {
    var id: UUID
    var name: String
    var icon: String
    var total: Decimal
    
    static func == (lhs: CategorySpending, rhs: CategorySpending) -> Bool {
        lhs.id == rhs.id
    }
}

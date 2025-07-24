import Foundation
import SwiftData

@Model class Category {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var icon: String
    var limit: Decimal?
    var isDefault: Bool = false
    var enableReminders: Bool = false
    
    // Reverse relationships (not stored directly)
    @Relationship(deleteRule: .cascade, inverse: \Expense.category)
    var expenses: [Expense] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.category)
    var transactions: [Transaction] = []
    
    init(name: String, icon: String, limit: Decimal? = nil, isDefault: Bool = false) {
        self.name = name
        self.icon = icon
        self.limit = limit
        self.isDefault = isDefault
    }
}

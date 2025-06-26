import Foundation
import SwiftData

@Model class Expense {
    @Attribute(.unique) var id: UUID = UUID()
    var amount: Decimal
    var vendor: String
    var date: Date
    var categoryRaw: String
    var isActive: Bool = true

    /// Computed enum wrapper around raw storage
    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .miscellaneous }
        set { categoryRaw = newValue.rawValue }
    }

    init(amount: Decimal,
         vendor: String,
         date: Date = .now,
         category: ExpenseCategory = .miscellaneous) {
        self.amount = amount
        self.vendor = vendor
        self.date = date
        self.categoryRaw = category.rawValue
    }
}

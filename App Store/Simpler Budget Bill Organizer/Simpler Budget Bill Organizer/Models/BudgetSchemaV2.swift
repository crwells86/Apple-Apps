import Foundation
import SwiftData

enum BudgetSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            Category.self,
            Expense.self,
            Transaction.self
        ]
    }
}

extension BudgetSchemaV2 {
    @Model
    class Expense {
        @Attribute(.unique) var id: UUID = UUID()
        var amount: Decimal
        var vendor: String
        var date: Date
        var isActive: Bool = true
        
        @Relationship var category: Category?
        
        init(amount: Decimal,
             vendor: String,
             date: Date = .now,
             category: Category? = nil) {
            self.amount = amount
            self.vendor = vendor
            self.date = date
            self.category = category
        }
    }
    
    @Model
    class Transaction: Identifiable {
        var id = UUID()
        var name: String
        var amount: Double
        var frequencyRaw: String
        var dueDate: Date?
        var isAutoPaid: Bool
        var isPaid: Bool
        var notes: String
        var startDate: Date?
        var endDate: Date?
        var vendor: String
        var isActive: Bool
        var currencyCode: String
        var remindMe: Bool
        var remindDay: Int?
        var remindHour: Int?
        var remindMinute: Int?
        
        @Relationship var category: Category?
        
        init(
            name: String = "",
            amount: Double = 0,
            frequency: BillFrequency = .monthly,
            category: Category? = nil,
            dueDate: Date? = nil,
            isAutoPaid: Bool = false,
            isPaid: Bool = false,
            notes: String = "",
            startDate: Date? = nil,
            endDate: Date? = nil,
            vendor: String = "",
            isActive: Bool = true,
            currencyCode: String = "USD",
            remindMe: Bool = false,
            remindDay: Int? = nil,
            remindHour: Int? = nil,
            remindMinute: Int? = nil
        ) {
            self.name = name
            self.amount = amount
            self.frequencyRaw = frequency.rawValue
            self.category = category
            self.dueDate = dueDate
            self.isAutoPaid = isAutoPaid
            self.isPaid = isPaid
            self.notes = notes
            self.startDate = startDate
            self.endDate = endDate
            self.vendor = vendor
            self.isActive = isActive
            self.currencyCode = currencyCode
            self.remindMe = remindMe
            self.remindDay = remindDay
            self.remindHour = remindHour
            self.remindMinute = remindMinute
        }
    }
}

import Foundation
import SwiftData

@Model class Transaction: Identifiable {
    var id = UUID()
    var name: String
    var amount: Double
    var frequencyRaw: String
    var categoryRaw: String
    var dueDate: Date?
    var isAutoPaid: Bool
    var isPaid: Bool
    var notes: String
    var startDate: Date?
    var endDate: Date?
    var vendor: String
    var isActive: Bool
    var tags: [String]
    var currencyCode: String
    var remindMe: Bool
    var remindDay: Int?
    var remindHour: Int?
    var remindMinute: Int?
    
    init(
        name: String = "",
        amount: Double = 0,
        frequency: BillFrequency = .monthly,
        category: ExpenseCategory = .miscellaneous,
        dueDate: Date? = nil,
        isAutoPaid: Bool = false,
        isPaid: Bool = false,
        notes: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil,
        vendor: String = "",
        isActive: Bool = true,
        tags: [String] = [],
        currencyCode: String = "USD",
        remindMe: Bool = false,
        remindDay: Int? = nil,
        remindHour: Int? = nil,
        remindMinute: Int? = nil
    ) {
        self.name = name
        self.amount = amount
        self.frequencyRaw = frequency.rawValue
        self.categoryRaw = category.rawValue
        self.dueDate = dueDate
        self.isAutoPaid = isAutoPaid
        self.isPaid = isPaid
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.vendor = vendor
        self.isActive = isActive
        self.tags = tags
        self.currencyCode = currencyCode
        self.remindMe = remindMe
        self.remindDay = remindDay
        self.remindHour = remindHour
        self.remindMinute = remindMinute
    }
}

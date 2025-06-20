import Foundation
import SwiftData

@Model class Expense: Identifiable {
    var id: UUID = UUID()
    var amount: Decimal
    var vendor: String
    var date: Date
    
    init(amount: Decimal, vendor: String, date: Date = .now) {
        self.amount = amount
        self.vendor = vendor
        self.date = date
    }
}

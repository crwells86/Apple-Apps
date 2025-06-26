import SwiftData
import Foundation

@Model class Income: Identifiable {
    var id: UUID
    var source: String
    var amount: Decimal
    var date: Date
    var frequencyRaw: String
    var reminderEnabled: Bool
    
    init(
        source: String,
        amount: Decimal,
        date: Date,
        frequency: Frequency = .variable,
        reminderEnabled: Bool = false
    ) {
        self.id = UUID()
        self.source = source
        self.amount = amount
        self.date = date
        self.frequencyRaw = frequency.rawValue
        self.reminderEnabled = reminderEnabled
    }
}

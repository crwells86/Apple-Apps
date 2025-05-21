import Foundation

extension Transaction {
    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .miscellaneous }
        set { categoryRaw = newValue.rawValue }
    }
    
    var frequency: BillFrequency {
        get {
            BillFrequency(rawValue: frequencyRaw) ?? .monthly
        }
        set {
            frequencyRaw = newValue.rawValue
        }
    }
}

//MRK: - Sample data for #Preview's
extension Transaction {
    static func sample(dueInDays: Int, isPaid: Bool = false) -> Transaction {
        Transaction(
            name: "Power",
            amount: 420,
            frequency: .monthly,
            category: .utilities,
            dueDate: Calendar.current.date(byAdding: .day, value: dueInDays, to: Date()),
            isAutoPaid: false,
            isPaid: isPaid,
            notes: "",
            startDate: nil,
            endDate: nil,
            vendor: "Vendor",
            isActive: true,
            tags: [],
            currencyCode: "USD",
            remindMe: false,
            remindDay: nil,
            remindHour: nil,
            remindMinute: nil
        )
    }
}

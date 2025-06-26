import Foundation
import UserNotifications

@Observable class BudgetController {
    // MARK: — User Settings
    
    /// Which cadence the UI is currently showing (e.g. monthly, weekly).
    var selectedCadence: BudgetCadence = .monthly
    
    // MARK: — Totals
    
    /// Sum of all income amounts.
    func totalIncome(_ incomes: [Income]) -> Decimal {
        incomes.reduce(0) { $0 + $1.amount }
    }
    
    /// Sum of all one-off expenses.
    func totalExpenses(_ expenses: [Expense]) -> Decimal {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    func totalExpenses(expenses: [Expense], paidBills: [Transaction]) -> Decimal {
        let billTotal = paidBills.reduce(Decimal(0)) { sum, bill in
            let freq = BillFrequency(rawValue: bill.frequencyRaw) ?? .monthly
            let amt  = Decimal(bill.amount)
            return sum + Self.normalize(amount: amt, from: freq, to: .monthly)
        }
        
        let expenseTotal = totalExpenses(expenses)
        return billTotal + expenseTotal
    }
    
    /// Sum of all recurring bills, normalized into `cadence`.
    func totalBills(_ bills: [Transaction],
                    for cadence: BudgetCadence) -> Decimal {
        bills.reduce(0) { sum, bill in
            let freq = BillFrequency(rawValue: bill.frequencyRaw) ?? .monthly
            let amt  = Decimal(bill.amount)
            return sum + Self.normalize(amount: amt, from: freq, to: cadence)
        }
    }
    
    // MARK: — Auto-Budget
    
    /// How much you need to earn in `cadence` to cover recurring bills.
    func requiredIncome(for bills: [Transaction],
                        cadence: BudgetCadence) -> Decimal {
        totalBills(bills, for: cadence)
    }
    
    // MARK: — Remaining Budget
    
    /// (Income – bills – expenses) all in the same `cadence`.
    func remainingBudget(bills: [Transaction],
                         expenses: [Expense],
                         incomes: [Income],
                         for cadence: BudgetCadence) -> Decimal
    {
        // Treat all raw values as if they’re monthly sums
        let incomeAmt = Self.normalize(amount: totalIncome(incomes),
                                       from: .monthly,
                                       to:   cadence)
        let billsAmt  = totalBills(bills, for: cadence)
        let spentAmt  = Self.normalize(amount: totalExpenses(expenses),
                                       from: .monthly,
                                       to:   cadence)
        
        return incomeAmt - billsAmt - spentAmt
    }
    
    /// Fraction of your available budget already spent (0…1).
    func spendingProgress(bills: [Transaction],
                          expenses: [Expense],
                          incomes: [Income],
                          for cadence: BudgetCadence) -> Double
    {
        let incomeAmt = Self.normalize(amount: totalIncome(incomes),
                                       from: .monthly,
                                       to:   cadence)
        let billsAmt  = totalBills(bills, for: cadence)
        let budget    = incomeAmt - billsAmt
        let spentAmt  = Self.normalize(amount: totalExpenses(expenses),
                                       from: .monthly,
                                       to:   cadence)
        
        guard budget > 0 else {
            return spentAmt > 0 ? 1 : 0
        }
        
        let fraction = (spentAmt / budget) as NSDecimalNumber
        return min(max(fraction.doubleValue, 0), 1)
    }
    
    // MARK: — Weekly Planner
    
    /// All bills whose next due date is between `start` and `end`.
    func upcomingPayments(bills: [Transaction],
                          from start: Date = .now,
                          to   end:   Date = Calendar.current.date(byAdding: .day, value: 7, to: .now)!)
    -> [Transaction]
    {
        bills
            .compactMap { bill -> (Transaction, Date)? in
                guard let next = nextDueDate(for: bill) else { return nil }
                return (bill, next)
            }
            .filter { $0.1 >= start && $0.1 <= end }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }
    
    /// Computes the next due date for a given bill.
    func nextDueDate(for bill: Transaction) -> Date? {
        guard let base = bill.dueDate else { return nil }
        let freq = BillFrequency(rawValue: bill.frequencyRaw) ?? .monthly
        var date = base
        let cal  = Calendar.current
        
        // oneTime only due once
        if freq == .oneTime {
            return base >= .now ? base : nil
        }
        
        while date < .now {
            switch freq {
            case .daily:
                date = cal.date(byAdding: .day,   value: 1,  to: date)!
            case .weekly:
                date = cal.date(byAdding: .day,   value: 7,  to: date)!
            case .biweekly:
                date = cal.date(byAdding: .day,   value: 14, to: date)!
            case .semiMonthly:
                date = cal.date(byAdding: .day,   value: 15, to: date)!
            case .monthly:
                date = cal.date(byAdding: .month, value: 1,  to: date)!
            case .biMonthly:
                date = cal.date(byAdding: .month, value: 2,  to: date)!
            case .quarterly:
                date = cal.date(byAdding: .month, value: 3,  to: date)!
            case .semiAnnual:
                date = cal.date(byAdding: .month, value: 6,  to: date)!
            case .yearly:
                date = cal.date(byAdding: .year,  value: 1,  to: date)!
            case .oneTime:
                // already handled above
                break
            }
        }
        
        return date
    }
    
    // MARK: — Alerts & Reminders
    
    /// Schedule local notifications for bills with `remindMe == true`.
    func scheduleReminders(for bills: [Transaction]) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        
        for bill in bills where bill.remindMe {
            guard
                let day    = bill.remindDay,
                let hour   = bill.remindHour,
                let minute = bill.remindMinute,
                let next   = nextDueDate(for: bill)
            else { continue }
            
            var comps = Calendar.current.dateComponents([.year, .month], from: next)
            comps.day    = day
            comps.hour   = hour
            comps.minute = minute
            
            let content = UNMutableNotificationContent()
            content.title = "Upcoming bill due: \(bill.name)"
            content.body  = "Amount: \(bill.amount.formatted(.currency(code: bill.currencyCode)))"
            
            let request = UNNotificationRequest(
                identifier: bill.id.uuidString,
                content:    content,
                trigger:    UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            )
            center.add(request)
        }
    }
    
    // MARK: — Frequency Math
    
    /// Convert an amount from one `BillFrequency` into another `BudgetCadence`.
    static func normalize(amount: Decimal,
                          from:   BillFrequency,
                          to:     BudgetCadence) -> Decimal
    {
        // → per-month baseline
        let perMonth: Decimal
        switch from {
        case .oneTime:
            perMonth = amount
        case .daily:
            perMonth = amount * 30
        case .weekly:
            perMonth = amount * Decimal(4.3333)
        case .biweekly:
            perMonth = amount * Decimal(2.1667)
        case .semiMonthly:
            perMonth = amount * 2
        case .monthly:
            perMonth = amount
        case .biMonthly:
            perMonth = amount / 2
        case .quarterly:
            perMonth = amount / 3
        case .semiAnnual:
            perMonth = amount / 6
        case .yearly:
            perMonth = amount / 12
        }
        
        // → target cadence
        switch to {
        case .hourly:
            return perMonth / Decimal(30 * 24)
        case .daily:
            return perMonth / 30
        case .weekly:
            return perMonth / Decimal(4.3333)
        case .monthly:
            return perMonth
        case .yearly:
            return perMonth * 12
        }
    }
    
    func chartData(for incomes: [Income]) -> [Double] {
        chartDataFrom(incomes.map { ($0.date, $0.amount) })
    }
    
    func chartData(for expenses: [Expense]) -> [Double] {
        chartDataFrom(expenses.map { ($0.date, $0.amount) })
    }
    
    private func chartDataFrom(_ entries: [(Date, Decimal)]) -> [Double] {
        var buckets = Array(repeating: 0.0, count: 24)
        let calendar = Calendar.current
        
        for (date, amount) in entries {
            let hour = calendar.component(.hour, from: date)
            let value = (amount as NSDecimalNumber).doubleValue
            buckets[hour] += value
        }
        
        return buckets
    }
}

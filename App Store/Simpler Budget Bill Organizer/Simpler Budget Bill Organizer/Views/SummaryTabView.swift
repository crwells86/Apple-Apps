import SwiftUI
import SwiftData
import FinanceKit

struct SummaryTabView: View {
    @Environment(BudgetController.self) private var budget: BudgetController
    @Query(sort: \Transaction.dueDate) private var bills: [Transaction]
    @Query private var incomes: [Income]
    @Query private var expenses: [Expense]
    @Query var categories: [Category]
    
    var paidBills: [Transaction] {
        bills.filter { $0.isPaid }
    }
    
    var paidBillsAsExpenses: [Expense] {
        paidBills.map { bill in
            Expense(amount: Decimal(bill.amount), vendor: bill.vendor, date: bill.dueDate ?? Date(), category: Category(name: "none", icon: "circle", limit: 0, isDefault: false))
        }
    }
    
    // MARK: - Date boundaries for current month
    private let calendar = Calendar.current
    private let now = Date()
    private var thisMonthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
    }
    private var nextMonthStart: Date {
        calendar.date(byAdding: .month, value: 1, to: thisMonthStart)!
    }
    
    // MARK: - Filtered data for current month
    private var incomesThisMonth: [Income] {
        incomes.filter { income in
            //                guard  else { return false }
            let date = income.date
            return date >= thisMonthStart && date < nextMonthStart
        }
    }
    
    private var expensesThisMonth: [Expense] {
        expenses.filter { expense in
            expense.date >= thisMonthStart && expense.date < nextMonthStart
        }
    }
    
    private var paidBillsThisMonth: [Transaction] {
        paidBills.filter { bill in
            guard let dueDate = bill.dueDate else { return false }
            return dueDate >= thisMonthStart && dueDate < nextMonthStart
        }
    }
    
    private var paidBillsAsExpensesThisMonth: [Expense] {
        paidBillsThisMonth.map { bill in
            Expense(amount: Decimal(bill.amount), vendor: bill.vendor, date: bill.dueDate ?? Date(), category: Category(name: "none", icon: "circle", limit: 0, isDefault: false))
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    SectionHeader(title: "Spending By Category", systemImage: "chart.pie")
                    
                    let spendingData = spendingByCategory(from: categories)
                    
                    if spendingData.isEmpty {
                        ContentUnavailableView("No Spending Categories", systemImage: "chart.pie")
                    } else {
                        DoughnutChartView(data: spendingData)
                    }
                    
                    // MARK: - Income vs. Spending
                    SectionHeader(title: "Income vs. Spending", systemImage: "chart.xyaxis.line")
                    
                    CashFlowSectionView(
                        income: budget.totalIncome(incomesThisMonth),
                        expense: budget.totalExpenses(expenses: expensesThisMonth, paidBills: paidBillsThisMonth),
                        incomeChartData: budget.chartData(for: incomesThisMonth),
                        expenseChartData: budget.chartData(for: expensesThisMonth + paidBillsAsExpensesThisMonth)
                    )
                    
                    // MARK: - Spending by Category
                    SectionHeader(title: "Spending Trends", systemImage: "list.bullet.rectangle")
                    
                    SpendingSectionView(expenses: expenses)
                    
                    // MARK: - Quick Stats
                    SectionHeader(title: "Quick Stats", systemImage: "sparkle.magnifyingglass")
                    
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            HighlightBox(
                                title: "Upcoming Bills",
                                value: "\(budget.upcomingPayments(bills: bills).count)"
                            )
                            
                            KPIView(
                                title: "Paid Bills",
                                value: "\(paidBills.count)"
                            )
                        }
                        
                        HStack(spacing: 16) {
                            ValueCard(
                                title: "Needed Monthly Income",
                                value: budget.requiredIncome(for: bills, cadence: .monthly).formatted(.currency(code: "USD"))
                            )
                            
                            DataPanel(
                                title: "Spent This Month",
                                value: "\(Int(budget.spendingProgress(bills: bills, expenses: expenses, incomes: incomes, for: .monthly) * 100))%"
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        sendFeedbackEmail()
                    } label: {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                }
            }
        }
    }
    
    func sendFeedbackEmail() {
        let subject = "App Feedback – Simpler Budget"
        let body = "Share some feedback..."
        let email = "calebrwells@gmail.com"
        
        let emailURL = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")

        if let url = emailURL {
            UIApplication.shared.open(url)
        }
    }
    
    private func sharePDF(at url: URL) {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.keyWindow?.rootViewController else {
            return
        }
        
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        root.present(vc, animated: true)
    }
}





struct IncomeDetailView: View {
    var body: some View {
        Text("Income Details")
    }
}

struct ExpenseDetailView: View {
    var body: some View {
        Text("Expense Details")
    }
}




private struct SectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.headline)
            Text(title)
                .font(.title2.bold())
            Spacer()
        }
        .padding(.horizontal)
    }
}



import SwiftUI
import Charts

struct SpendingSectionView: View {
    let expenses: [Expense]
    
    private struct MonthSpend: Identifiable {
        let id = UUID()
        let month: String
        let amount: Double
    }
    
    private var lastFour: [MonthSpend] {
        let cal = Calendar.current
        let today = Date()
        let df = DateFormatter()
        df.dateFormat = "LLL"
        
        return (0..<4).reversed().compactMap { offset in
            guard let d = cal.date(byAdding: .month, value: -offset, to: today) else { return nil }
            let comps = cal.dateComponents([.year, .month], from: d)
            let totalDecimal = expenses
                .filter { cal.component(.year, from: $0.date) == comps.year
                    && cal.component(.month, from: $0.date) == comps.month }
                .reduce(Decimal(0)) { $0 + $1.amount }
            let total = (totalDecimal as NSDecimalNumber).doubleValue
            return MonthSpend(month: df.string(from: d), amount: total)
        }
    }
    
    private var lastMonthTotal: Double {
        guard lastFour.count >= 2 else { return 0 }
        return lastFour[lastFour.count - 2].amount
    }
    
    private var thisMonthTotal: Double {
        lastFour.last?.amount ?? 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            CardView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spent").font(.subheadline)
                    Text(thisMonthTotal, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                         // format: .currency(code: "USD"))
                        .font(.title2).bold()
                    HStack(spacing: 4) {
                        Image(systemName: (thisMonthTotal - lastMonthTotal) >= 0
                              ? "arrow.up"
                              : "arrow.down")
                        .font(.caption)
                        
                        let diff = thisMonthTotal - lastMonthTotal
                        let isIncrease = diff >= 0
                        
                        Text("\(abs(diff), format: .currency(code: Locale.current.currency?.identifier ?? "USD")) \(isIncrease ? "more" : "less") than last month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 122)
            }
            
            CardView {
                Chart {
                    ForEach(lastFour) { item in
                        BarMark(
                            x: .value("Month", item.month),
                            y: .value("Spent", item.amount)
                        )
                    }
                }
                .frame(height: 100)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .frame(height: 127)
            }
        }
        .padding(.horizontal)
    }
}



import SwiftUI

struct CardView<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
    }
}


import SwiftUI

struct LabelPanel<ValueStyle: FormatStyle>: View where ValueStyle.FormatInput == Decimal {
    let label: String
    let value: Decimal
    let format: ValueStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.subheadline)
            //            Text(value, format: format)
            //                .font(.title2).bold()
        }
    }
}


import SwiftUI

struct BudgetCardView: View {
    let bill: Transaction
    
    var body: some View {
        let amt = BudgetController.normalize(
            amount: Decimal(bill.amount),
            from: BillFrequency(rawValue: bill.frequencyRaw) ?? .monthly,
            to: .monthly
        )
        
        return VStack(spacing: 8) {
            Image(systemName: "tag")
                .font(.title2)
            Text(bill.name).font(.subheadline).lineLimit(1)
            Text(amt, format: .currency(code: bill.currencyCode))
                .font(.headline)
        }
        .padding()
        .frame(width: 100)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}








// Shared Models & Helpers
import SwiftUI
import Charts
import SwiftData

// 4. Upcoming Payments
struct UpcomingPaymentsView: View {
    @Environment(BudgetController.self) private var budget
    @Query private var bills: [Transaction]
    
    var body: some View {
        List(budget.upcomingPayments(bills: bills)) { bill in
            VStack(alignment: .leading) {
                Text(bill.name)
                Text(bill.dueDate!, style: .date).font(.caption)
                Text(bill.amount.formatted(.currency(code: bill.currencyCode))).font(.caption2)
            }
        }
    }
}


// 6. Income vs. Expenses Over Time
struct IncomeVsExpensesChartView: View {
    @Environment(BudgetController.self) private var budget
    @Query private var incomes: [Income]
    @Query private var expenses: [Expense]
    
    var body: some View {
        Chart {
            ForEach(Array(budget.chartData(for: incomes).enumerated()), id: \ .offset) { hour, value in
                LineMark(x: .value("Hour", hour), y: .value("Income", value))
                    .foregroundStyle(.green)
            }
            ForEach(Array(budget.chartData(for: expenses).enumerated()), id: \ .offset) { hour, value in
                LineMark(x: .value("Hour", hour), y: .value("Expenses", value))
                    .foregroundStyle(.red)
            }
        }
        .frame(height: 200)
    }
}

// 15. Smart Suggestions
struct SmartSuggestionsView: View {
    @Environment(BudgetController.self) private var budget
    @Query private var incomes: [Income]
    @Query private var expenses: [Expense]
    @Query private var bills: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading) {
            if budget.spendingProgress(bills: bills, expenses: expenses, incomes: incomes, for: .monthly) > 0.9 {
                Label("You’re spending more than 90% of your income", systemImage: "exclamationmark.triangle")
            }
            if budget.upcomingPayments(bills: bills).isEmpty {
                Label("No bills in the next 7 days — good time to save!", systemImage: "lightbulb")
            }
        }
        .padding()
    }
}

// 16. Savings Forecast
struct SavingsForecastView: View {
    @Environment(BudgetController.self) private var budget
    @Query private var incomes: [Income]
    @Query private var expenses: [Expense]
    @Query private var bills: [Transaction]
    
    var body: some View {
        let savings = budget.remainingBudget(bills: bills, expenses: expenses, incomes: incomes, for: .monthly)
        VStack(alignment: .leading) {
            Text("Forecasted Savings")
                .font(.headline)
            Text(savings.formatted(.currency(code: "USD")))
                .foregroundStyle(.green)
        }
        .padding()
    }
}

// 17. Budget History (simplified version)
struct BudgetHistoryView: View {
    @Query private var incomes: [Income]
    @Query private var expenses: [Expense]
    
    var body: some View {
        List {
            ForEach(0..<6, id: \.self) { offset in
                let date = Calendar.current.date(byAdding: .month, value: -offset, to: .now)!
                let income = incomes.filter { Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month) }.reduce(0) { $0 + $1.amount }
                let expense = expenses.filter { Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month) }.reduce(0) { $0 + $1.amount }
                HStack {
                    Text(date.formatted(.dateTime.month()))
                    Spacer()
                    Text("Net: \((income - expense).formatted(.currency(code: "USD")))")
                }
            }
        }
    }
}

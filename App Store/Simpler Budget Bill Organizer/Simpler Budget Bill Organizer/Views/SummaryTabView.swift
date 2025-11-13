import SwiftUI
import SwiftData
import Charts

// MARK: - Main Summary Tab View
struct SummaryTabView: View {
    @Environment(BudgetController.self) private var budget: BudgetController
    @Query(filter: #Predicate<Transaction> { $0.dueDate != nil }, sort: \Transaction.dueDate) private var bills: [Transaction]
    @Query private var incomes: [Income]
    @Query private var expenses: [Expense]
    @Query var categories: [Category]
    
    @State private var selectedRange: TimeRange = .month
    @State private var showInsights: Bool = false
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case month = "Month"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case twoYears = "2Y"
        var id: String { rawValue }
    }
    
    private let calendar = Calendar.current
    private let now = Date()
    
    // Centralized date boundaries based on selected range
    private var periodStart: Date {
        switch selectedRange {
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .twoYears:
            return calendar.date(byAdding: .year, value: -2, to: now) ?? now
        }
    }

    private var periodEnd: Date { now }
    
    private var incomesThisMonth: [Income] {
        incomes.filter { $0.date >= periodStart && $0.date < periodEnd && $0.amount > 0 }
    }
    
    private var expensesThisMonth: [Expense] {
        expenses.filter { $0.date >= periodStart && $0.date < periodEnd && $0.amount > 0 }
    }
    
    // Upcoming, unpaid bills with a future due date
    private var upcomingUnpaidBills: [Transaction] {
        bills.filter { bill in
            guard !bill.isPaid, let dueDate = bill.dueDate else { return false }
            return dueDate >= now
        }
    }

    // Paid bills within the selected period
    private var paidBillsThisPeriod: [Transaction] {
        bills.filter { bill in
            guard bill.isPaid, let dueDate = bill.dueDate else { return false }
            return dueDate >= periodStart && dueDate < periodEnd
        }
    }
    
    private var totalIncome: Decimal {
        budget.totalIncome(incomesThisMonth)
    }
    
    private var totalExpenses: Decimal {
        budget.totalExpenses(expenses: expensesThisMonth, paidBills: paidBillsThisPeriod)
    }
    
    private var netCashFlow: Decimal {
        totalIncome - totalExpenses
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    RangePicker(selectedRange: $selectedRange)
                        .padding(.horizontal)
                    
                    // MARK: - Hero Card with Net Cash Flow
                    HeroBalanceCard(
                        income: totalIncome,
                        expenses: totalExpenses,
                        net: netCashFlow,
                        range: selectedRange
                    )
                    .padding(.horizontal)
                    
                    // MARK: - Smart Insights Banner
                    if shouldShowInsights {
                        SmartInsightsBanner(
                            bills: bills,
                            expenses: expensesThisMonth,
                            income: totalIncome,
                            totalExpenses: totalExpenses
                        )
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Cash Flow Visualization
                    VStack(alignment: .leading, spacing: 16) {
                        SectionTitle(
                            title: "Cash Flow",
                            systemImage: "chart.line.uptrend.xyaxis",
                            action: { showInsights.toggle() }
                        )
                        
                        CashFlowChartCard(
                            incomes: incomesThisMonth,
                            expenses: expensesThisMonth,
                            paidBills: paidBillsThisPeriod,
                            budget: budget
                        )
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Upcoming Bills
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(
                            title: "Upcoming Bills",
                            systemImage: "calendar.badge.clock",
                            badge: "\(upcomingUnpaidBills.count)"
                        )
                        
                        UpcomingBillsCard(bills: upcomingUnpaidBills)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Spending Trends
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(
                            title: "Spending Trends",
                            systemImage: "chart.bar.fill"
                        )
                        
                        SpendingTrendsCard(expenses: expenses)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Spending Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(
                            title: "Spending Breakdown",
                            systemImage: "chart.pie.fill"
                        )
                        
                        let spendingData = spendingByCategory(from: categories)
                        
                        if spendingData.isEmpty {
                            EmptyStateCard(
                                icon: "chart.pie",
                                message: "No spending data yet",
                                subtitle: "Add expenses to see your breakdown"
                            )
                        } else {
                            ModernDoughnutChart(data: spendingData)
                            
                            CategoryBreakdownList(
                                data: spendingData,
                                totalSpent: totalExpenses
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Financial Health Score
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(
                            title: "Financial Health",
                            systemImage: "heart.text.square.fill"
                        )
                        
                        FinancialHealthCard(
                            income: totalIncome,
                            expenses: totalExpenses,
                            savingsRate: calculateSavingsRate()
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Period", selection: $selectedRange) {
                            ForEach(TimeRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            sendFeedbackEmail()
                        } label: {
                            Label("Send Feedback", systemImage: "envelope")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
        }
    }
    
    private var shouldShowInsights: Bool {
        let spendingProgress = budget.spendingProgress(
            bills: paidBillsThisPeriod,
            expenses: expensesThisMonth,
            incomes: incomesThisMonth,
            for: .monthly
        )
        return spendingProgress > 0.8 || upcomingUnpaidBills.isEmpty
    }
    
    private func calculateSavingsRate() -> Double {
        guard totalIncome > 0 else { return 0 }
        return Double(truncating: (netCashFlow / totalIncome) as NSDecimalNumber)
    }
    
    private func sendFeedbackEmail() {
        let subject = "App Feedback – Simpler Budget"
        let body = "Share some feedback..."
        let email = "caleb@olyevolutions.com"
        
        let emailURL = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        
        if let url = emailURL {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Hero Balance Card
struct HeroBalanceCard: View {
    let income: Decimal
    let expenses: Decimal
    let net: Decimal
    let range: SummaryTabView.TimeRange
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Net Cash Flow")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(net, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(net >= 0 ? .green : .red)
                
                Text("Last \(range.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Income")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(income, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("Expenses")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(expenses, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        }
    }
}

// MARK: - Smart Insights Banner
struct SmartInsightsBanner: View {
    let bills: [Transaction]
    let expenses: [Expense]
    let income: Decimal
    let totalExpenses: Decimal
    
    private var insightMessage: (icon: String, title: String, color: Color) {
        let spendingRatio = Double(truncating: (totalExpenses / max(income, 1)) as NSDecimalNumber)
        
        if spendingRatio > 0.9 {
            return ("exclamationmark.triangle.fill", "You've spent over 90% of your income", .orange)
        } else if spendingRatio > 0.7 {
            return ("info.circle.fill", "You're on track but watch spending", .blue)
        } else {
            return ("checkmark.circle.fill", "Great job staying under budget!", .green)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insightMessage.icon)
                .font(.title2)
                .foregroundStyle(insightMessage.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Insight")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(insightMessage.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(insightMessage.color.opacity(0.1))
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(width: 100, height: 80)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Cash Flow Chart Card
struct CashFlowChartCard: View {
    let incomes: [Income]
    let expenses: [Expense]
    let paidBills: [Transaction]
    let budget: BudgetController
    
    private let incomeColor: Color = .green
    private let expenseColor: Color = .red
    
    private var paidBillsAsExpenses: [Expense] {
        struct Key: Hashable {
            let vendor: String
            let day: Date
        }
        let cal = Calendar.current
        let existingKeys: Set<Key> = Set(expenses.map { exp in
            let day = cal.startOfDay(for: exp.date)
            return Key(vendor: exp.vendor, day: day)
        })

        var results: [Expense] = []
        results.reserveCapacity(paidBills.count)

        for bill in paidBills {
            guard let due = bill.dueDate else { continue }
            let day = cal.startOfDay(for: due)
            let key = Key(vendor: bill.vendor, day: day)
            if existingKeys.contains(key) { continue }

            // Construct a lightweight Expense using an existing or placeholder category name only
            let amount = Decimal(bill.amount)
            let vendor = bill.vendor
            let date = due
            let placeholderCategory = Category(name: "Bills", icon: "circle", limit: 0, isDefault: false)
            let expense = Expense(amount: amount, vendor: vendor, date: date, category: placeholderCategory)
            results.append(expense)
        }
        return results
    }
    
    var body: some View {
        // Precompute everything up-front to keep the Chart builder simple
        let cal = Calendar.current

        // Income points
        let sortedIncomes: [Income] = incomes.sorted { $0.date < $1.date }
        let incomePoints: [(date: Date, amount: Double)] = sortedIncomes.map { item in
            let amt = Double(truncating: item.amount as NSDecimalNumber)
            return (date: item.date, amount: amt)
        }

        // Expense points (include paid bills as expenses)
        let combinedExpenses: [Expense] = (expenses + paidBillsAsExpenses).sorted { $0.date < $1.date }
        let expensePoints: [(date: Date, amount: Double)] = combinedExpenses.map { item in
            let amt = -Double(truncating: item.amount as NSDecimalNumber)
            return (date: item.date, amount: amt)
        }

        // Determine visible domain
        let allDates: [Date] = (incomePoints.map { $0.date } + expensePoints.map { $0.date }).sorted()
        let domainStart: Date = allDates.first ?? Date()
        let domainEnd: Date = allDates.last ?? domainStart

        // Month start rule outside the Chart builder
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()

        return VStack(alignment: .leading, spacing: 16) {
            Chart {
                // Income bars
                ForEach(Array(incomePoints.enumerated()), id: \.offset) { _, point in
                    BarMark(
                        x: .value("Date", point.date),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(incomeColor)
                }

                // Expense bars (negative for below baseline)
                ForEach(Array(expensePoints.enumerated()), id: \.offset) { _, point in
                    BarMark(
                        x: .value("Date", point.date),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(expenseColor)
                }

                // Vertical rule at the first of the month (leading edge anchor)
                RuleMark(x: .value("Date", monthStart))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 180)
            .chartXScale(domain: domainStart...max(domainEnd, domainStart.addingTimeInterval(24*60*60)))
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
}

struct CategoryRow: View {
    let name: String
    let amount: Decimal
    let color: Color
    let percentage: Decimal
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.subheadline)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.subheadline.bold())
                Text("\(Int(Double(truncating: percentage as NSDecimalNumber) * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Upcoming Bills Card
struct UpcomingBillsCard: View {
    let bills: [Transaction]
    
    var body: some View {
        if bills.isEmpty {
            EmptyStateCard(
                icon: "calendar.badge.checkmark",
                message: "No upcoming bills",
                subtitle: "You're all caught up!"
            )
        } else {
            VStack(spacing: 0) {
                ForEach(Array(bills.prefix(5).enumerated()), id: \.element.id) { index, bill in
                    BillRow(bill: bill)
                    
                    if index < min(4, bills.count - 1) {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

struct BillRow: View {
    let bill: Transaction
    
    private var daysUntilDue: Int {
        guard let dueDate = bill.dueDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        return max(0, days)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background {
                    Circle()
                        .fill(.blue.opacity(0.1))
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(bill.name)
                    .font(.subheadline.bold())
                Text("Due in \(daysUntilDue) days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(bill.amount, format: .currency(code: bill.currencyCode))
                .font(.subheadline.bold())
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Spending Trends Card
struct SpendingTrendsCard: View {
    let expenses: [Expense]
    
    private struct MonthData: Identifiable {
        let id = UUID()
        let month: String
        let amount: Double
    }
    
    private var lastSixMonths: [MonthData] {
        let cal = Calendar.current
        let today = Date()
        let df = DateFormatter()
        df.dateFormat = "MMM"
        
        return (0..<6).reversed().compactMap { offset in
            guard let d = cal.date(byAdding: .month, value: -offset, to: today) else { return nil }
            let comps = cal.dateComponents([.year, .month], from: d)
            let total = expenses
                .filter {
                    cal.component(.year, from: $0.date) == comps.year &&
                    cal.component(.month, from: $0.date) == comps.month
                }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return MonthData(month: df.string(from: d), amount: Double(truncating: total as NSDecimalNumber))
        }
    }
    
    private var trendDirection: (icon: String, text: String, color: Color) {
        guard lastSixMonths.count >= 2 else {
            return ("minus", "No trend", .gray)
        }
        
        let current = lastSixMonths.last?.amount ?? 0
        let previous = lastSixMonths[lastSixMonths.count - 2].amount
        let diff = current - previous
        
        if abs(diff) < 0.01 {
            return ("minus", "Stable", .gray)
        } else if diff > 0 {
            return ("arrow.up.right", "Increasing", .red)
        } else {
            return ("arrow.down.right", "Decreasing", .green)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trend")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Image(systemName: trendDirection.icon)
                            .font(.subheadline)
                        Text(trendDirection.text)
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(trendDirection.color)
                }
                
                Spacer()
            }
            
            Chart(lastSixMonths) { month in
                BarMark(
                    x: .value("Month", month.month),
                    y: .value("Amount", month.amount)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(6)
            }
            .frame(height: 140)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Modern Doughnut Chart
struct ModernDoughnutChart: View {
    let data: [(String, Double, Color)]
    
    var body: some View {
        Chart(Array(data.enumerated()), id: \.offset) { index, item in
            SectorMark(
                angle: .value("Amount", item.1),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(item.2)
            .cornerRadius(4)
        }
        .frame(height: 200)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Category Breakdown List
struct CategoryBreakdownList: View {
    let data: [(String, Double, Color)]
    let totalSpent: Decimal
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                CategoryRow(
                    name: item.0,
                    amount: Decimal(item.1),
                    color: item.2,
                    percentage: totalSpent > 0 ? (Decimal(item.1) / totalSpent) : 0
                )
                
                if index < data.count - 1 {
                    Divider()
                        .padding(.leading, 48)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
}


// MARK: - Financial Health Card
struct FinancialHealthCard: View {
    let income: Decimal
    let expenses: Decimal
    let savingsRate: Double
    
    private var healthScore: Int {
        Int(max(0, min(100, savingsRate * 100 + 50)))
    }
    
    private var healthStatus: (text: String, color: Color) {
        switch healthScore {
        case 80...100: return ("Excellent", .green)
        case 60..<80: return ("Good", .blue)
        case 40..<60: return ("Fair", .orange)
        default: return ("Needs Work", .red)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Health Score")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(healthScore)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(healthStatus.color)
                    Text(healthStatus.text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(healthStatus.color.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: Double(healthScore) / 100)
                        .stroke(healthStatus.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                }
            }
            
            Divider()
            
            HStack(spacing: 20) {
                MetricItem(
                    label: "Savings Rate",
                    value: "\(Int(savingsRate * 100))%",
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                Divider()
                    .frame(height: 40)
                
                MetricItem(
                    label: "Net Worth",
                    value: "\((income - expenses).formatted(.currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(0))))",
                    icon: "dollarsign.circle"
                )
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
}

struct MetricItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Title
struct SectionTitle: View {
    let title: String
    let systemImage: String
    var badge: String?
    var action: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.blue)
            
            Text(title)
                .font(.title3.bold())
            
            if let badge = badge {
                Text(badge)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(.blue.opacity(0.15))
                    }
                    .foregroundStyle(.blue)
            }
            
            Spacer()
            
//            if let action = action {
//                Button(action: action) {
//                    Image(systemName: "chevron.right")
//                        .font(.caption.bold())
//                        .foregroundStyle(.secondary)
//                }
//            }
        }
    }
}

// MARK: - Range Picker
struct RangePicker: View {
    @Binding var selectedRange: SummaryTabView.TimeRange
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SummaryTabView.TimeRange.allCases) { range in
                    Button {
                        selectedRange = range
                    } label: {
                        Text(range.rawValue)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(range == selectedRange ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.1))
                            )
                            .foregroundStyle(range == selectedRange ? .blue : .primary)
                    }
                }
            }
        }
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    let icon: String
    let message: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text(message)
                .font(.subheadline.bold())
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Helper Functions
extension SummaryTabView {
    func spendingByCategory(from categories: [Category]) -> [(String, Double, Color)] {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .teal, .indigo]
        
        return categories.enumerated().compactMap { index, category in
            let total = expensesThisMonth
                .filter { $0.category?.name == category.name }
                .reduce(Decimal(0)) { $0 + $1.amount }
            
            let doubleTotal = Double(truncating: total as NSDecimalNumber)
            
            guard doubleTotal > 0 else { return nil }
            
            return (category.name, doubleTotal, colors[index % colors.count])
        }
        .sorted { $0.1 > $1.1 }
    }
}


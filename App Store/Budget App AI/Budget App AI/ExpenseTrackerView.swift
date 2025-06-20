import SwiftUI
import StoreKit
import SwiftData

struct ExpenseTrackerView: View {
    @Environment(\.modelContext) private var context
    @Query private var allExpenses: [Expense]
    
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State private var selectedTimeframe: Timeframe = .week
    @State private var editingExpense: Expense? = nil
    
    @AppStorage("monthlyBudget") private var monthlyBudgetRaw: Double = 6087
    @State private var showingBudgetEditor = false
    
    @AppStorage("hasSeenIntro") private var hasSeenIntro: Bool = false
    
    @State private var showingPaywall = false
    @State private var subscriptionController = SubscriptionController()
    
    @AppStorage("hasSeenReviewPrompt") private var hasSeenReviewPrompt = false
    
    var monthlyBudget: Decimal {
        Decimal(monthlyBudgetRaw)
    }
    
    // MARK: - Budget Calculation
    private var filteredExpenses: [Expense] {
        let fromDate = selectedTimeframe.startDate()
        return allExpenses.filter { $0.date >= fromDate }
    }
    
    private var totalAmount: Decimal {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var remainingBudget: Decimal {
        monthlyBudgetPerCurrentTimeframe - totalAmount
    }
    
    private var monthlyBudgetPerCurrentTimeframe: Decimal {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeframe {
        case .day:
            let days = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            return monthlyBudget / Decimal(days)
        case .week:
            let weeks = Double((calendar.range(of: .day, in: .month, for: now)?.count ?? 30)) / 7.0
            return monthlyBudget / Decimal(weeks)
        case .month:
            return monthlyBudget
        case .year:
            return monthlyBudget * 12
        }
    }
    
    
    // MARK: - Grouped Expenses
    private var groupedExpensesByMonth: [(key: String, value: [Expense])] {
        let calendar = Calendar.current
        let sorted = filteredExpenses.sorted { $0.date > $1.date }
        
        let grouped = Dictionary(grouping: sorted) { expense -> String in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            let date = calendar.date(from: components)!
            return DateFormatter.monthAndYear.string(from: date)
        }
        
        return grouped.sorted {
            guard let lhs = DateFormatter.monthAndYear.date(from: $0.key),
                  let rhs = DateFormatter.monthAndYear.date(from: $1.key) else { return false }
            return lhs > rhs
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                NavigationLink {
                    if !subscriptionController.isSubscribed {
                        PaywallView()
                    } else {
                        ExpenseStatsView()
                    }
                } label: {
                    BudgetSummaryView(
                        selectedTimeframe: selectedTimeframe,
                        totalAmount: totalAmount,
                        remainingBudget: remainingBudget
                    )
                }
                
                TimeframePickerView(selectedTimeframe: $selectedTimeframe)
                
                GroupedExpensesListView(
                    groupedExpenses: groupedExpensesByMonth,
                    onDelete: { context.delete($0) },
                    onEdit: { editingExpense = $0 }
                )
                
                VoiceExpenseButton(
                    isRecording: $isRecording,
                    showingPaywall: $showingPaywall,
                    speechRecognizer: $speechRecognizer,
                    context: context,
                    allExpenses: allExpenses,
                    parseExpense: parseExpense,
                    subscriptionController: subscriptionController
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingBudgetEditor = true
                    } label: {
                        Label("Edit Budget", systemImage: "dollarsign.circle")
                    }
                }
            }
            .sheet(isPresented: $showingBudgetEditor) {
                EditBudgetView(budget: $monthlyBudgetRaw)
            }
            .sheet(item: $editingExpense) { expense in
                EditExpenseView(expense: expense)
            }
            .sheet(isPresented: .constant(!hasSeenIntro)) {
                IntroSheetView {
                    hasSeenIntro = true
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environment(SubscriptionController())
            }
            .onChange(of: allExpenses.count) {
                if allExpenses.count >= 28 && !hasSeenReviewPrompt {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: windowScene)
                        hasSeenReviewPrompt = true
                    }
                }
            }
        }
    }
}















import SwiftUI
import Charts
import SwiftData

struct ExpenseStatsView: View {
    @Environment(\.modelContext) private var context
    @State private var allExpenses: [Expense] = []
    @State private var selectedTimeRange: TimeRange = .daily
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Summary Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        summaryCard(title: "Total Spent", value: formatted(totalAmount))
                        summaryCard(title: "Avg. per Day", value: formatted(averagePerDay))
                        summaryCard(title: "Transactions", value: "\(filteredExpenses.count)")
                        summaryCard(title: "Highest Day", value: formatted(highestDayAmount), subtitle: highestDayFormatted)
                        summaryCard(title: "Lowest Day", value: formatted(lowestDayAmount), subtitle: lowestDayFormatted)
                        summaryCard(title: "Streak (↓ Spending)", value: "\(lowSpendingStreak) days")
                    }
                    .padding(.horizontal)
                    
                    // Charts
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Spending Trends")
                            .font(.title3)
                            .bold()
                            .padding(.horizontal)
                        
                        ExpenseTrendChart(timeRange: selectedTimeRange, expenses: filteredExpenses)
                            .frame(height: 220)
                            .padding(.horizontal)
                        
                        Text("Category Breakdown")
                            .font(.title3)
                            .bold()
                            .padding(.horizontal)
                        
                        CategoryDonutChart(expenses: filteredExpenses)
                            .frame(height: 220)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Summary")
            .onAppear(perform: fetchAllExpenses)
        }
    }
    
    // MARK: - Data & Computation
    private var filteredExpenses: [Expense] {
        let now = Date()
        switch selectedTimeRange {
        case .allTime:
            return allExpenses
        default:
            let start = selectedTimeRange.startDate(from: now)
            return allExpenses.filter { $0.date >= start && $0.date <= now }
        }
    }
    
    private var totalAmount: Decimal { filteredExpenses.reduce(0) { $0 + $1.amount } }
    private var averagePerDay: Decimal {
        guard filteredExpenses.isEmpty == false else { return 0 }
        let days = max(1, filteredExpensesDayCount)
        return totalAmount / Decimal(days)
    }
    
    private var filteredExpensesDayCount: Int {
        switch selectedTimeRange {
        case .daily: return 1
        case .weekly: return 7
        case .monthly: return 30
        case .yearly: return 365
        case .allTime:
            let dates = allExpenses.map { Calendar.current.startOfDay(for: $0.date) }
            let unique = Set(dates)
            return max(1, unique.count)
        }
    }
    
    private var groupedByDay: [(Date, Decimal)] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: filteredExpenses) { cal.startOfDay(for: $0.date) }
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return grouped.sorted { $0.key < $1.key }
    }
    
    private var highestDay: (Date, Decimal)? { groupedByDay.max(by: { $0.1 < $1.1 }) }
    private var lowestDay: (Date, Decimal)? { groupedByDay.min(by: { $0.1 < $1.1 }) }
    private var highestDayAmount: Decimal { highestDay?.1 ?? 0 }
    private var lowestDayAmount: Decimal { lowestDay?.1 ?? 0 }
    private var highestDayFormatted: String { highestDay?.0.formatted(date: .abbreviated, time: .omitted) ?? "N/A" }
    private var lowestDayFormatted: String { lowestDay?.0.formatted(date: .abbreviated, time: .omitted) ?? "N/A" }
    
    private var lowSpendingStreak: Int {
        let avg = averagePerDay
        var streak = 0
        for (_, amount) in groupedByDay.reversed() {
            if amount <= avg { streak += 1 } else { break }
        }
        return streak
    }
    
    // MARK: - UI Components
    @ViewBuilder
    private func summaryCard(title: String, value: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .bold()
            if let sub = subtitle {
                Text(sub)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 87)
        .background(.ultraThickMaterial)
        .cornerRadius(14)
        .shadow(radius: 2)
    }
    
    private func formatted(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSNumber) ?? "$0.00"
    }
    
    private func fetchAllExpenses() {
        do {
            allExpenses = try context.fetch(FetchDescriptor<Expense>())
        } catch {
            print("Fetch error: \(error)")
        }
    }
}

// MARK: - TimeRange
enum TimeRange: CaseIterable {
    case daily, weekly, monthly, yearly, allTime
    
    var title: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .allTime: return "All Time"
        }
    }
    
    func startDate(from date: Date) -> Date {
        let cal = Calendar.current
        switch self {
        case .daily:
            return cal.startOfDay(for: date)
        case .weekly:
            return cal.date(byAdding: .day, value: -6, to: date) ?? date
        case .monthly:
            return cal.date(byAdding: .month, value: -1, to: date) ?? date
        case .yearly:
            return cal.date(byAdding: .year, value: -1, to: date) ?? date
        case .allTime:
            return date // not used
        }
    }
}

// MARK: - Charts
struct ExpenseTrendChart: View {
    var timeRange: TimeRange
    var expenses: [Expense]
    
    var body: some View {
        Chart {
            ForEach(groupedExpenses(), id: \.0) { date, total in
                LineMark(x: .value("Date", date), y: .value("Amount", total))
                PointMark(x: .value("Date", date), y: .value("Amount", total))
            }
        }
        .chartYAxis { AxisMarks(position: .leading) }
    }
    
    private func groupedExpenses() -> [(Date, Decimal)] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: expenses) { exp in
            switch timeRange {
            case .daily, .weekly:
                return cal.startOfDay(for: exp.date)
            case .monthly:
                return cal.dateInterval(of: .weekOfMonth, for: exp.date)?.start ?? exp.date
            case .yearly:
                return cal.dateInterval(of: .month, for: exp.date)?.start ?? exp.date
            case .allTime:
                return cal.startOfDay(for: exp.date)
            }
        }
        return grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }
            .sorted(by: { $0.key < $1.key })
    }
}

struct CategoryDonutChart: View {
    var expenses: [Expense]
    
    var body: some View {
        Chart {
            ForEach(groupedCategories(), id: \.key) { category, total in
                SectorMark(angle: .value("Amount", total), innerRadius: .ratio(0.6))
                    .foregroundStyle(by: .value("Category", category))
            }
        }
        .chartLegend(position: .bottom)
    }
    
    private func groupedCategories() -> [(key: String, value: Decimal)] {
        Dictionary(grouping: expenses, by: { $0.vendor })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
            .sorted { $0.value > $1.value }
    }
}



//func loadMockExpenses(into context: ModelContext) {
//    let calendar = Calendar.current
//    let now = Date()
//    let vendors = [
//        ("Rent", 1800...2500),
//        ("Groceries", 20...150),
//        ("Dining Out", 10...80),
//        ("Coffee", 3...7),
//        ("Public Transit", 2...4),
//        ("Uber/Lyft", 10...35),
//        ("Healthcare", 50...200),
//        ("Entertainment", 10...100),
//        ("Utilities", 100...200),
//        ("Subscriptions", 8...20)
//    ]
//    
//    for dayOffset in 0..<365 {
//        let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
//        
//        // Generate 1–4 expenses per day
//        let dailyExpenseCount = Int.random(in: 1...4)
//        
//        for _ in 0..<dailyExpenseCount {
//            let vendor = vendors.randomElement()!
//            let amount = Decimal(Double(Int.random(in: vendor.1)) + Double.random(in: 0..<1)).rounded(scale: 2)
//            
//            let expense = Expense(
//                amount: amount,
//                vendor: vendor.0, date: date
//            )
//            context.insert(expense)
//        }
//    }
//    
//    do {
//        try context.save()
//        print("Mock expenses added.")
//    } catch {
//        print("Error saving mock data: \(error)")
//    }
//}
//
//
//extension Decimal {
//    func rounded(scale: Int, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
//        var result = Decimal()
//        var original = self
//        NSDecimalRound(&result, &original, scale, mode)
//        return result
//    }
//}

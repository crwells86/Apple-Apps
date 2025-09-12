import SwiftUI
import StoreKit
import SwiftData
import FinanceKit

struct ExpenseTrackerView: View {
    @Environment(BudgetController.self) private var budget: BudgetController
    @Environment(SubscriptionController.self) var subscriptionController
    @Environment(\.modelContext) private var context
    
    @AppStorage("hasSeenReviewPrompt") private var hasSeenReviewPrompt = false
    
    @Query private var allExpenses: [Expense]
    @Query(filter: #Predicate<Transaction> { $0.isActive }) private var bills: [Transaction]
    
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State private var selectedTimeframe: Timeframe = .week
    @State private var selectedCategoryFilter: Category? = nil //ExpenseCategory? = nil
    @State private var editingExpense: Expense? = nil
    @State private var isSubscribed = false
    
    private var monthlyBudget: Decimal {
        budget.requiredIncome(for: bills, cadence: .monthly)
    }
    
    // Filter expenses by date and optional category
//    private var filteredExpenses: [Expense] {
//        let fromDate = selectedTimeframe.startDate()
//        return allExpenses
//            .filter { $0.date >= fromDate }
//            .filter { expense in
//                guard let category = selectedCategoryFilter else { return true }
//                return expense.category == category
//            }
//    }
    
    @State private var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? .now
    @State private var customEndDate = Date()

    private var filteredExpenses: [Expense] {
        let startDate = selectedTimeframe.startDate(customStart: customStartDate)
        let endDate = selectedTimeframe == .custom ? customEndDate : Date()

        return allExpenses
            .filter { $0.date >= startDate && $0.date <= endDate }
            .filter { expense in
                guard let category = selectedCategoryFilter else { return true }
                return expense.category == category
            }
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
//        let trackingStartDate = Date(timeIntervalSince1970: 1_704_000_000)
        
        switch selectedTimeframe {
        case .hour:
            return monthlyBudget / Decimal(24)
        case .day:
            let days = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            return monthlyBudget / Decimal(days)
        case .week:
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            let weeks = Double(daysInMonth) / 7
            return monthlyBudget / Decimal(weeks)
        case .month:
            return monthlyBudget
        case .year:
            return monthlyBudget * 12
//        case .allTime:
//            let components = calendar.dateComponents([.month], from: trackingStartDate, to: now)
//            let monthsElapsed = max(components.month ?? 1, 1)
//            return monthlyBudget * Decimal(monthsElapsed)
        case .custom:
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            let days = calendar.dateComponents([.day], from: customStartDate, to: customEndDate).day ?? 1
            let normalizedDays = max(min(days, daysInMonth), 1) // Clamp to avoid division by zero
            return monthlyBudget / Decimal(daysInMonth) * Decimal(normalizedDays)
        }
    }
    
    // Grouped by month
    private var groupedExpensesByMonth: [(key: String, value: [Expense])] {
        let calendar = Calendar.current
        let sorted = filteredExpenses.sorted { $0.date > $1.date }
        let grouped = Dictionary(grouping: sorted) { expense -> String in
            let comps = calendar.dateComponents([.year, .month], from: expense.date)
            let date = calendar.date(from: comps)!
            return DateFormatter.monthAndYear.string(from: date)
        }
        return grouped.sorted { lhs, rhs in
            let lDate = DateFormatter.monthAndYear.date(from: lhs.key)!
            let rDate = DateFormatter.monthAndYear.date(from: rhs.key)!
            return lDate > rDate
        }
    }
    
    @State var transactions = [TransactionModel]()
    @State private var weeklySpending: Decimal = 0
    
    @State private var deletedTransactionIDs: Set<String> = []

    @AppStorage("deletedTransactionIDs") private var deletedTransactionIDsData: Data = Data()


    
    @State private var isSelecting = false
    @State private var selectedExpenses: Set<Expense> = []
    
    @Binding var tabSelection: Int
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                BudgetSummaryView(
                    selectedTimeframe: selectedTimeframe,
                    totalAmount: totalAmount,
                    remainingBudget: remainingBudget
                )
                
                // Timeframe picker
                TimeframePickerView(selectedTimeframe: $selectedTimeframe)
                
                if selectedTimeframe == .custom {
                    VStack {
                        DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $customEndDate, in: customStartDate..., displayedComponents: .date)
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }
                
                // Category filter picker
                HStack {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    Spacer()
                    Picker("Category", selection: $selectedCategoryFilter) {
                        Text("All").tag(Optional<Category>.none) //.tag(ExpenseCategory?.none)
                        ForEach(ExpenseCategory.allCases) { category in
                            Text(category.label).tag(ExpenseCategory?.some(category))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                .padding(.horizontal)
                
                
                // List of grouped expenses
                GroupedExpensesListView(
                    groupedExpenses: groupedExpensesByMonth,
                    onDelete: { expense in
                        deletedTransactionIDs.insert(expense.id.uuidString)
                        context.delete(expense)
                        persistDeletedTransactionIDs()
                    },
                    onEdit: { editingExpense = $0 },
                    isSelecting: isSelecting,
                    selectedExpenses: $selectedExpenses
                )
            }
            .navigationTitle("Expenses")
            .padding(.top)
            .overlay(alignment: .bottomTrailing) {
                ExpenseButton(
                    isRecording: $isRecording,
                    showingPaywall: $isSubscribed,
                    speechRecognizer: $speechRecognizer,
                    allExpenses: allExpenses,
                    parseExpense: parseExpense
                )
                .padding()
            }
            .sheet(item: $editingExpense) { expense in
                EditExpenseView(expense: expense)
            }
            .sheet(isPresented: $isSubscribed) {
                PaywallView()
                    .environment(SubscriptionController())
            }
            .onChange(of: allExpenses.count) {
                if allExpenses.count >= 8, !hasSeenReviewPrompt,
                   let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    AppStore.requestReview(in: windowScene)
                    hasSeenReviewPrompt = true
                }
            }
            .toolbar {
                if tabSelection == 2 {
    //                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ToolbarItemGroup {
                        if isSelecting {
                            Button("Delete") {
                                deleteSelectedExpenses()
                            }
                            .disabled(selectedExpenses.isEmpty)
                        } else {
                            Button("Select") {
                                isSelecting = true
                            }
                            
                            Button {
                                sendFeedbackEmail()
                            } label: {
                                Label("Send Feedback", systemImage: "envelope")
                            }
                        }
                    }
                    
                    if isSelecting {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                isSelecting = false
                                selectedExpenses.removeAll()
                            }
                        }
                    }
                }
            }
        }
        .task {
            if subscriptionController.isSubscribed {
                
                deletedTransactionIDs = (try? JSONDecoder().decode(Set<String>.self, from: deletedTransactionIDsData)) ?? []
                
                do {
                    let status = try await FinanceStore.shared.requestAuthorization()
                    
                    if status == .authorized {
                        await fetchFinanceKitTransactions()
                        importFinanceKitTransactionsAsExpenses(transactions)
                    }
                } catch {
                    print("FinanceKit authorization error: \(error)")
                }
            }
        }
    }
    
    private func persistDeletedTransactionIDs() {
        deletedTransactionIDsData = (try? JSONEncoder().encode(deletedTransactionIDs)) ?? Data()
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
    
    private func deleteSelectedExpenses() {
        withAnimation {
            for expense in selectedExpenses {
                deletedTransactionIDs.insert(expense.id.uuidString)
                context.delete(expense)
            }
            persistDeletedTransactionIDs()

            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }

            selectedExpenses.removeAll()
            isSelecting = false
        }
    }

    
    // add FinanceKit functions here
    func updateFinanceKitData() async {
        print("✅ updateFinanceKitData() called") // ✅ PRINT THIS
        await fetchFinanceKitTransactions()
        await calculateWeeklyFinanceKitSpending()
    }
    
    func fetchFinanceKitTransactions() async {
        do {
            print("🔄 Fetching transactions...") // ✅
            let rawTransactions = try await FinanceController.fetchAllTransactions()  // fetchLastWeekOfTransactions()
            print("📦 Raw transactions count: \(rawTransactions.count)") // ✅
            
            for tx in rawTransactions {
                print("🔸 \(tx.transactionDate): \(tx.transactionDescription) - \(tx.transactionAmount.amount)")
            }
            
            transactions = rawTransactions.map(TransactionModel.init)
            
        } catch {
            print("❌ Error fetching transactions: \(error)")
        }
    }
    
    
    func calculateWeeklyFinanceKitSpending() async {
        do {
            weeklySpending = try await FinanceController.calculateWeeklySpendingTotal()
        } catch {
            print("Failed to calculate weekly spending: \(error)")
        }
    }
    
//    func importFinanceKitTransactionsAsExpenses(_ transactions: [TransactionModel]) {
//        let ignoredDescriptions: Set<String> = ["Point Of Sale", "Deposit"]
//        
//        for transaction in transactions {
//            guard !ignoredDescriptions.contains(transaction.description) else { continue }
//            
//            let alreadyExists = allExpenses.contains { $0.id == transaction.id }
//            guard !alreadyExists else { continue }
//            
//            let vendor = transaction.description
//            let inferredCategory = inferCategory(from: vendor)
//            
//            let newExpense = Expense(
//                amount: abs(transaction.amount),
//                vendor: vendor,
//                date: transaction.date,
//                category: inferredCategory
//            )
//            newExpense.id = transaction.id
//            context.insert(newExpense)
//        }
//    }
    
    func importFinanceKitTransactionsAsExpenses(_ transactions: [TransactionModel]) {
        let ignoredDescriptions: Set<String> = ["Point Of Sale", "Deposit"]
        
        for transaction in transactions {
            guard !ignoredDescriptions.contains(transaction.description) else { continue }

            guard !deletedTransactionIDs.contains(transaction.id.uuidString) else { continue }

            let alreadyExists = allExpenses.contains { $0.id == transaction.id }
            guard !alreadyExists else { continue }

            let vendor = transaction.description
//            let inferredCategory = inferCategory(from: vendor)

            let newExpense = Expense(
                amount: abs(transaction.amount),
                vendor: vendor,
                date: transaction.date,
                category: nil //Category(name: "TEST", icon: "testtube.2") //inferredCategory
            )
            newExpense.id = transaction.id
            context.insert(newExpense)
        }
    }

    
    func inferCategory(from description: String) -> ExpenseCategory {
        let lowercaseDescription = description.lowercased()
        
        if lowercaseDescription.contains("uber") || lowercaseDescription.contains("lyft") {
            return .transportation
        } else if lowercaseDescription.contains("starbucks") || lowercaseDescription.contains("coffee") {
            return .food
        } else if lowercaseDescription.contains("netflix") || lowercaseDescription.contains("spotify") {
            return .subscriptions
        } else if lowercaseDescription.contains("apple") || lowercaseDescription.contains("itunes") {
            return .gifts
        } else if lowercaseDescription.contains("grocery") ||
                    lowercaseDescription.contains("supermarket") ||
                    lowercaseDescription.contains("whole foods") ||
                    lowercaseDescription.contains("safeway") ||
                    lowercaseDescription.contains("albertsons") ||
                    lowercaseDescription.contains("winco") ||
                    lowercaseDescription.contains("costco") ||
                    lowercaseDescription.contains("trader joe") ||
                    lowercaseDescription.contains("raley") ||
                    lowercaseDescription.contains("kroger") ||
                    lowercaseDescription.contains("fred meyer") ||
                    lowercaseDescription.contains("smith's") ||
                    lowercaseDescription.contains("food 4 less") ||
                    lowercaseDescription.contains("gelson") ||
                    lowercaseDescription.contains("vons") ||
                    lowercaseDescription.contains("wegmans") ||
                    lowercaseDescription.contains("publix") ||
                    lowercaseDescription.contains("giant") ||
                    lowercaseDescription.contains("meijer") ||
                    lowercaseDescription.contains("piggly wiggly") {
            return .food
        } else if lowercaseDescription.contains("shell") || lowercaseDescription.contains("chevron") {
            return .transportation
        } else if lowercaseDescription.contains("walgreens") || lowercaseDescription.contains("pharmacy") {
            return .healthcare
        } else {
            return .miscellaneous
        }
    }
}

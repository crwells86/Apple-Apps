import SwiftUI
import SwiftData

// MARK: - Expense Model
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

func parseExpense(from text: String) -> Expense? {
    let lowercased = text.lowercased()
    
    // Step 1: Extract amount phrase (digits or words)
    guard let amountPhrase = extractAmountPhrase(from: lowercased) else {
        return nil
    }
    
    // Step 2: Convert amount phrase to Decimal
    guard let amount = convertToDecimal(amountPhrase) else {
        return nil
    }
    
    // Step 3: Extract vendor/category around amountPhrase
    let vendor = extractVendor(around: amountPhrase, in: lowercased) ?? "Misc"
    
    return Expense(amount: amount, vendor: vendor.capitalized)
}

// MARK: - Helpers

func extractAmountPhrase(from text: String) -> String? {
    // Patterns to catch digits with optional $ and cents, or number words + bucks/dollars
    let patterns = [
        #"\$\d+(\.\d{1,2})?"#,                  // $50, $5.60
        #"\d+(\.\d{1,2})?\s?(bucks|dollars)?"#, // 50, 5.60 bucks, 50 dollars
        #"(\w+\s)?(bucks|dollars|cents)"#      // twenty bucks, five dollars, ninety-nine cents
    ]
    
    for pattern in patterns {
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
    }
    return nil
}

func convertToDecimal(_ phrase: String) -> Decimal? {
    let cleaned = phrase
        .replacingOccurrences(of: "$", with: "")
        .replacingOccurrences(of: "bucks", with: "")
        .replacingOccurrences(of: "dollars", with: "")
        .replacingOccurrences(of: "cents", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Try to parse digits directly
    if let decimal = Decimal(string: cleaned) {
        return decimal
    }
    
    // Else try to parse written number words
    return wordsToDecimal(cleaned)
}

func extractVendor(around amountPhrase: String, in text: String) -> String? {
    // Break text into words
    let words = text.components(separatedBy: .whitespacesAndNewlines)
    
    // Find index where amountPhrase appears (approximate)
    guard let idx = words.firstIndex(where: { $0.contains(amountPhrase) || amountPhrase.contains($0) }) else {
        return nil
    }
    
    // Common filler words to ignore as vendor candidates
    let fillerWords: Set<String> = ["i", "spent", "grabbed", "dropped", "paid", "on", "for", "at", "the", "a"]
    
    // Search up to 3 words before amountPhrase for vendor
    for offset in 1...3 {
        let vendorIndex = idx - offset
        if vendorIndex >= 0 {
            let candidate = words[vendorIndex].trimmingCharacters(in: .punctuationCharacters)
            if !fillerWords.contains(candidate) && !candidate.isEmpty {
                return candidate
            }
        }
    }
    
    // If no vendor found before, try after
    for offset in 1...3 {
        let vendorIndex = idx + offset
        if vendorIndex < words.count {
            let candidate = words[vendorIndex].trimmingCharacters(in: .punctuationCharacters)
            if !fillerWords.contains(candidate) && !candidate.isEmpty {
                return candidate
            }
        }
    }
    
    // Fallback
    return nil
}

// Simple words to decimal converter for 0–99 (expand as needed)
func wordsToDecimal(_ words: String) -> Decimal? {
    let numberWords: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4,
        "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
        "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
        "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17,
        "eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30,
        "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70,
        "eighty": 80, "ninety": 90
    ]
    
    let parts = words.components(separatedBy: .whitespaces)
    var total = 0
    for part in parts {
        if let val = numberWords[part] {
            total += val
        }
    }
    
    return total > 0 ? Decimal(total) : nil
}


struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @Bindable var expense: Expense
    var isNew: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Vendor", text: $expense.vendor)
                TextField("Amount", value: $expense.amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                DatePicker("Date", selection: $expense.date, displayedComponents: .date)
            }
            .navigationTitle(isNew ? "Add Expense" : "Edit Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isNew {
                            context.insert(expense)
                        }
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}



struct EditBudgetView: View {
    @Binding var budget: Double
    @Environment(\.dismiss) private var dismiss
    @State private var input: String
    
    init(budget: Binding<Double>) {
        self._budget = budget
        self._input = State(initialValue: String(format: "%.2f", budget.wrappedValue))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Weekly Budget", text: $input)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Edit Monthly Budget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let newValue = Double(input) {
                            budget = newValue
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}


// MARK: - Timeframe Enum
enum Timeframe: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var id: String { rawValue }
    
    func startDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        case .month:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        case .year:
            return calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
        }
    }
}


// MARK: - Main View
struct ExpenseTrackerView: View {
    @Environment(\.modelContext) private var context
    @Query private var allExpenses: [Expense]
    @State private var selectedTimeframe: Timeframe = .week
    @State private var editingExpense: Expense? = nil
    @State private var showingAddExpenseSheet = false
    
    @AppStorage("monthlyBudget") private var monthlyBudgetRaw: Double = 0
    @State private var showingBudgetEditor = false
    
    @Binding var tabSelection: Int
    
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
                BudgetSummaryView(
                    selectedTimeframe: selectedTimeframe,
                    totalAmount: totalAmount,
                    remainingBudget: remainingBudget
                )
                
                TimeframePickerView(selectedTimeframe: $selectedTimeframe)
                
                GroupedExpensesListView(
                    groupedExpenses: groupedExpensesByMonth,
                    onDelete: { context.delete($0) },
                    onEdit: { editingExpense = $0 }
                )
                
            }
            .toolbar {
                if tabSelection == 2 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddExpenseSheet.toggle()
                        } label: {
                            Label("Add Expense", systemImage: "plus")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingBudgetEditor = true
                        } label: {
                            Label("Edit Budget", systemImage: "dollarsign.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingBudgetEditor) {
                EditBudgetView(budget: $monthlyBudgetRaw)
            }
            .sheet(item: $editingExpense) { expense in
                EditExpenseView(expense: expense, isNew: false)
            }
            .sheet(isPresented: $showingAddExpenseSheet) {
                EditExpenseView(expense: Expense(amount: 0.0, vendor: "", date: .now), isNew: true)
            }
        }
    }
}




struct BudgetSummaryView: View {
    let selectedTimeframe: Timeframe
    let totalAmount: Decimal
    let remainingBudget: Decimal
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Spent This \(selectedTimeframe.rawValue)")
                .font(.caption)
                .foregroundColor(.gray)
            Text(totalAmount, format: .currency(code: "USD"))
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.primary)
            Text("Remaining Budget: \(remainingBudget, format: .currency(code: "USD"))")
                .font(.caption)
                .foregroundColor(remainingBudget < 0 ? .red : .green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct TimeframePickerView: View {
    @Binding var selectedTimeframe: Timeframe
    
    var body: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

struct GroupedExpensesListView: View {
    let groupedExpenses: [(key: String, value: [Expense])]
    let onDelete: (Expense) -> Void
    let onEdit: (Expense) -> Void
    
    var body: some View {
        List {
            ForEach(groupedExpenses, id: \.key) { month, expenses in
                let totalForMonth = expenses.reduce(Decimal(0)) { $0 + $1.amount }
                
                Section(header: Text("\(month) – \(totalForMonth, format: .currency(code: "USD"))")
                    .font(.headline)) {
                        
                        ForEach(expenses) { expense in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(expense.vendor)
                                    .font(.headline)
                                Text(expense.amount, format: .currency(code: "USD"))
                                Text(expense.date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    onDelete(expense)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    onEdit(expense)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                            }
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Month-Year DateFormatter
extension DateFormatter {
    static let monthAndYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

import SwiftUI
import SwiftData

struct IncomeTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var incomes: [Income]
    
    @State private var source = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var frequency: Frequency = .weekly
    
    @State private var searchText: String = ""
    @State private var amountError: String? = nil
    @State private var isPresentingAddIncome: Bool = false
    
    private var currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f
    }()
    
    @State private var editingIncome: Income? = nil
    @Binding var tabSelection: Int
    @FocusState var isInputActive: Bool
    
    init(tabSelection: Binding<Int>) {
        self._tabSelection = tabSelection
    }
    
    // Derived data
    private var filteredIncomes: [Income] {
        let base: [Income]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            base = incomes
        } else {
            let q = searchText.lowercased()
            base = incomes.filter { $0.source.lowercased().contains(q) }
        }
        return base.sorted { $0.date > $1.date }
    }
    
    private var totalsThisMonth: Decimal {
        let cal = Calendar.current
        return filteredIncomes.reduce(0 as Decimal) { partial, inc in
            if cal.isDate(inc.date, equalTo: Date(), toGranularity: .month) {
                return partial + inc.amount
            }
            return partial
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Summary")) {
                    HStack {
                        Text("This Month")
                        Spacer()
                        Text(NSNumber(value: (totalsThisMonth as NSDecimalNumber).doubleValue), formatter: currencyFormatter)
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("All Time")
                        Spacer()
                        let allTotal: Decimal = filteredIncomes.reduce(0 as Decimal) { $0 + $1.amount }
                        Text(NSNumber(value: (allTotal as NSDecimalNumber).doubleValue), formatter: currencyFormatter)
                            .fontWeight(.semibold)
                    }
                }
                
                Section(header: Text("Logged Incomes")) {
                    List {
                        ForEach(filteredIncomes) { income in
                            VStack(alignment: .leading) {
                                Text(income.source).font(.headline)
                                Text("$\(income.amount, format: .number)").foregroundColor(.secondary)
                                Text(income.date, style: .date).font(.footnote).foregroundColor(.gray)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteIncome(income)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    editingIncome = income
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete(perform: deleteIncomeAt)
                    }
                }
            }
            .navigationTitle("Income")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search source")
            .toolbar {
                if tabSelection == 4 {
                    ToolbarItemGroup {
                        Button {
                            isPresentingAddIncome = true
                        } label: {
                            Label("Add Income", systemImage: "plus")
                        }
                        
                        EditButton()
                        
                        Button {
                            sendFeedbackEmail()
                        } label: {
                            Label("Send Feedback", systemImage: "envelope")
                        }
                    }
                }
            }
            .sheet(item: $editingIncome) { income in
                EditIncomeSheet(income: income)
            }
            .sheet(isPresented: $isPresentingAddIncome) {
                AddIncomeSheet(
                    source: $source,
                    amount: $amount,
                    date: $date,
                    frequency: $frequency,
                    amountError: $amountError,
                    isInputActive: _isInputActive,
                    onSave: {
                        saveIncome()
                        isPresentingAddIncome = false
                    },
                    onCancel: {
                        isPresentingAddIncome = false
                    }
                )
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
    
    private func saveIncome() {
        guard let decimalAmount = Decimal(string: amount) else { return }
        let newIncome = Income(source: source, amount: decimalAmount, date: date, frequency: frequency)
        context.insert(newIncome)
        amountError = nil
        
        source = ""
        amount = ""
        date = .now
    }
    
    private func deleteIncome(_ income: Income) {
        context.delete(income)
    }
    
    private func deleteIncomeAt(_ offsets: IndexSet) {
        for index in offsets {
            context.delete(incomes[index])
        }
    }
}



struct EditIncomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @Bindable var income: Income
    @FocusState var isInputActive: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Source", text: $income.source)
                TextField("Amount", value: $income.amount, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($isInputActive)
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            HStack {
                                Spacer()
                                
                                Button("Done") {
                                    isInputActive = false
                                }
                            }
                            .padding(.trailing)
                        }
                    }
                DatePicker("Date", selection: $income.date, displayedComponents: .date)
                Picker("Frequency", selection: Binding(
                    get: { Frequency(rawValue: income.frequencyRaw) ?? .variable },
                    set: { income.frequencyRaw = $0.rawValue }
                )) {
                    ForEach(Frequency.allCases, id: \.self) {
                        Text($0.rawValue.capitalized)
                    }
                }
            }
            .navigationTitle("Edit Income")
            .padding(.top)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddIncomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var source: String
    @Binding var amount: String
    @Binding var date: Date
    @Binding var frequency: Frequency
    @Binding var amountError: String?
    @FocusState var isInputActive: Bool
    
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Source (e.g. Job, Freelance)", text: $source)
                if source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Please enter a source")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                    .focused($isInputActive)
                    .onChange(of: amount) { _, newValue in
                        if newValue.isEmpty {
                            amountError = "Enter an amount"
                        } else if Decimal(string: newValue) == nil {
                            amountError = "Enter a valid number"
                        } else {
                            amountError = nil
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            HStack {
                                Spacer()
                                Button("Done") { isInputActive = false }
                            }
                            .padding(.trailing)
                        }
                    }
                if let amountError, !amount.isEmpty || amountError == "Enter an amount" {
                    Text(amountError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
                
                Picker("Frequency", selection: $frequency) {
                    ForEach(Frequency.allCases, id: \.self) {
                        Text($0.rawValue.capitalized)
                    }
                }
            }
            .navigationTitle("New Income")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(source.isEmpty || Decimal(string: amount) == nil)
                }
            }
        }
    }
}

import SwiftUI
import SwiftData

struct IncomeTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var incomes: [Income]
    
    @State private var source = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var frequency: Frequency = .weekly
    
    @State private var editingIncome: Income? = nil
    @Binding var tabSelection: Int
    @FocusState var isInputActive: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("New Income")) {
                    TextField("Source (e.g. Job, Freelance)", text: $source)
                    TextField("Amount", text: $amount)
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
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Frequency.allCases, id: \.self) {
                            Text($0.rawValue.capitalized)
                        }
                    }
                    
                    Button("Save Income") {
                        saveIncome()
                    }
                    .disabled(source.isEmpty || Decimal(string: amount) == nil)
                }
                
                Section(header: Text("Logged Incomes")) {
                    List {
                        ForEach(incomes) { income in
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
            .toolbar {
                if tabSelection == 4 {
                    ToolbarItemGroup {
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
                        // Data is already bound and updated via @Bindable
                        dismiss()
                    }
                }
            }
        }
    }
}

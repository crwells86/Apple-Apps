import SwiftUI
import SwiftData

struct IncomeTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var incomes: [Income]
    
    @State private var source = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var frequency: Frequency = .weekly
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("New Income")) {
                    TextField("Source (e.g. Job, Freelance)", text: $source)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
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
                    ForEach(incomes) { income in
                        VStack(alignment: .leading) {
                            Text(income.source).font(.headline)
                            Text("$\(income.amount, format: .number)").foregroundColor(.secondary)
                            Text(income.date, style: .date).font(.footnote).foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Income")
        }
    }
    
    private func saveIncome() {
        guard let decimalAmount = Decimal(string: amount) else { return }
        let newIncome = Income(source: source, amount: decimalAmount, date: date)
        context.insert(newIncome)
        
        source = ""
        amount = ""
        date = .now
    }
}

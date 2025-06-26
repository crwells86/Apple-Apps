import SwiftUI

struct EditExpenseView: View {
    @Bindable var expense: Expense
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Vendor", text: $expense.vendor)
                TextField("Amount", value: $expense.amount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                DatePicker("Date", selection: $expense.date, displayedComponents: .date)
                Picker("Category", selection: $expense.category) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Text(category.label)
                            .tag(category)
                    }
                }
            }
            .navigationTitle("Edit Expense")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EditExpenseView(expense: Expense(amount: Decimal(87.65), vendor: "Safeway", date: .now))
}

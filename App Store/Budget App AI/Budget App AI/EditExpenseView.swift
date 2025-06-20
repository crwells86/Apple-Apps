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

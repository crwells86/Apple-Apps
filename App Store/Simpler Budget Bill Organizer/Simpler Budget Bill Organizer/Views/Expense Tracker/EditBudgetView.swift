import SwiftUI

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

#Preview {
    EditBudgetView(budget: .constant(6087))
}

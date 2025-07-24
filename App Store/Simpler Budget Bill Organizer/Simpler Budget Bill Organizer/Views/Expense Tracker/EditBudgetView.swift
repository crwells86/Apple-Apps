import SwiftUI

struct EditBudgetView: View {
    @Binding var budget: Double
    @Environment(\.dismiss) private var dismiss
    @State private var input: String
    @FocusState var isInputActive: Bool
    
    init(budget: Binding<Double>) {
        self._budget = budget
        self._input = State(initialValue: String(format: "%.2f", budget.wrappedValue))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Weekly Budget", text: $input)
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

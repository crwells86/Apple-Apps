import SwiftUI
import SwiftData

struct EditExpenseView: View {
    @Bindable var expense: Expense
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var showAddCategory = false
    @FocusState var isInputActive: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Vendor", text: $expense.vendor)
                TextField("Amount", value: $expense.amount, format: .currency(code: "USD"))
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
                DatePicker("Date", selection: $expense.date, displayedComponents: .date)
                
//                Picker("Category", selection: $expense.category) {
//                    ForEach(ExpenseCategory.allCases) { category in
//                        Text(category.label)
//                            .tag(category)
//                    }
//                }
                // Category Picker
                Picker(selection: $expense.category) {
                    Text("None").tag(Optional<Category>.none)
                    
                    ForEach(categories) { category in
                        Label {
                            Text(category.name)
                        } icon: {
                            iconView(for: category.icon)
                        }
                        .tag(Optional(category))
                    }
                } label: {
                    if let selectedCategory = expense.category {
                        Label {
                            Text(selectedCategory.name)
                        } icon: {
                            iconView(for: selectedCategory.icon)
                        }
                    } else {
                        Text("Select Category")
                    }
                }
                .pickerStyle(.navigationLink)
                
                
                Button("Add Category") {
                    showAddCategory = true
                }
                .sheet(isPresented: $showAddCategory) {
                    AddCategorySheet { newCategory in
                        expense.category = newCategory
                        showAddCategory = false
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
    
    @ViewBuilder
    func iconView(for icon: String) -> some View {
        if UIImage(systemName: icon) != nil {
            Image(systemName: icon)
        } else {
            Text(icon)
        }
    }
}

#Preview {
    EditExpenseView(expense: Expense(amount: Decimal(87.65), vendor: "Safeway", date: .now))
}

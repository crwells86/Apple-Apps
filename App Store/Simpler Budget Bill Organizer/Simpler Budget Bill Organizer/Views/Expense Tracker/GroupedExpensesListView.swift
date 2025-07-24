import SwiftUI

struct GroupedExpensesListView: View {
    let groupedExpenses: [(key: String, value: [Expense])]
    let onDelete: (Expense) -> Void
    let onEdit: (Expense) -> Void
    
    // New
    let isSelecting: Bool
    @Binding var selectedExpenses: Set<Expense>
    
    var body: some View {
        List {
            ForEach(groupedExpenses, id: \.key) { month, expenses in
                let totalForMonth = expenses.reduce(Decimal(0)) { $0 + $1.amount }
                
                Section(header: Text("\(month) – \(totalForMonth, format: .currency(code: "USD"))")
                    .font(.headline)) {
                        
                        ForEach(expenses) { expense in
                            HStack(alignment: .top) {
                                if isSelecting {
                                    Image(systemName: selectedExpenses.contains(expense) ? "checkmark.circle.fill" : "circle")
                                        .onTapGesture {
                                            toggleSelection(expense)
                                        }
                                }
                                
                                if let icon = expense.category?.icon {
                                    iconView(for: icon)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(expense.vendor)
                                        .font(.headline)
                                    
                                    if let category = expense.category {
                                        Text(category.name)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(expense.amount, format: .currency(code: "USD"))
                                    
                                    Text(expense.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle()) // Makes entire row tappable
                            .onTapGesture {
                                if isSelecting {
                                    toggleSelection(expense)
                                } else {
                                    onEdit(expense)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if !isSelecting {
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
        }
    }
    
    private func toggleSelection(_ expense: Expense) {
        if selectedExpenses.contains(expense) {
            selectedExpenses.remove(expense)
        } else {
            selectedExpenses.insert(expense)
        }
    }
    
    @ViewBuilder
    private func iconView(for icon: String) -> some View {
        if UIImage(systemName: icon) != nil {
            Image(systemName: icon)
                .foregroundStyle(.accent)
        } else {
            Text(icon)
                .font(.title3)
        }
    }
}

import SwiftUI

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

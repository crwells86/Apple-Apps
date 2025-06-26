import SwiftUI
import SwiftData

struct BillsListView: View {
    enum BillSortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case amount = "Amount"
        case name = "Name"
        case paidStatus = "Paid"
    }
    
    @Binding var isAddTransactionsShowing: Bool
    @Binding var draftBill: Transaction
    @Binding var tabSelection: Int
    
    @Query(filter: #Predicate<Transaction> { $0.isActive }) private var bills: [Transaction]
    @Environment(BudgetController.self) private var budget: BudgetController
    
    @Environment(\.modelContext) private var context
    
    @State private var selectedSort: BillSortOption = .dueDate
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Required income to cover bills") {
                    let chartData = BudgetCadence.allCases.map { cadence in
                        let decimalValue = budget.requiredIncome(for: bills, cadence: cadence)
                        let doubleValue = (decimalValue as NSDecimalNumber).doubleValue
                        return BillSegment(
                            label: cadence.rawValue.capitalized,
                            value: doubleValue
                        )
                    }
                    BillsBarChart(data: chartData)
                }
                
                Picker("Sort by", selection: $selectedSort) {
                    ForEach(BillSortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                
                ForEach(sortedBills) { bill in
                    BillRowView(bill: bill)
                        .environment(budget)
                        .swipeActions {
                            Button(role: .destructive) {
                                context.delete(bill)
                                try? context.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                draftBill = bill
                                isAddTransactionsShowing.toggle()
                            } label: {
                                Label("Edit", systemImage: "square.and.pencil")
                            }
                            .tint(.indigo)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                bill.isPaid.toggle()
                                try? context.save()
                            } label: {
                                Label("Paid", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                }
            }
            .sheet(isPresented: $isAddTransactionsShowing) {
                NavigationStack {
                    TransactionFormView(bill: $draftBill) {
                        context.insert(draftBill)
                        try? context.save()
                        isAddTransactionsShowing.toggle()
                    } onCancel: {
                        isAddTransactionsShowing.toggle()
                    }
                }
            }
            .navigationTitle("Cost of Living")
            .toolbar {
                if tabSelection == 3 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            draftBill = Transaction()
                            isAddTransactionsShowing.toggle()
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
            }
            .onAppear {
                budget.scheduleReminders(for: bills)
            }
        }
    }
    
    private var sortedBills: [Transaction] {
        switch selectedSort {
        case .dueDate:
            return bills.sorted {
                ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
            }
        case .amount:
            return bills.sorted { $0.amount > $1.amount }
        case .name:
            return bills.sorted { $0.name.localizedLowercase < $1.name.localizedLowercase }
        case .paidStatus:
            return bills.sorted { $0.isPaid && !$1.isPaid }
        }
    }
}

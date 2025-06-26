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
    
    @State private var isEditing = false
    //    @Environment(\.editMode) private var editMode
    
    @State private var selectedBills = Set<UUID>() // Use UUID or the Transaction itself if Hashable
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationStack {
            //            Form {
            List(selection: $selectedBills) {
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
                
                Section {
                    Picker("Sort by", selection: $selectedSort) {
                        ForEach(BillSortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
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
                                    
                                    markBillAsPaid(bill)
                                } label: {
                                    Label("Paid", systemImage: "checkmark.circle")
                                }
                                .tint(.green)
                            }
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
            .environment(\.editMode, $editMode)
            .toolbar {
                if tabSelection == 3 {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            withAnimation {
                                isEditing.toggle()
                                editMode = isEditing ? .active : .inactive
                                if !isEditing {
                                    selectedBills.removeAll()
                                }
                            }
                        } label: {
                            Text(isEditing ? "Done" : "Edit")
                        }
                        
                        if isEditing && !selectedBills.isEmpty {
                            Button {
                                markSelectedBillsPaid()
                            } label: {
                                Text("Mark Paid")
                            }
                            
                            Button(role: .destructive) {
                                deleteSelectedBills()
                            } label: {
                                Text("Delete Selected")
                            }
                        }
                        
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
    
    func markSelectedBillsPaid() {
        for billID in selectedBills {
            if let bill = bills.first(where: { $0.id == billID }) {
                bill.isPaid = true
                markBillAsPaid(bill)
            }
        }
        try? context.save()
        selectedBills.removeAll()
    }
    
    private func markBillAsPaid(_ bill: Transaction) {
            let expense = Expense(amount: Decimal(bill.amount), vendor: bill.name)
        
            context.insert(expense)

            do {
                try context.save()
                // Optionally update BudgetController state if needed
                // e.g., budget.updateTotals() or similar
            } catch {
                print("Failed to save expense: \(error)")
            }
        }
    
    func deleteSelectedBills() {
        for billID in selectedBills {
            if let bill = bills.first(where: { $0.id == billID }) {
                context.delete(bill)
            }
        }
        try? context.save()
        selectedBills.removeAll()
    }
}

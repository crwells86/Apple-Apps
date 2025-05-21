import SwiftUI
import SwiftData

struct BillsListView: View {
    enum BillSortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case amount = "Amount"
        case name = "Name"
        case paidStatus = "Paid"
    }
    
    @Bindable var controller: FinanceController
    @Binding var isAddTransactionsShowing: Bool
    @Binding var draftBill: Transaction
    
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Transaction> { $0.isActive }) var bills: [Transaction]
    
    @State private var selectedSort: BillSortOption = .dueDate
    
    var body: some View {
        NavigationStack {
            Form {
                let annually = controller.neededAnnual(from: bills)
                let hours = controller.workSchedule.hoursPerYear
                
                let chartData = [
                    BillSegment(label: "Annually", value: annually),
                    BillSegment(label: "Monthly", value: annually / 12),
                    BillSegment(label: "Weekly", value: annually / 52),
                    BillSegment(label: "Daily", value: annually / 364),
                    BillSegment(label: "Hourly", value: annually / hours)
                ]
                
                Section("Needed to Cover Bills") {
                    BillsBarChart(data: chartData)
                    Picker("Work Schedule", selection: $controller.workSchedule) {
                        ForEach(WorkSchedule.allCases) { schedule in
                            Text(schedule.label).tag(schedule)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                let sortedBills: [Transaction] = {
                    switch selectedSort {
                    case .dueDate:
                        return bills.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
                    case .amount:
                        return bills.sorted { $0.amount > $1.amount }
                    case .name:
                        return bills.sorted { $0.name.lowercased() < $1.name.lowercased() }
                    case .paidStatus:
                        return bills.sorted { $0.isPaid && !$1.isPaid }
                    }
                }()
                
                Picker("Sort by", selection: $selectedSort) {
                    ForEach(BillSortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                
                ForEach(sortedBills) { bill in
                    BillRowView(bill: bill)
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
                        
                        isAddTransactionsShowing.toggle()
                    } onCancel: {
                        isAddTransactionsShowing.toggle()
                    }
                }
            }
        }
        .navigationTitle("Cost of Living")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    draftBill = Transaction()
                    isAddTransactionsShowing.toggle()
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .onAppear {
            controller.requestNotificationPermission()
        }
    }
}

#Preview {
    @Previewable @State var controller = FinanceController()
    @Previewable @State var isAddTransactionsShowing = false
    @Previewable @State var draftBill = Transaction()
    
    BillsListView(
        controller: controller,
        isAddTransactionsShowing: $isAddTransactionsShowing,
        draftBill: $draftBill
    )
}

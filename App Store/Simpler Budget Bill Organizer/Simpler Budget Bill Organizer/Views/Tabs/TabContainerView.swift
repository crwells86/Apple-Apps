import SwiftUI

struct TabContainerView: View {
    @State private var tabSelection = 1
    @State private var isShowingSheet = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $tabSelection) {
                Tab("Summary", systemImage: "dollarsign.gauge.chart.leftthird.topthird.rightthird", value: 1) {
                    NavigationStack { Text("Summary").navigationTitle("Summary") }
                }
                
                Tab("Transactions", systemImage: "list.bullet.rectangle", value: 2) {
                    NavigationStack { AddTransactionView() }
                }
                
                Tab("Assistant", systemImage: "sparkles", value: 4) {
                    NavigationStack { Text("Assistant").navigationTitle("Assistant") }
                }
                
                Tab("Plans", systemImage: "pencil.and.list.clipboard", value: 5) {
                    NavigationStack { PlansView() }
                }
            }
            
            if tabSelection != 4 {
                FloatingActionButton {
                    isShowingSheet = true
                }
            }
        }
        .sheet(isPresented: $isShowingSheet) {
            Text("Sheet content here")
                .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    TabContainerView()
}

struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor, in: Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 80) // clears the tab bar
    }
}

enum TransactionType2 {
    case income
    case expense
}

struct AddTransactionView: View {
    @State private var type: TransactionType2 = .expense
    @State private var amount: Double = 0
    
    var body: some View {
        Form {
            Picker("Type", selection: $type) {
                Text("Expense").tag(TransactionType2.expense)
                Text("Income").tag(TransactionType2.income)
            }
            
            TextField("Amount", value: $amount, format: .currency(code: "USD"))
        }
    }
}

import SwiftUI

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

#Preview {
    AddTransactionView()
}


enum TransactionType2 {
    case income
    case expense
}

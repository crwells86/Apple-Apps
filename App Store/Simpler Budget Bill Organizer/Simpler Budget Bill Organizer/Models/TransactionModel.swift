import Foundation
import FinanceKit

struct TransactionModel: Identifiable {
    var id: UUID
    var description: String
    var amount: Decimal
    var currency: String
    var date: Date
    
    init(id: UUID, description: String, amount: Decimal, currency: String, date: Date) {
        self.id = id
        self.description = description
        self.amount = amount
        self.currency = currency
        self.date = date
    }
    
    init(transaction: FinanceKit.Transaction) {
        id = transaction.id
        description = transaction.transactionDescription
        amount = transaction.transactionAmount.amount
        currency = transaction.transactionAmount.currencyCode
        date = transaction.transactionDate
    }
}

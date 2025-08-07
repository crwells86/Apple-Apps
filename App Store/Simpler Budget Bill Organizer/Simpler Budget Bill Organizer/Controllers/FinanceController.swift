import Foundation
import FinanceKit

struct FinanceController {
    
    // MARK: - Weekly Spending Total
    static func calculateWeeklySpendingTotal() async throws -> Decimal {
        let accounts = try await FinanceStore.shared.accounts(query: AccountQuery())
        var total: Decimal = 0
        
        for account in accounts {
            total += try await calculateTotal(for: account)
        }
        
        // Spending is represented as negative values
        return -total
    }
    
    static func calculateTotal(for account: Account) async throws -> Decimal {
        let startOfWeek = Date.startOfWeek
        
        let transactionQuery = TransactionQuery(
            predicate: #Predicate<FinanceKit.Transaction> {
                $0.accountID == account.id && $0.transactionDate > startOfWeek
            }
        )
        
        let transactions = try await FinanceStore.shared.transactions(query: transactionQuery)
        
        let filteredTransactions = getSpendingTransactions(for: transactions)
        
        if account.assetAccount != nil {
            return totalForAssetTransactions(filteredTransactions)
        } else if account.liabilityAccount != nil {
            return totalForLiabilityTransactions(filteredTransactions)
        } else {
            return 0
        }
    }
    
    static func getSpendingTransactions(for transactions: [FinanceKit.Transaction]) -> [FinanceKit.Transaction] {
        let allowedTypes: [TransactionType] = [.check, .pointOfSale, .unknown]
        
        return transactions.filter {
            allowedTypes.contains($0.transactionType)
        }
    }
    
    static func totalForAssetTransactions(_ transactions: [FinanceKit.Transaction]) -> Decimal {
        transactions.reduce(0) { partialResult, transaction in
            let amount = transaction.transactionAmount.amount
            switch transaction.creditDebitIndicator {
            case .credit:
                return partialResult + amount
            case .debit:
                return partialResult - amount
            default:
                return partialResult
            }
        }
    }
    
    static func totalForLiabilityTransactions(_ transactions: [FinanceKit.Transaction]) -> Decimal {
        transactions.reduce(0) { partialResult, transaction in
            let amount = transaction.transactionAmount.amount
            switch transaction.creditDebitIndicator {
            case .credit:
                return partialResult - amount
            case .debit:
                return partialResult + amount
            default:
                return partialResult
            }
        }
    }
    
    // MARK: - Fetch Transactions
    static func fetchLastWeekOfTransactions() async throws -> [FinanceKit.Transaction] {
        let startOfWeek = Date.startOfWeek
        
        return try await FinanceStore.shared.transactions(
            query: TransactionQuery(
                sortDescriptors: [.init(\.transactionDate, order: .reverse)],
                predicate: #Predicate<FinanceKit.Transaction> {
                    $0.transactionDate > startOfWeek
                }
            )
        )
    }
    
    static func fetchAllTransactions() async throws -> [FinanceKit.Transaction] {
        return try await FinanceStore.shared.transactions(
            query: TransactionQuery(
                sortDescriptors: [.init(\.transactionDate, order: .reverse)]
                // No predicate = fetch everything available
            )
        )
    }
}

import Foundation

extension Category {
    var totalSpending: Decimal {
        let expensesTotal = expenses
            .filter(\.isActive)
            .reduce(Decimal(0)) { $0 + $1.amount }
        
        let transactionsTotal = transactions
            .filter(\.isActive)
            .reduce(Decimal(0)) { $0 + Decimal($1.amount) }
        
        return expensesTotal + transactionsTotal
    }
}

func spendingByCategory(from categories: [Category]) -> [CategorySpending] {
    categories
        .filter { $0.totalSpending > 0 }
        .map {
            CategorySpending(
                id: $0.id,
                name: $0.name,
                icon: $0.icon,
                total: $0.totalSpending
            )
        }
}

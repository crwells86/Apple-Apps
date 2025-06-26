import Foundation

struct AppleCardAccount: Identifiable {
    let id: UUID
    let displayName: String
    let accountDescription: String
    let institutionName: String
    let currencyCode: String
    let creditInformation: CreditInformation
    let openingDate: Date?
}

struct CreditInformation {
    let creditLimit: CurrencyAmount?
    let nextPaymentDueDate: Date
    let minimumNextPaymentAmount: CurrencyAmount?
    let overduePaymentAmount: CurrencyAmount?
}

struct CurrencyAmount {
    let amount: Decimal
    let currencyCode: String
}

import Foundation

extension Decimal {
    func formatCurrency(for currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }
    
    func formatCompactCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.usesSignificantDigits = true
        formatter.maximumSignificantDigits = 3
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }
}

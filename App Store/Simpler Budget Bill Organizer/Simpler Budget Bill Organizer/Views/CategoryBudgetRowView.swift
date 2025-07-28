import SwiftUI

struct CategoryBudgetRowView: View {
    let category: Category
    
    var body: some View {
        let limit = category.limit ?? 0
        let spent = category.totalSpending
        let remaining = limit - spent
        let isUnder = remaining >= 0
        
        let percentage = min((spent as NSDecimalNumber).doubleValue / (limit as NSDecimalNumber).doubleValue, 1.0)
        let color: Color = {
            if !isUnder { return .red }
            else if percentage > 0.8 { return .yellow }
            else { return .green }
        }()
        
        HStack(spacing: 16) {
            IconView(icon: category.icon)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                
                Text("Spent: \(formatCurrency(spent)) of \(formatCurrency(limit))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ProgressView(value: percentage)
                    .tint(color)
            }
            
            Spacer()
            
            Text(isUnder ? "✓" : "⚠️")
                .font(.title3)
                .foregroundStyle(color)
        }
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

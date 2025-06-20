import SwiftUI

struct BudgetSummaryView: View {
    let selectedTimeframe: Timeframe
    let totalAmount: Decimal
    let remainingBudget: Decimal
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Spent This \(selectedTimeframe.rawValue)")
                .font(.caption)
                .foregroundColor(.gray)
            Text(totalAmount, format: .currency(code: "USD"))
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.primary)
            Text("Remaining Budget: \(remainingBudget, format: .currency(code: "USD"))")
                .font(.caption)
                .foregroundColor(remainingBudget < 0 ? .red : .green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    BudgetSummaryView(selectedTimeframe: Timeframe.day, totalAmount: Decimal(1420), remainingBudget: Decimal(4667))
        .padding()
}

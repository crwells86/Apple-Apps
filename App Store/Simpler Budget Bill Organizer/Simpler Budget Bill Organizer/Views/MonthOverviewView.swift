import SwiftUI

struct MonthOverviewView: View {
    let remaining: Decimal
    let budgeted: Decimal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(remaining, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                 //format: .currency(code: "USD"))
                .font(.system(size: 42, weight: .bold))
            
            Text("Out of \(budgeted, format: .currency(code: Locale.current.currency?.identifier ?? "USD")) budgeted")
    // format: .currency(code: "USD")) budgeted")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

import SwiftUI

struct MetricCardView: View {
    let title: String
    let value: Decimal
    let color: Color
    let chartData: [Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                //                Image(systemName: "chevron.right")
                //                    .font(.caption)
                //                    .foregroundColor(.secondary)
            }
            
            Text(value, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                 // format: .currency(code: "USD"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            
            BarChart(data: chartData, color: color)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color(.secondarySystemBackground)))
    }
}

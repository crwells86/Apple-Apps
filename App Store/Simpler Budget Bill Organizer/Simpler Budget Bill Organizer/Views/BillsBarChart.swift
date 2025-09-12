import SwiftUI
import Charts

struct BillsBarChart: View {
    let data: [BillSegment]
    
    var body: some View {
        Chart(data) { segment in
            BarMark(
                x: .value("Label", segment.label),
                y: .value("Amount", segment.value)
            )
            .annotation(position: .top) {
                Text(segment.value, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                     // format: .currency(code: "USD"))
                    .font(.caption)
            }
        }
        .frame(height: 200)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    BillsBarChart(data: [
        BillSegment(label: "Annual", value: 67200.00),
        BillSegment(label: "Monthly", value: 5600.00),
        BillSegment(label: "Weekly", value: 1400.00),
        BillSegment(label: "Daily", value: 280.00),
        BillSegment(label: "Hourly", value: 32.00)
    ])
    .padding()
}

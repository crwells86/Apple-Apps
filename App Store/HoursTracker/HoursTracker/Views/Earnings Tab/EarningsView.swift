import SwiftUI

struct EarningsView: View {
    var body: some View {
        List {
            EarningsSummaryView()
            EarningsBarChartView()
            EarningsListView()
        }
        .navigationTitle("Earnings")
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    EarningsView()
}

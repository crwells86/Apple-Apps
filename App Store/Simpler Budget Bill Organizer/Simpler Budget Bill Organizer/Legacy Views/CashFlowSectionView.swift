import SwiftUI

struct CashFlowSectionView: View {
    let income: Decimal
    let expense: Decimal
    let incomeChartData: [Double]
    let expenseChartData: [Double]
    
    var body: some View {
        HStack(spacing: 12) {
            //                NavigationLink {
            //                    IncomeDetailView()
            //                } label: {
            MetricCardView(
                title: "Income",
                value: income,
                color: .green,
                chartData: incomeChartData
            )
            //                }
            //                .buttonStyle(.plain)
            
            //                NavigationLink {
            //                    ExpenseDetailView()
            //                } label: {
            MetricCardView(
                title: "Expenses",
                value: expense,
                color: .red,
                chartData: expenseChartData
            )
            //                }
            //                .buttonStyle(.plain)
        }
        .padding(.horizontal)
        //        }
    }
}

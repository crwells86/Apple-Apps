import SwiftUI
import Charts
import SwiftData

struct EarningsBarChartView: View {
    @Query private var allShifts: [WorkShift]
    
    private var earningsData: [EarningsEntry] {
        let calendar = Calendar.current
        let today = Date()
        
        var result = [EarningsEntry]()
        let formatter = DateFormatter()
        formatter.dateFormat = "LLL" // e.g., Jan, Feb
        
        for i in (0..<6).reversed() {
            guard
                let monthStart = calendar.date(byAdding: .month, value: -i, to: today),
                let monthInterval = calendar.dateInterval(of: .month, for: monthStart)
            else { continue }
            
            // Filter shifts within the month
            let shiftsInMonth = allShifts.filter {
                $0.startTime >= monthInterval.start && $0.startTime < monthInterval.end
            }
            
            // Sum earnings for that month
            let total: Double = shiftsInMonth.reduce(0) { sum, shift in
                let hours = shift.totalWorked / 3600
                let earnings = Decimal(hours) * shift.job.hourlyRate
                return sum + (earnings as NSDecimalNumber).doubleValue
            }
            
            let label = formatter.string(from: monthStart)
            result.append(EarningsEntry(label: label, amount: total))
        }
        
        return result
    }
    
    private var maxAmount: Double {
        let max = earningsData.map(\.amount).max() ?? 100
        return (max / 10).rounded(.up) * 10
    }
    
    private var axisValues: [Double] {
        guard maxAmount > 0 else { return [0, 10, 20, 30, 40] }
        return stride(from: 0, through: maxAmount, by: maxAmount / 4).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Past 6 Months")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(earningsData) { entry in
                    BarMark(
                        x: .value("Month", entry.label),
                        y: .value("Earnings", entry.amount)
                    )
                    .foregroundStyle(.green)
                }
            }
            .chartYAxis {
                AxisMarks(values: axisValues) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .currency(code: "USD"))
                }
            }
            .chartYScale(domain: 0...maxAmount)
            .frame(height: 160)
            .padding(.horizontal)
        }
    }
}

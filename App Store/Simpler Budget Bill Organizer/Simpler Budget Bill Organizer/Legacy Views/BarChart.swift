import Charts
import SwiftUI

struct BarChart: View {
    let data: [Double]
    let color: Color
    
    struct DailyEntry: Identifiable {
        let date: Date
        let value: Double
        
        var id: Date { date }
        
        var label: String {
            let day = Calendar.current.component(.day, from: date)
            return day == 1 || day % 5 == 0 ? "\(day)" : ""
        }
    }
    
    var entries: [DailyEntry] {
        let calendar = Calendar.current
        let now = Date()
        let range = calendar.range(of: .day, in: .month, for: now)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        return range.enumerated().compactMap { index, _ in
            guard index < data.count else { return nil }
            let date = calendar.date(byAdding: .day, value: index, to: startOfMonth)!
            return DailyEntry(date: date, value: data[index])
        }
    }
    
    var body: some View {
        Chart {
            ForEach(entries) { item in
                BarMark(
                    x: .value("Day", item.date),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(color.opacity(0.8))
                .cornerRadius(2)
            }
        }
        .frame(height: 100)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 5)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        let day = Calendar.current.component(.day, from: date)
                        Text("\(day)")
                    }
                }
            }
        }
    }
}

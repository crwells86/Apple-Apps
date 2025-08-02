import SwiftUI
import SwiftData

struct EarningsListView: View {
    @Query private var allShifts: [WorkShift]
    
    var monthlyEarnings: [MonthlyEarnings] {
        computeMonthlyEarnings(from: allShifts)
    }
    
    var body: some View {
        ForEach(monthlyEarnings) { month in
            Section(header: Text("\(month.month) Earnings")) {
                ForEach(month.weeks) { week in
                    HStack {
                        Text(week.range)
                        Spacer()
                        Text(String(format: "$%.2f", week.amount))
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    func computeMonthlyEarnings(from shifts: [WorkShift]) -> [MonthlyEarnings] {
        let calendar = Calendar.current
        let today = Date()
        var months: [MonthlyEarnings] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL" // e.g., "July"
        
        for i in (0..<6) {
            guard let monthStart = calendar.date(byAdding: .month, value: -i, to: today),
                  let monthInterval = calendar.dateInterval(of: .month, for: monthStart)
            else { continue }
            
            let monthLabel = formatter.string(from: monthInterval.start)
            
            // Filter shifts in this month
            let shiftsInMonth = shifts.filter {
                $0.startTime >= monthInterval.start && $0.startTime < monthInterval.end
            }
            
            // Group by week
            let groupedByWeek = Dictionary(grouping: shiftsInMonth) { shift in
                calendar.dateInterval(of: .weekOfYear, for: shift.startTime)?.start ?? shift.startTime
            }
            
            var weeklyEarnings: [WeeklyEarning] = groupedByWeek.compactMap { (weekStart, shifts) in
                guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else {
                    return nil
                }
                
                let rangeFormatter = DateFormatter()
                rangeFormatter.dateFormat = "MMM d"
                
                let weekEnd = calendar.date(byAdding: .day, value: -1, to: weekInterval.end) ?? weekInterval.end
                let range = "\(rangeFormatter.string(from: weekInterval.start)) – \(rangeFormatter.string(from: weekEnd))"
                
                let amount: Double = shifts.reduce(0) { sum, shift in
                    let hours = shift.totalWorked / 3600
                    let earnings = Decimal(hours) * shift.job.hourlyRate
                    return sum + (earnings as NSDecimalNumber).doubleValue
                }
                
                return WeeklyEarning(range: range, amount: amount)
            }
            
            weeklyEarnings.sort { $0.range < $1.range }
            
            if !weeklyEarnings.isEmpty {
                months.append(MonthlyEarnings(month: monthLabel, monthDate: monthInterval.start, weeks: weeklyEarnings))
            }
        }
        
        return months.sorted(by: { $0.monthDate > $1.monthDate })
    }
}

#Preview {
    EarningsListView()
}

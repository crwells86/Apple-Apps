import SwiftUI
import SwiftData

struct EarningsSummaryView: View {
    @Query private var allShifts: [WorkShift]
    @State private var isShowingInfoSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading) {
                Text("This Week")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(formattedCurrency(totalWeeklyEarnings))
                    .font(.largeTitle)
                    .fontWeight(.semibold)
            }
            
            Text("Worked \(formattedTime(from: totalWorkedTime))")
            
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    // MARK: - Date & Earnings Logic
    private var startOfWeek: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }
    
    private var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)!
    }
    
    private var shiftsThisWeek: [WorkShift] {
        allShifts.filter {
            $0.startTime >= startOfWeek && $0.startTime < endOfWeek
        }
    }
    
    private var totalWorkedTime: TimeInterval {
        shiftsThisWeek.reduce(0) { $0 + $1.totalWorked }
    }
    
    private var totalWeeklyEarnings: Decimal {
        shiftsThisWeek.reduce(0) { sum, shift in
            let hours = shift.totalWorked / 3600
            return sum + Decimal(hours) * shift.job.hourlyRate
        }
    }
    
    // MARK: - Formatters
    private func formattedCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(for: value) ?? "$0.00"
    }
    
    private func formattedTime(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours) hr, \(minutes) min"
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    EarningsSummaryView()
}

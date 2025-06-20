import Foundation

enum Timeframe: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var id: String { rawValue }
    
    func startDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        case .month:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        case .year:
            return calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
        }
    }
}

import Foundation

enum Timeframe: String, CaseIterable, Identifiable {
    case hour = "Hour"
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case allTime = "All Time" // ✅ New case

    var id: String { rawValue }

    func startDate(trackingStartDate: Date? = nil) -> Date {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .hour:
            return cal.date(byAdding: .hour, value: -1, to: now) ?? now
        case .day:
            return cal.startOfDay(for: now)
        case .week:
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            return cal.date(from: comps) ?? now
        case .month:
            let comps = cal.dateComponents([.year, .month], from: now)
            return cal.date(from: comps) ?? now
        case .year:
            let comps = cal.dateComponents([.year], from: now)
            return cal.date(from: comps) ?? now
        case .allTime:
            return trackingStartDate ?? .distantPast
        }
    }
}

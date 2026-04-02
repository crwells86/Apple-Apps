import Foundation

enum Timeframe: String, CaseIterable, Identifiable {
    case hour, day, week, month, year, custom // allTime,

    var id: String { rawValue }

    func startDate(customStart: Date? = nil) -> Date {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .hour:
            return calendar.date(byAdding: .hour, value: -1, to: now) ?? now
        case .day:
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
//        case .allTime:
//            return Date(timeIntervalSince1970: 1_704_000_000) // or your earliest tracked date
        case .custom:
            return customStart ?? now
        }
    }
}

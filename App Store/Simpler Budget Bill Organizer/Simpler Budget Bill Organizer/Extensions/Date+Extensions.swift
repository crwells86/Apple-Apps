import Foundation

extension Date {
    static var startOfWeek: Date {
        let calendar = Calendar(identifier: .iso8601)
        guard let date = calendar.dateComponents(
            [.calendar, .yearForWeekOfYear, .weekOfYear],
            from: Date()
        ).date else {
            fatalError("Couldn't create start of week date")
        }
        return date
    }
    
    var formatCompactDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

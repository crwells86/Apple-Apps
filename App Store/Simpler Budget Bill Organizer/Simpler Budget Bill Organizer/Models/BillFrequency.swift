import Foundation

/// The recurrence options for your bills.
enum BillFrequency: String, CaseIterable, Codable {
    /// A one-off payment (no recurrence).
    case oneTime
    /// Every day.
    case daily
    /// Every week.
    case weekly
    /// Every two weeks.
    case biweekly
    /// Twice per month (e.g. on the 1st & 15th).
    case semiMonthly
    /// Every month.
    case monthly
    /// Every two months.
    case biMonthly
    /// Every three months.
    case quarterly
    /// Every six months.
    case semiAnnual
    /// Every year.
    case yearly
    
    /// The `DateComponents` step to add for each recurrence.
    var dateComponents: DateComponents {
        switch self {
        case .oneTime:
            return DateComponents()
        case .daily:
            return DateComponents(day: 1)
        case .weekly:
            return DateComponents(day: 7)
        case .biweekly:
            return DateComponents(day: 14)
        case .semiMonthly:
            // “twice a month” – often treated as 1st & 15th
            return DateComponents(day: 15)
        case .monthly:
            return DateComponents(month: 1)
        case .biMonthly:
            return DateComponents(month: 2)
        case .quarterly:
            return DateComponents(month: 3)
        case .semiAnnual:
            return DateComponents(month: 6)
        case .yearly:
            return DateComponents(year: 1)
        }
    }
    
    /// A human-readable name for UI.
    var displayName: String {
        switch self {
        case .oneTime:       return "One-Time"
        case .daily:         return "Daily"
        case .weekly:        return "Weekly"
        case .biweekly:      return "Bi-Weekly"
        case .semiMonthly:   return "Semi-Monthly"
        case .monthly:       return "Monthly"
        case .biMonthly:     return "Bi-Monthly"
        case .quarterly:     return "Quarterly"
        case .semiAnnual:    return "Semi-Annual"
        case .yearly:        return "Yearly"
        }
    }
}

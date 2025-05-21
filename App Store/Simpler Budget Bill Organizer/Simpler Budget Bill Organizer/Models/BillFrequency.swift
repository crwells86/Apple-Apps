enum BillFrequency: String, CaseIterable, Identifiable {
    case oneTime
    case weekly
    case everyOtherWeek
    case monthly
    case everyOtherMonth
    case yearly
    
    var id: String { rawValue }
    
    var toMonthly: Double {
        switch self {
        case .monthly:
            return 1
        case .weekly:
            return 52.0 / 12.0
        case .everyOtherWeek:
            return 26.0 / 12.0
        case .everyOtherMonth:
            return 0.5
        case .yearly:
            return 1.0 / 12.0
        case .oneTime:
            return 0
        }
    }
    
    var label: String {
        switch self {
        case .oneTime: return "One Time"
        case .weekly: return "Weekly"
        case .everyOtherWeek: return "Every Other Week"
        case .monthly: return "Monthly"
        case .everyOtherMonth: return "Every Other Month"
        case .yearly: return "Yearly"
        }
    }
}

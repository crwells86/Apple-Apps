enum WorkSchedule: String, CaseIterable, Identifiable {
    case fullTime
    case partTime
    
    var id: String { rawValue }
    
    var hoursPerYear: Double {
        switch self {
        case .fullTime:
            return 2080
        case .partTime:
            return 1040
        }
        // custom hours?
    }
    
    var label: String {
        switch self {
        case .fullTime: return "Full-Time"
        case .partTime: return "Part-Time"
        }
    }
}

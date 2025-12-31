import SwiftData
import Foundation

@Model class Income: Identifiable {
    var id: UUID
    var source: String
    var amount: Decimal
    var date: Date
    var frequencyRaw: String
    var reminderEnabled: Bool
    
    init(
        source: String,
        amount: Decimal,
        date: Date,
        frequency: Frequency = .variable,
        reminderEnabled: Bool = false
    ) {
        self.id = UUID()
        self.source = source
        self.amount = amount
        self.date = date
        self.frequencyRaw = frequency.rawValue
        self.reminderEnabled = reminderEnabled
    }
}

//extension Income {
//    func allOccurrences(in range: DateInterval) -> [Date] {
//        guard let frequency = Frequency(rawValue: frequencyRaw) else {
//            // If frequencyRaw is invalid, treat as variable (single occurrence)
//            return (range.contains(date) ? [date] : [])
//        }
//
//        if frequency == .variable {
//            return range.contains(date) ? [date] : []
//        }
//
//        var calendar = Calendar.current
//        calendar.timeZone = TimeZone.current
//
//        var results: [Date] = []
//
//        // Determine the date interval component for adding
//        let component: Calendar.Component
//        let step: Int
//
//        switch frequency {
//        case .weekly:
//            component = .weekOfYear
//            step = 1
//        case .biweekly:
//            component = .weekOfYear
//            step = 2
//        case .monthly:
//            component = .month
//            step = 1
//        default:
//            // For any other frequencies not specified, treat as variable
//            return range.contains(date) ? [date] : []
//        }
//
//        // Start from the first occurrence on or after range.start
//        var current = date
//
//        // If date is before range.start, advance current to first occurrence >= range.start
//        if current < range.start {
//            var next = current
//            while next < range.start {
//                guard let added = calendar.date(byAdding: component, value: step, to: next) else {
//                    break
//                }
//                next = added
//            }
//            current = next
//        }
//
//        // Collect all occurrences until current > range.end
//        while current <= range.end {
//            results.append(current)
//            guard let next = calendar.date(byAdding: component, value: step, to: current) else {
//                break
//            }
//            current = next
//        }
//
//        return results
//    }
//}













import Foundation

//extension Income {
//    func allOccurrences(in range: DateInterval) -> [Date] {
//        guard let frequency = Frequency(rawValue: frequencyRaw) else {
//            return range.contains(date) ? [date] : []
//        }
//
//        if frequency == .variable {
//            return range.contains(date) ? [date] : []
//        }
//
//        var calendar = Calendar.current
//        calendar.timeZone = TimeZone.current
//
//        var results: [Date] = []
//
//        // Determine the date interval component for adding
//        let component: Calendar.Component
//        let step: Int
//
//        switch frequency {
//        case .weekly:
//            component = .weekOfYear
//            step = 1
//        case .biweekly:
//            component = .weekOfYear
//            step = 2
//        case .monthly:
//            component = .month
//            step = 1
//        default:
//            return range.contains(date) ? [date] : []
//        }
//
//        // FIXED: Find the first occurrence on or after range.start
//        var current = date
//
//        if current < range.start {
//            // Calculate how many periods have passed since the original date
//            let components = calendar.dateComponents([component], from: date, to: range.start)
//            
//            let periodsPassed: Int
//            switch component {
//            case .weekOfYear:
//                periodsPassed = components.weekOfYear ?? 0
//            case .month:
//                periodsPassed = components.month ?? 0
//            default:
//                periodsPassed = 0
//            }
//            
//            // Calculate how many full cycles we need to skip
//            // We want the first occurrence >= range.start
//            let cyclesToSkip = (periodsPassed / step) * step
//            
//            // Advance to that occurrence
//            if let advanced = calendar.date(byAdding: component, value: cyclesToSkip, to: date) {
//                current = advanced
//                
//                // If we're still before range.start, advance one more cycle
//                if current < range.start {
//                    current = calendar.date(byAdding: component, value: step, to: current) ?? current
//                }
//            }
//        }
//
//        // Collect all occurrences from current through range.end
//        while current <= range.end {
//            // Only include if it's within the range
//            if current >= range.start {
//                results.append(current)
//            }
//            
//            guard let next = calendar.date(byAdding: component, value: step, to: current) else {
//                break
//            }
//            current = next
//        }
//
//        return results
//    }
//}

// MARK: - Alternative Simpler Approach (More Reliable)
// This version is easier to understand and less prone to edge cases

extension Income {
    func allOccurrences(in range: DateInterval) -> [Date] {
        guard let frequency = Frequency(rawValue: frequencyRaw) else {
            return range.contains(date) ? [date] : []
        }

        if frequency == .variable {
            return range.contains(date) ? [date] : []
        }

        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        let component: Calendar.Component
        let step: Int

        switch frequency {
        case .weekly:
            component = .weekOfYear
            step = 1
        case .biweekly:
            component = .weekOfYear
            step = 2
        case .monthly:
            component = .month
            step = 1
        default:
            return range.contains(date) ? [date] : []
        }

        var results: [Date] = []
        var current = date

        // Go backwards first if needed to find earlier occurrences
        var temp = current
        while temp > range.start {
            guard let prev = calendar.date(byAdding: component, value: -step, to: temp) else {
                break
            }
            if prev < range.start {
                break
            }
            temp = prev
        }
        
        // Now temp is the first occurrence on or before range.start
        // Advance forward if needed to get into range
        current = temp
        while current < range.start {
            guard let next = calendar.date(byAdding: component, value: step, to: current) else {
                break
            }
            current = next
        }

        // Collect all occurrences from current through range.end
        while current <= range.end {
            results.append(current)
            guard let next = calendar.date(byAdding: component, value: step, to: current) else {
                break
            }
            current = next
        }

        return results
    }
}

// MARK: - Debug Helper
// Add this to help debug what's happening

extension Income {
    func debugOccurrences(in range: DateInterval) -> String {
        let occurrences = allOccurrences(in: range)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        var debug = """
        Income: \(source)
        Start Date: \(formatter.string(from: date))
        Frequency: \(frequencyRaw)
        Range: \(formatter.string(from: range.start)) to \(formatter.string(from: range.end))
        Occurrences found: \(occurrences.count)
        """
        
        for (index, occurrence) in occurrences.enumerated() {
            debug += "\n  \(index + 1). \(formatter.string(from: occurrence))"
        }
        
        return debug
    }
}

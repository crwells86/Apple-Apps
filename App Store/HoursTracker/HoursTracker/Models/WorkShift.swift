import Foundation
import SwiftData

@Model
class WorkShift {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var totalWorked: TimeInterval
    var notes: String?
    var overtimeThreshold: TimeInterval = 8 * 3600
    var createdAt: Date
    
    // Inverse relationship: each shift belongs to one job
    var job: Job
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        totalWorked: TimeInterval = 0,
        notes: String? = nil,
        overtimeThreshold: TimeInterval = 8 * 3600,
        job: Job
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.totalWorked = totalWorked
        self.notes = notes
        self.overtimeThreshold = overtimeThreshold
        self.createdAt = Date()
        self.job = job
    }
    
    var isOvertime: Bool {
        totalWorked > overtimeThreshold
    }
    
    var formattedTotalWorked: String {
        let h = Int(totalWorked) / 3600
        let m = (Int(totalWorked) % 3600) / 60
        let s = Int(totalWorked) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

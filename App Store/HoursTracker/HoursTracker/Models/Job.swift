import Foundation
import SwiftData

@Model
class Job {
    var id: UUID
    var title: String
    var company: String?
    var createdAt: Date
    
    var hourlyRate: Decimal
    
    @Relationship(deleteRule: .cascade)
    var shifts: [WorkShift] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        company: String? = nil,
        hourlyRate: Decimal,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.company = company
        self.hourlyRate = hourlyRate
        self.createdAt = createdAt
    }
}

import SwiftData
import Foundation

@Model
final class TaskItem: Identifiable { // , Sendable
    var id: UUID
    var title: String
    var isCompleted: Bool
    
    // Optional inverse relationship
    @Relationship(inverse: \Recording.actionItems) var recording: Recording?
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

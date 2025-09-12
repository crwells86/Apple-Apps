import Foundation

struct ChatMessage: Identifiable, Equatable {
    enum Role: Equatable {
        case user
        case ai
    }
    
    let id = UUID()
    let role: Role
    let text: String
    let timestamp: Date
    
    init(role: Role, text: String, timestamp: Date = .init()) {
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
    
    // formatted time string for UI
    var timeString: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        return fmt.string(from: timestamp)
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id && lhs.role == rhs.role && lhs.text == rhs.text && lhs.timestamp == rhs.timestamp
    }
}

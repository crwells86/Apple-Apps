import SwiftData
import Foundation

@Model
class Question {
    var id: UUID
    var text: String
    var optionA: String
    var optionB: String
    var challengeA: String?
    var challengeB: String?
    
    init(id: UUID = UUID(), text: String, optionA: String, optionB: String, challengeA: String? = nil, challengeB: String? = nil) {
        self.id = id
        self.text = text
        self.optionA = optionA
        self.optionB = optionB
        self.challengeA = challengeA
        self.challengeB = challengeB
    }
}


@Model
class Deck {
    var id: UUID
    var name: String
    var icon: String

    @Relationship(deleteRule: .cascade) // cascade delete when deck is deleted
    var questions: [Question]

    init(id: UUID = UUID(), name: String, icon: String, questions: [Question] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        self.questions = questions
    }
}


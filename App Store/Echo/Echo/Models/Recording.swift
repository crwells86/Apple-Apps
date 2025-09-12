import SwiftData
import Foundation
import AVFoundation
import FoundationModels

@Model
final class Recording { //: @unchecked Sendable  {
    typealias StartTime = CMTime
    
    var id: UUID
    var title: String
    var text: AttributedString
    var url: URL?
    var isDone: Bool
    
    var createdAt: Date
    var updatedAt: Date
    var duration: TimeInterval
    var fileURL: URL
    var isPhoneCall: Bool
    var transcription: Transcription?
    
    // Relationships
    @Relationship(deleteRule: .cascade) var summaries: [Summary]
    @Relationship(deleteRule: .cascade) var actionItems: [TaskItem]
    @Relationship(deleteRule: .cascade) var speakers: [Speaker]
    @Relationship(deleteRule: .cascade) var tags: [Tag]
    
    var shareURL: URL?
    
    init(id: UUID, title: String, text: AttributedString, url: URL? = nil, isDone: Bool, createdAt: Date, updatedAt: Date, duration: TimeInterval, fileURL: URL, isPhoneCall: Bool, transcription: Transcription? = nil, summaries: [Summary] = [], actionItems: [TaskItem] = [], speakers: [Speaker] = [], tags: [Tag] = [], shareURL: URL? = nil) {
        self.id = id
        self.title = title
        self.text = text
        self.url = url
        self.isDone = isDone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.duration = duration
        self.fileURL = fileURL
        self.isPhoneCall = isPhoneCall
        self.transcription = transcription
        self.summaries = summaries
        self.actionItems = actionItems
        self.speakers = speakers
        self.tags = tags
        self.shareURL = shareURL
    }
    
    func suggestedTitle() async throws -> String? {
        guard SystemLanguageModel.default.isAvailable else { return nil }
        
        let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            instructions: """
            You are an assistant that generates short, clear titles for audio recordings.
            Summarize the main topic in five words or fewer.
            """
        )
        
        let baseText = transcription?.text ?? ""
        guard !baseText.isEmpty else { return nil }
        
        let answer = try await session.respond(to: baseText)
        return answer.content
            .trimmingCharacters(in: .punctuationCharacters.union(.whitespacesAndNewlines))
    }
}

@Model
final class Summary {
    var id: UUID
    var text: String
    var createdAt: Date
    
    init(id: UUID = UUID(), text: String, createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

@Model
final class ActionItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}


@Model
final class Transcription {
    @Attribute(.unique) var id: UUID
    var text: String
    var createdAt: Date
    var languageCode: String
    var isEdited: Bool
    var recording: Recording?
    
    init(
        text: String,
        languageCode: String
    ) {
        self.id = UUID()
        self.text = text
        self.languageCode = languageCode
        self.isEdited = false
        self.createdAt = Date()
    }
}

//@Model
//final class Summary {
//    @Attribute(.unique) var id: UUID
//    var text: String
//    var actionItems: [String]
//    var createdAt: Date
//    var recording: Recording?
//    
//    init(
//        text: String,
//        actionItems: [String] = []
//    ) {
//        self.id = UUID()
//        self.text = text
//        self.actionItems = actionItems
//        self.createdAt = Date()
//    }
//}

@Model
final class Speaker {
    @Attribute(.unique) var id: UUID
    var name: String
    var confidence: Double
    var segments: [SpeakerSegment]
    var recording: Recording?
    
    init(
        name: String,
        confidence: Double
    ) {
        self.id = UUID()
        self.name = name
        self.confidence = confidence
        self.segments = []
    }
}

@Model
final class SpeakerSegment {
    @Attribute(.unique) var id: UUID
    var startTime: TimeInterval
    var endTime: TimeInterval
    var text: String
    var speaker: Speaker?
    
    init(
        startTime: TimeInterval,
        endTime: TimeInterval,
        text: String
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
}

@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var recordings: [Recording]
    
    init(
        name: String,
        colorHex: String
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.recordings = []
    }
}

extension Recording {
    static func blank() -> Recording {
        Recording(
            id: UUID(),
            title: "New Recording",
            text: AttributedString(""),
            url: nil,
            isDone: false,
            createdAt: Date(),
            updatedAt: Date(),
            duration: 0,
            fileURL: URL(filePath: "/dev/null"),
            isPhoneCall: false,
            transcription: Transcription(text: "", languageCode: ""),
            summaries: [],
            speakers: [],
            tags: [],
            shareURL: nil
        )
    }
    
    func recordingBrokenUpByLines() -> AttributedString {
        if url == nil {
            return text
        } else {
            var final = AttributedString("")
            var working = AttributedString("")
            let copy = text
            copy.runs.forEach { run in
                if copy[run.range].characters.contains(".") {
                    working.append(copy[run.range])
                    final.append(working)
                    final.append(AttributedString("\n\n"))
                    working = AttributedString("")
                } else {
                    if working.characters.isEmpty {
                        let newText = copy[run.range].characters
                        let attributes = run.attributes
                        let trimmed = newText.trimmingPrefix(" ")
                        let newAttributed = AttributedString(trimmed, attributes: attributes)
                        working.append(newAttributed)
                    } else {
                        working.append(copy[run.range])
                    }
                }
            }
            
            if final.characters.isEmpty {
                return working
            }
            
            return final
        }
    }
}

extension Recording: Equatable {
    nonisolated static func == (lhs: Recording, rhs: Recording) -> Bool {
        lhs.id == rhs.id
    }
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

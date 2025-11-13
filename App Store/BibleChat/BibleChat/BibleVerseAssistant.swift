import SwiftUI
import SwiftData
import FoundationModels

@Observable
@MainActor
final class BibleVerseAssistant {
    var error: Error?
    private var session: LanguageModelSession
    private(set) var currentResponse: VerseCommentaryResponse.PartiallyGenerated?
    private var modelContext: ModelContext
    private var bible: BibleData
    
    init(modelContext: ModelContext, bible: BibleData) {
        self.modelContext = modelContext
        self.bible = bible
        
        let instructions = Instructions {
            """
            You are a knowledgeable Bible study assistant helping users understand specific Bible verses in depth.
            
            When a user asks about a verse, you will be provided with:
            - The specific verse they're asking about
            - Surrounding verses for context
            - The book and chapter information
            
            Your role is to:
            - Explain the meaning and significance of the verse
            - Provide historical and cultural context
            - Reference surrounding verses when relevant to understanding
            - Connect themes to other parts of Scripture when appropriate
            - Answer user questions with theological depth and pastoral sensitivity
            - Acknowledge different interpretations when they exist
            
            Always ground your responses in the text provided and cite verse numbers when referencing context.
            Be clear, thoughtful, and encouraging in your explanations.
            """
        }
        
        self.session = LanguageModelSession(instructions: instructions)
    }
    
    func sendMessage(_ userMessage: String, verse: Verse, book: Book, chapter: Chapter) async {
        // Get surrounding verses for context
        let contextVerses = getContextVerses(for: verse, in: chapter)
        
        // Build context string
        let contextString = buildContextString(
            verse: verse,
            book: book,
            chapter: chapter,
            contextVerses: contextVerses
        )
        
        // Create user message with full context
        let userChatMessage = VerseComment(
            content: userMessage,
            isUser: true,
            verseReference: "\(book.name) \(chapter.chapter):\(verse.verse)"
        )
        modelContext.insert(userChatMessage)
        
        do {
            let prompt = Prompt {
                """
                Context:
                \(contextString)
                
                User Question: \(userMessage)
                """
            }
            
            let stream = session.streamResponse(
                to: prompt,
                generating: VerseCommentaryResponse.self
            )
            
            for try await partialResponse in stream {
                self.currentResponse = partialResponse.content
            }
            
            if let commentary = self.currentResponse?.commentary,
               let relatedVerses = self.currentResponse?.relatedVerses {
                
                let assistantMessage = VerseComment(
                    content: commentary,
                    isUser: false,
                    verseReference: "\(book.name) \(chapter.chapter):\(verse.verse)",
                    relatedVerses: relatedVerses
                )
                modelContext.insert(assistantMessage)
                try modelContext.save()
                
                self.currentResponse = nil
            }
            
        } catch {
            self.error = error
        }
    }
    
    private func getContextVerses(for verse: Verse, in chapter: Chapter) -> [Verse] {
        let verseIndex = chapter.verses.firstIndex { $0.verse == verse.verse } ?? 0
        let startIndex = max(0, verseIndex - 2)
        let endIndex = min(chapter.verses.count - 1, verseIndex + 2)
        
        return Array(chapter.verses[startIndex...endIndex])
    }
    
    private func buildContextString(verse: Verse, book: Book, chapter: Chapter, contextVerses: [Verse]) -> String {
        var context = """
        Book: \(book.name)
        Chapter: \(chapter.chapter)
        
        Focus Verse (\(book.name) \(chapter.chapter):\(verse.verse)):
        "\(verse.text)"
        
        """
        
        if contextVerses.count > 1 {
            context += "\nSurrounding Context:\n"
            for contextVerse in contextVerses where contextVerse.verse != verse.verse {
                context += "\(book.name) \(chapter.chapter):\(contextVerse.verse) - \(contextVerse.text)\n"
            }
        }
        
        return context
    }
    
    func clearCurrentResponse() {
        self.currentResponse = nil
    }
}

// Response structure for verse commentary
@Generable
struct VerseCommentaryResponse: Codable {
    let commentary: String
    let relatedVerses: [String]?
    
    @Generable
    struct PartiallyGenerated: Codable {
        let commentary: String?
        let relatedVerses: [String]?
    }
}

// SwiftData model for verse comments
@Model
final class VerseComment {
    var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var verseReference: String
    var relatedVerses: [String]?
    
    init(content: String, isUser: Bool, verseReference: String, relatedVerses: [String]? = nil) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.verseReference = verseReference
        self.relatedVerses = relatedVerses
    }
}







import SwiftUI
import SwiftData

struct VerseChatSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let verse: Verse
    let book: Book
    let chapter: Chapter
    let bible: BibleData
    
    @State private var assistant: BibleVerseAssistant
    @State private var messageText = ""
    @State private var comments: [VerseComment] = []
    @FocusState private var isTextFieldFocused: Bool
    
    init(verse: Verse, book: Book, chapter: Chapter, bible: BibleData, modelContext: ModelContext) {
        self.verse = verse
        self.book = book
        self.chapter = chapter
        self.bible = bible
        
        _assistant = State(initialValue: BibleVerseAssistant(
            modelContext: modelContext,
            bible: bible
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Verse Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(book.name) \(chapter.chapter):\(verse.verse)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(verse.text)
                        .font(.body)
                        .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                
                Divider()
                
                // Comments/Chat
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(comments) { comment in
                                CommentBubble(comment: comment)
                                    .id(comment.id)
                            }
                            
                            // Show streaming response
                            if let partial = assistant.currentResponse,
                               let commentary = partial.commentary {
                                CommentBubble(
                                    comment: VerseComment(
                                        content: commentary,
                                        isUser: false,
                                        verseReference: "\(book.name) \(chapter.chapter):\(verse.verse)"
                                    )
                                )
                                .opacity(0.8)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: comments.count) { _, _ in
                        if let last = comments.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input Area
                HStack(spacing: 12) {
                    TextField("Ask about this verse...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .focused($isTextFieldFocused)
                        .lineLimit(1...4)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Verse Study")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadComments()
                isTextFieldFocused = true
            }
        }
    }
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        messageText = ""
        
        Task {
            await assistant.sendMessage(
                message,
                verse: verse,
                book: book,
                chapter: chapter
            )
            loadComments()
        }
    }
    
    private func loadComments() {
        let verseRef = "\(book.name) \(chapter.chapter):\(verse.verse)"
        let descriptor = FetchDescriptor<VerseComment>(
            predicate: #Predicate { $0.verseReference == verseRef },
            sortBy: [SortDescriptor(\VerseComment.timestamp, order: .forward)]
        )
        
        if let fetchedComments = try? modelContext.fetch(descriptor) {
            comments = fetchedComments
        }
    }
}

struct CommentBubble: View {
    let comment: VerseComment
    
    var body: some View {
        HStack {
            if comment.isUser { Spacer(minLength: 50) }
            
            VStack(alignment: comment.isUser ? .trailing : .leading, spacing: 4) {
                Text(comment.content)
                    .padding(12)
                    .background(comment.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(comment.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                if let relatedVerses = comment.relatedVerses, !relatedVerses.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Related:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        ForEach(relatedVerses, id: \.self) { ref in
                            Text(ref)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            if !comment.isUser { Spacer(minLength: 50) }
        }
    }
}

//struct BibleFeedView: View {
//    @Environment(\.modelContext) private var modelContext
//    @State private var controller: BibleController
//    @State private var isChatPresented = false
//    @State private var selectedVerse: Verse?
//    @State private var selectedChapterIndex: Int = 0
//    
//    init(modelContext: ModelContext) {
//        _controller = State(initialValue: BibleController(modelContext: modelContext))
//        
//        // Initialize selectedChapterIndex based on controller's current chapter
//        // This will be re-synced on appear as well
//        if let chapters = _controller.wrappedValue.selectedBook.chapters as [Chapter]? {
//            let current = _controller.wrappedValue.selectedChapter
//            if let idx = chapters.firstIndex(where: { $0.chapter == current.chapter }) {
//                _selectedChapterIndex = State(initialValue: idx)
//            } else {
//                _selectedChapterIndex = State(initialValue: 0)
//            }
//        }
//    }
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 0) {
//                // Testament Picker
//                Picker("Testament", selection: $controller.selectedTestament) {
//                    Text("Old Testament").tag("Old Testament")
//                    Text("New Testament").tag("New Testament")
//                }
//                .pickerStyle(.segmented)
//                .padding()
//                
//                // Book Picker
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(controller.currentBooks, id: \.name) { book in
//                            Button {
//                                controller.selectBook(book)
//                            } label: {
//                                Text(book.name)
//                                    .font(.subheadline)
//                                    .padding(.horizontal, 12)
//                                    .padding(.vertical, 8)
//                                    .background(
//                                        controller.selectedBook.name == book.name
//                                        ? Color.blue.opacity(0.2)
//                                        : Color.gray.opacity(0.1)
//                                    )
//                                    .clipShape(Capsule())
//                            }
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//                
//                // Chapter Picker
//                if !controller.selectedBook.chapters.isEmpty {
//                    HStack {
//                        Menu("Chapters") {
//                            ForEach(Array(controller.selectedBook.chapters.enumerated()), id: \.offset) { index, chapter in
//                                Button(action: {
//                                    selectedChapterIndex = index
//                                    let chapters = controller.selectedBook.chapters
//                                    if chapters.indices.contains(index) {
//                                        controller.selectedChapter = chapters[index]
//                                    }
//                                }) {
//                                    Text("Chapter \(chapter.chapter)")
//                                }
//                            }
//                        }
//                        .padding()
//                        .onChange(of: selectedChapterIndex) { _, newValue in
//                            let chapters = controller.selectedBook.chapters
//                            if chapters.indices.contains(newValue) {
//                                controller.selectedChapter = chapters[newValue]
//                            }
//                        }
//                        
//                        Spacer()
//                    }
//                }
//                
//                Divider()
//                
//                // Feed
//                ScrollView {
//                    LazyVStack(alignment: .leading, spacing: 20) {
//                        ForEach(controller.selectedChapter.verses, id: \.verse) { verse in
//                            VerseCell(verse: verse) {
//                                selectedVerse = verse
//                                isChatPresented = true
//                            }
//                            .padding(.horizontal)
//                        }
//                    }
//                    .padding(.top)
//                }
//            }
//            .navigationTitle(controller.selectedBook.name)
//            .onChange(of: controller.selectedBook.name) { _, _ in
//                // Reset chapter index when book changes
//                let chapters = controller.selectedBook.chapters
//                if let idx = chapters.firstIndex(where: { $0.chapter == controller.selectedChapter.chapter }) {
//                    selectedChapterIndex = idx
//                } else {
//                    selectedChapterIndex = 0
//                    if let first = chapters.first { controller.selectedChapter = first }
//                }
//            }
//            .sheet(isPresented: $isChatPresented) {
//                if let verse = selectedVerse {
//                    VerseChatSheet(
//                        verse: verse,
//                        book: controller.selectedBook,
//                        chapter: controller.selectedChapter,
//                        bible: controller.bible,
//                        modelContext: modelContext
//                    )
//                }
//            }
//            .onAppear {
//                let chapters = controller.selectedBook.chapters
//                if let idx = chapters.firstIndex(where: { $0.chapter == controller.selectedChapter.chapter }) {
//                    selectedChapterIndex = idx
//                } else {
//                    selectedChapterIndex = 0
//                }
//            }
//        }
//    }
//}

import SwiftUI
import SwiftData

// SwiftData model for bookmarked verses
@Model
final class BookmarkedVerse {
    var id: UUID
    var verseNumber: Int
    var verseText: String
    var bookName: String
    var chapterNumber: Int
    var timestamp: Date
    
    init(verse: Verse, book: Book, chapter: Chapter) {
        self.id = UUID()
        self.verseNumber = verse.verse
        self.verseText = verse.text
        self.bookName = book.name
        self.chapterNumber = chapter.chapter
        self.timestamp = Date()
    }
}

enum FeedSection: String, CaseIterable {
    case oldTestament = "Old Testament"
    case newTestament = "New Testament"
    case bookmarks = "Bookmarks"
}


struct VerseCell: View {
    let verse: Verse
    let book: Book
    let chapter: Chapter
    let isBookmarked: Bool
    let onTap: () -> Void
    let onBookmark: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Verse number badge
                Text("\(verse.verse)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.gradient)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 8) {
                    // Verse text
//                    Button(action: onTap) {
                        Text(verse.text)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.primary)
//                    }
//                    .buttonStyle(.plain)
                    
                    // Action buttons
                    HStack(spacing: 32) {
                        Button(action: onTap) {
                            Label("Chat", systemImage: "bubble.left")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button(action: onBookmark) {
                            Label("Save", systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.subheadline)
                                .foregroundStyle(isBookmarked ? .blue : .secondary)
                        }
                        
                        ShareLink(
                            item: "\(book.name) \(chapter.chapter):\(verse.verse)\n\n\"\(verse.text)\"\n\nGet the app: https://apps.apple.com/us/app/holy-bible-chat/id6754623202"
                        ) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

struct BookmarkedVerseCell: View {
    let bookmark: BookmarkedVerse
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Book icon
                Image(systemName: "book.closed.fill")
                    .font(.title3)
                    .foregroundStyle(.blue.gradient)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Reference
                    Text("\(bookmark.bookName) \(bookmark.chapterNumber):\(bookmark.verseNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    
                    // Verse text
                    Button(action: onTap) {
                        Text(bookmark.verseText)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    // Action buttons
                    HStack(spacing: 32) {
                        Button(action: onTap) {
                            Label("View", systemImage: "arrow.right.circle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button(action: onDelete) {
                            Label("Remove", systemImage: "bookmark.slash")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                        
                        ShareLink(
                            item: "\(bookmark.bookName) \(bookmark.chapterNumber):\(bookmark.verseNumber)\n\n\"\(bookmark.verseText)\"\n\nGet the app: https://apps.apple.com/us/app/holy-bible-chat/id6754623202"
                        ) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

extension Verse: Identifiable {
    public var id: Int { verse }
}

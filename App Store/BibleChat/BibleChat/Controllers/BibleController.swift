import Foundation
import SwiftData

@Observable
@MainActor
final class BibleController {
    let chatAssistant: BibleChatAssistant
    private(set) var bible: BibleData
    
    var selectedTestament: String = "Old Testament" {
        didSet {
            // When testament changes, update to first book of that testament
            if let firstBook = currentTestament?.books.first {
                selectBook(firstBook)
            }
        }
    }
    
    var selectedBook: Book
    var selectedChapter: Chapter
    var selectedVerse: Verse?
    
    // Computed property to get current testament
    var currentTestament: Testament? {
        bible.testaments.first { $0.name == selectedTestament }
    }
    
    // Computed property to get books for current testament
    var currentBooks: [Book] {
        currentTestament?.books ?? []
    }
    
    init(modelContext: ModelContext) {
        // Load Bible JSON
        let url = Bundle.main.url(forResource: "KJV", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decodedBible = try! JSONDecoder().decode(BibleData.self, from: data)
        
        // Get initial testament, book, and chapter
        let initialTestament = decodedBible.testaments.first!
        let initialBook = initialTestament.books.first!
        let initialChapter = initialBook.chapters.first!
        
        // Fetch or create user profile
        let userFetch = try? modelContext.fetch(FetchDescriptor<UserProfile>())
        let userProfile = userFetch?.first ?? UserProfile()
        
        // Initialize chat assistant with user profile
        self.chatAssistant = BibleChatAssistant(modelContext: modelContext, userProfile: userProfile)
        
        
        self.bible = decodedBible
        self.selectedBook = initialBook
        self.selectedChapter = initialChapter
        self.selectedVerse = nil
        self.selectedTestament = initialTestament.name
    }
    
    func selectBook(_ book: Book) {
        selectedBook = book
        if let firstChapter = book.chapters.first {
            selectedChapter = firstChapter
        } else {
            print("⚠️ \(book.name) has no chapters!")
        }
    }

    
    func selectChapter(_ chapter: Chapter) {
        selectedChapter = chapter
    }
    
    func sendQuestion(_ text: String) async {
        await chatAssistant.sendMessage(text)
    }
    
    func searchVerses(for query: String) -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        var results: [SearchResult] = []
        
        for testament in bible.testaments {
            for book in testament.books {
                for chapter in book.chapters {
                    for verse in chapter.verses where verse.text.localizedCaseInsensitiveContains(query) {
                        results.append(SearchResult(
                            bookName: book.name,
                            chapter: chapter.chapter,
                            verse: verse.verse,
                            text: verse.text
                        ))
                    }
                }
            }
        }
        return results
    }
}

import SwiftUI
import SwiftData

struct SearchResult: Identifiable {
    let id = UUID()
    let bookName: String
    let chapter: Int
    let verse: Int
    let text: String
    
    func highlightedText(_ query: String) -> AttributedString {
        var attributed = AttributedString(text)
        if let range = attributed.range(of: query, options: [.caseInsensitive]) {
            attributed[range].foregroundColor = .blue
            attributed[range].font = .headline
        }
        return attributed
    }
}




struct FreeBibleFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var controller: BibleController
    @State private var selectedVerse: Verse?
    @State private var selectedChapterIndex: Int = 0
    @State private var selectedSection: FeedSection = .oldTestament
    @State private var bookmarkedVerses: [BookmarkedVerse] = []
    
    // 🧩 Add search properties
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    private var searchResults: [SearchResult] {
        guard !searchText.isEmpty else { return [] }
        return controller.searchVerses(for: searchText)
    }
    
    @AppStorage("hasShownCompatibilitySheet") private var hasShownCompatibilitySheet = false
    @State private var showCompatibilitySheet = false
    
    init(modelContext: ModelContext) {
        // Initialize controller first
        let controllerInstance = BibleController(modelContext: modelContext)
        _controller = State(initialValue: controllerInstance)
        
        // Compute selectedChapterIndex with simple, explicit steps to help the type-checker
        let chaptersArray: [Chapter] = Array(controllerInstance.selectedBook.chapters)
        let currentChapterNumber: Int = controllerInstance.selectedChapter.chapter
        let foundIndex: Int? = chaptersArray.firstIndex { ch in
            ch.chapter == currentChapterNumber
        }
        _selectedChapterIndex = State(initialValue: foundIndex ?? 0)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Section Picker (hidden while searching)
                if !isSearching {
                    HStack(spacing: 0) {
                        ForEach(FeedSection.allCases, id: \.self) { section in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSection = section
                                    if section != .bookmarks {
                                        controller.selectedTestament = section.rawValue
                                    }
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Text(section == .bookmarks ? "Saved" : section.rawValue.replacingOccurrences(of: " Testament", with: ""))
                                        .font(.subheadline)
                                        .fontWeight(selectedSection == section ? .semibold : .regular)
                                        .foregroundStyle(selectedSection == section ? .primary : .secondary)
                                    
                                    Rectangle()
                                        .fill(selectedSection == section ? Color.blue : Color.clear)
                                        .frame(height: 3)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.top, 8)
                    Divider()
                }
                
                if isSearching {
                    // 🔍 Search Results View
                    if searchResults.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("No results found")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Try searching for another word or phrase.")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxHeight: .infinity)
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(searchResults) { result in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(result.highlightedText(searchText))
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .lineLimit(nil)
                                            .textSelection(.enabled)
                                        
                                        Text("\(result.bookName) \(result.chapter):\(result.verse)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        navigateTo(result)
                                        isSearching = false
                                        searchText = ""
                                    }
                                    Divider()
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                } else {
                    // 📖 Normal Bible Feed (your original UI)
                    if selectedSection == .bookmarks {
                        BookmarksSection()
                    } else {
                        BibleReadingSection()
                    }
                }
            }
            .navigationTitle(isSearching ? "Search" : (selectedSection == .bookmarks ? "Saved" : controller.selectedBook.name))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search the Bible")
            .onChange(of: searchText) { _, newValue in
                isSearching = !newValue.isEmpty
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCompatibilitySheet = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showCompatibilitySheet) {
                CompatibilityInfoSheet()
            }
            .onAppear {
                loadBookmarks()
                if !hasShownCompatibilitySheet {
                    showCompatibilitySheet = true
                    hasShownCompatibilitySheet = true
                }
            }
        }
    }
}


// MARK: - Temporary helpers to satisfy the compiler
private extension FreeBibleFeedView {
    private func navigateTo(_ result: SearchResult) {
        if let testament = controller.bible.testaments.first(where: {
            $0.books.contains(where: { $0.name == result.bookName })
        }) {
            controller.selectedTestament = testament.name
            selectedSection = testament.name == "Old Testament" ? .oldTestament : .newTestament
            
            if let book = testament.books.first(where: { $0.name == result.bookName }) {
                controller.selectBook(book)
                
                if let chapter = book.chapters.first(where: { $0.chapter == result.chapter }) {
                    controller.selectedChapter = chapter
                    if let idx = book.chapters.firstIndex(where: { $0.chapter == result.chapter }) {
                        selectedChapterIndex = idx
                    }
                    
                    // 👇 Now scroll to the verse
                    if let verse = chapter.verses.first(where: { $0.verse == result.verse }) {
                        // Use DispatchQueue to allow SwiftUI to render the new chapter first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedVerse = verse
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func BookmarksSection() -> some View {
        // Bookmarks View
        if bookmarkedVerses.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "bookmark")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                Text("No saved verses yet")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Tap the bookmark icon on any verse to save it")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxHeight: .infinity)
            .padding()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(bookmarkedVerses) { bookmark in
                        BookmarkedVerseCell(
                            bookmark: bookmark,
                            onTap: {
                                // Navigate to the verse
                                navigateToVerse(bookmark)
                            },
                            onDelete: {
                                deleteBookmark(bookmark)
                            }
                        )
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func BibleReadingSection() -> some View {
        // Bible Reading View
        VStack(spacing: 0) {
            // Book Picker
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(controller.currentBooks, id: \.name) { book in
                            Button {
                                withAnimation(.easeInOut) {
                                    controller.selectBook(book)
                                }
                            } label: {
                                Text(book.name)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        controller.selectedBook.name == book.name
                                        ? Color.blue.opacity(0.2)
                                        : Color.gray.opacity(0.1)
                                    )
                                    .clipShape(Capsule())
                            }
                            .id(book.name) // 👈 This makes it scrollable by name
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                // 👇 Whenever the selected book changes, scroll it into view at leading edge
                .onChange(of: controller.selectedBook.name) { _, newValue in
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(newValue, anchor: .leading)
                    }
                }
            }
            
            
            // Chapter Picker
            if !controller.selectedBook.chapters.isEmpty {
                HStack {
                    Menu {
                        ForEach(Array(controller.selectedBook.chapters.enumerated()), id: \.offset) { index, chapter in
                            Button(action: {
                                selectedChapterIndex = index
                                let chapters = controller.selectedBook.chapters
                                if chapters.indices.contains(index) {
                                    controller.selectedChapter = chapters[index]
                                }
                            }) {
                                Text("Chapter \(chapter.chapter)")
                            }
                        }
                    } label: {
                        HStack {
                            Text("Chapter \(controller.selectedChapter.chapter)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                    }
                    .padding(.leading)
                    .onChange(of: selectedChapterIndex) { _, newValue in
                        let chapters = controller.selectedBook.chapters
                        if chapters.indices.contains(newValue) {
                            controller.selectedChapter = chapters[newValue]
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // Verses Feed
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(controller.selectedChapter.verses, id: \.verse) { verse in
                            FreeVerseCell(
                                verse: verse,
                                book: controller.selectedBook,
                                chapter: controller.selectedChapter,
                                isBookmarked: isBookmarked(verse),
                                onBookmark: {
                                    toggleBookmark(verse)
                                }
                            )
                            .id(verse.verse) // 👈 Add this line
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                // Scroll to the top verse whenever chapter changes
                .onChange(of: selectedChapterIndex) {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(controller.selectedChapter.verses.first?.verse, anchor: .top)
                    }
                }
                .onChange(of: selectedVerse?.verse) { _, newValue in
                    if let verseNumber = newValue {
                        withAnimation {
                            proxy.scrollTo(verseNumber, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    private func isBookmarked(_ verse: Verse) -> Bool {
        bookmarkedVerses.contains { bookmark in
            bookmark.verseNumber == verse.verse &&
            bookmark.bookName == controller.selectedBook.name &&
            bookmark.chapterNumber == controller.selectedChapter.chapter
        }
    }
    
    private func toggleBookmark(_ verse: Verse) {
        if let existing = bookmarkedVerses.first(where: {
            $0.verseNumber == verse.verse &&
            $0.bookName == controller.selectedBook.name &&
            $0.chapterNumber == controller.selectedChapter.chapter
        }) {
            modelContext.delete(existing)
        } else {
            let bookmark = BookmarkedVerse(
                verse: verse,
                book: controller.selectedBook,
                chapter: controller.selectedChapter
            )
            modelContext.insert(bookmark)
        }
        
        try? modelContext.save()
        loadBookmarks()
    }
    
    private func deleteBookmark(_ bookmark: BookmarkedVerse) {
        modelContext.delete(bookmark)
        try? modelContext.save()
        loadBookmarks()
    }
    
    private func loadBookmarks() {
        let descriptor = FetchDescriptor<BookmarkedVerse>(
            sortBy: [SortDescriptor(\BookmarkedVerse.timestamp, order: .reverse)]
        )
        
        if let fetched = try? modelContext.fetch(descriptor) {
            bookmarkedVerses = fetched
        }
    }
    
    private func navigateToVerse(_ bookmark: BookmarkedVerse) {
        // Find the testament
        if let testament = controller.bible.testaments.first(where: { testament in
            testament.books.contains(where: { $0.name == bookmark.bookName })
        }) {
            controller.selectedTestament = testament.name
            selectedSection = testament.name == "Old Testament" ? .oldTestament : .newTestament
            
            // Find and select the book
            if let book = testament.books.first(where: { $0.name == bookmark.bookName }) {
                controller.selectBook(book)
                
                // Find and select the chapter
                if let chapter = book.chapters.first(where: { $0.chapter == bookmark.chapterNumber }) {
                    controller.selectedChapter = chapter
                    if let idx = book.chapters.firstIndex(where: { $0.chapter == bookmark.chapterNumber }) {
                        selectedChapterIndex = idx
                    }
                }
            }
        }
    }
}

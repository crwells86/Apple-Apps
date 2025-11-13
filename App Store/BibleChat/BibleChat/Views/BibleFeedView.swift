//import SwiftUI
//import SwiftData
//
//struct BibleFeedView: View {
//    @Environment(\.modelContext) private var modelContext
//    @State private var controller: BibleController
//    @State private var selectedVerse: Verse?
//    @State private var selectedChapterIndex: Int = 0
//    @State private var selectedSection: FeedSection = .oldTestament
//    @State private var bookmarkedVerses: [BookmarkedVerse] = []
//
//    init(modelContext: ModelContext) {
//        _controller = State(initialValue: BibleController(modelContext: modelContext))
//
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
//                // Section Picker
//                HStack(spacing: 0) {
//                    ForEach(FeedSection.allCases, id: \.self) { section in
//                        Button {
//                            withAnimation(.easeInOut(duration: 0.2)) {
//                                selectedSection = section
//                                if section != .bookmarks {
//                                    controller.selectedTestament = section.rawValue
//                                }
//                            }
//                        } label: {
//                            VStack(spacing: 8) {
//                                Text(section == .bookmarks ? "Saved" : section.rawValue.replacingOccurrences(of: " Testament", with: ""))
//                                    .font(.subheadline)
//                                    .fontWeight(selectedSection == section ? .semibold : .regular)
//                                    .foregroundStyle(selectedSection == section ? .primary : .secondary)
//
//                                Rectangle()
//                                    .fill(selectedSection == section ? Color.blue : Color.clear)
//                                    .frame(height: 3)
//                            }
//                            .frame(maxWidth: .infinity)
//                        }
//                    }
//                }
//                .padding(.top, 8)
//
//                Divider()
//
//                if selectedSection == .bookmarks {
//                    // Bookmarks View
//                    if bookmarkedVerses.isEmpty {
//                        VStack(spacing: 16) {
//                            Image(systemName: "bookmark")
//                                .font(.system(size: 50))
//                                .foregroundStyle(.secondary)
//                            Text("No saved verses yet")
//                                .font(.title3)
//                                .foregroundStyle(.secondary)
//                            Text("Tap the bookmark icon on any verse to save it")
//                                .font(.subheadline)
//                                .foregroundStyle(.tertiary)
//                                .multilineTextAlignment(.center)
//                        }
//                        .frame(maxHeight: .infinity)
//                        .padding()
//                    } else {
//                        ScrollView {
//                            LazyVStack(spacing: 0) {
//                                ForEach(bookmarkedVerses) { bookmark in
//                                    BookmarkedVerseCell(
//                                        bookmark: bookmark,
//                                        onTap: {
//                                            // Navigate to the verse
//                                            navigateToVerse(bookmark)
//                                        },
//                                        onDelete: {
//                                            deleteBookmark(bookmark)
//                                        }
//                                    )
//                                    Divider()
//                                        .padding(.leading, 60)
//                                }
//                            }
//                        }
//                    }
//                } else {
//                    // Bible Reading View
//                    VStack(spacing: 0) {
//                        // Book Picker
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            HStack(spacing: 12) {
//                                ForEach(controller.currentBooks, id: \.name) { book in
//                                    Button {
//                                        controller.selectBook(book)
//                                    } label: {
//                                        Text(book.name)
//                                            .font(.subheadline)
//                                            .padding(.horizontal, 12)
//                                            .padding(.vertical, 8)
//                                            .background(
//                                                controller.selectedBook.name == book.name
//                                                ? Color.blue.opacity(0.2)
//                                                : Color.gray.opacity(0.1)
//                                            )
//                                            .clipShape(Capsule())
//                                    }
//                                }
//                            }
//                            .padding(.horizontal)
//                            .padding(.vertical, 8)
//                        }
//
//                        // Chapter Picker
//                        if !controller.selectedBook.chapters.isEmpty {
//                            HStack {
//                                Menu {
//                                    ForEach(Array(controller.selectedBook.chapters.enumerated()), id: \.offset) { index, chapter in
//                                        Button(action: {
//                                            selectedChapterIndex = index
//                                            let chapters = controller.selectedBook.chapters
//                                            if chapters.indices.contains(index) {
//                                                controller.selectedChapter = chapters[index]
//                                            }
//                                        }) {
//                                            Text("Chapter \(chapter.chapter)")
//                                        }
//                                    }
//                                } label: {
//                                    HStack {
//                                        Text("Chapter \(controller.selectedChapter.chapter)")
//                                            .font(.subheadline)
//                                            .fontWeight(.medium)
//                                        Image(systemName: "chevron.down")
//                                            .font(.caption)
//                                    }
//                                    .foregroundStyle(.blue)
//                                }
//                                .padding(.leading)
//                                .onChange(of: selectedChapterIndex) { _, newValue in
//                                    let chapters = controller.selectedBook.chapters
//                                    if chapters.indices.contains(newValue) {
//                                        controller.selectedChapter = chapters[newValue]
//                                    }
//                                }
//
//                                Spacer()
//                            }
//                            .padding(.vertical, 8)
//                        }
//
//                        Divider()
//
//                        // Verses Feed
//                        ScrollView {
//                            LazyVStack(spacing: 0) {
//                                ForEach(controller.selectedChapter.verses, id: \.verse) { verse in
//                                    VerseCell(
//                                        verse: verse,
//                                        book: controller.selectedBook,
//                                        chapter: controller.selectedChapter,
//                                        isBookmarked: isBookmarked(verse),
//                                        onTap: {
//                                            selectedVerse = verse
//                                        },
//                                        onBookmark: {
//                                            toggleBookmark(verse)
//                                        }
//                                    )
//                                    Divider()
//                                        .padding(.leading, 60)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            .navigationTitle(selectedSection == .bookmarks ? "Saved" : controller.selectedBook.name)
//            .navigationBarTitleDisplayMode(.inline)
//            .onChange(of: controller.selectedBook.name) { _, _ in
//                let chapters = controller.selectedBook.chapters
//                if let idx = chapters.firstIndex(where: { $0.chapter == controller.selectedChapter.chapter }) {
//                    selectedChapterIndex = idx
//                } else {
//                    selectedChapterIndex = 0
//                    if let first = chapters.first { controller.selectedChapter = first }
//                }
//            }
//            .sheet(item: $selectedVerse) { verse in
//                VerseChatSheet(
//                    verse: verse,
//                    book: controller.selectedBook,
//                    chapter: controller.selectedChapter,
//                    bible: controller.bible,
//                    modelContext: modelContext
//                )
//            }
//            .onAppear {
//                loadBookmarks()
//                let chapters = controller.selectedBook.chapters
//                if let idx = chapters.firstIndex(where: { $0.chapter == controller.selectedChapter.chapter }) {
//                    selectedChapterIndex = idx
//                } else {
//                    selectedChapterIndex = 0
//                }
//            }
//        }
//    }
//
//    private func isBookmarked(_ verse: Verse) -> Bool {
//        bookmarkedVerses.contains { bookmark in
//            bookmark.verseNumber == verse.verse &&
//            bookmark.bookName == controller.selectedBook.name &&
//            bookmark.chapterNumber == controller.selectedChapter.chapter
//        }
//    }
//
//    private func toggleBookmark(_ verse: Verse) {
//        if let existing = bookmarkedVerses.first(where: {
//            $0.verseNumber == verse.verse &&
//            $0.bookName == controller.selectedBook.name &&
//            $0.chapterNumber == controller.selectedChapter.chapter
//        }) {
//            modelContext.delete(existing)
//        } else {
//            let bookmark = BookmarkedVerse(
//                verse: verse,
//                book: controller.selectedBook,
//                chapter: controller.selectedChapter
//            )
//            modelContext.insert(bookmark)
//        }
//
//        try? modelContext.save()
//        loadBookmarks()
//    }
//
//    private func deleteBookmark(_ bookmark: BookmarkedVerse) {
//        modelContext.delete(bookmark)
//        try? modelContext.save()
//        loadBookmarks()
//    }
//
//    private func loadBookmarks() {
//        let descriptor = FetchDescriptor<BookmarkedVerse>(
//            sortBy: [SortDescriptor(\BookmarkedVerse.timestamp, order: .reverse)]
//        )
//
//        if let fetched = try? modelContext.fetch(descriptor) {
//            bookmarkedVerses = fetched
//        }
//    }
//
//    private func navigateToVerse(_ bookmark: BookmarkedVerse) {
//        // Find the testament
//        if let testament = controller.bible.testaments.first(where: { testament in
//            testament.books.contains(where: { $0.name == bookmark.bookName })
//        }) {
//            controller.selectedTestament = testament.name
//            selectedSection = testament.name == "Old Testament" ? .oldTestament : .newTestament
//
//            // Find and select the book
//            if let book = testament.books.first(where: { $0.name == bookmark.bookName }) {
//                controller.selectBook(book)
//
//                // Find and select the chapter
//                if let chapter = book.chapters.first(where: { $0.chapter == bookmark.chapterNumber }) {
//                    controller.selectedChapter = chapter
//                    if let idx = book.chapters.firstIndex(where: { $0.chapter == bookmark.chapterNumber }) {
//                        selectedChapterIndex = idx
//                    }
//                }
//            }
//        }
//    }
//}



import SwiftUI
import SwiftData

// MARK: - Scripture Reference Parser
struct ScriptureReference {
    let bookName: String
    let chapter: Int
    let verse: Int?
    
    static func parse(_ reference: String) -> ScriptureReference? {
        // Examples: "John 3:16", "Genesis 1:1", "Romans 8:28-30", "Psalm 23"
        let trimmed = reference.trimmingCharacters(in: .whitespaces)
        
        // Split by colon to separate book/chapter from verse
        let parts = trimmed.components(separatedBy: ":")
        
        if parts.count == 2 {
            // Has verse: "John 3:16"
            let bookChapter = parts[0].trimmingCharacters(in: .whitespaces)
            let versePart = parts[1].trimmingCharacters(in: .whitespaces)
            
            // Extract verse number (handle ranges like "28-30" by taking first number)
            let verseComponents = versePart.components(separatedBy: CharacterSet(charactersIn: "-–—, "))
            guard let verseNum = Int(verseComponents[0]) else { return nil }
            
            // Split book and chapter
            let bookChapterParts = bookChapter.components(separatedBy: " ")
            guard let chapterStr = bookChapterParts.last,
                  let chapterNum = Int(chapterStr) else { return nil }
            
            let bookName = bookChapterParts.dropLast().joined(separator: " ")
            
            return ScriptureReference(bookName: bookName, chapter: chapterNum, verse: verseNum)
            
        } else if parts.count == 1 {
            // No verse, just chapter: "Psalm 23"
            let bookChapter = trimmed
            let bookChapterParts = bookChapter.components(separatedBy: " ")
            guard let chapterStr = bookChapterParts.last,
                  let chapterNum = Int(chapterStr) else { return nil }
            
            let bookName = bookChapterParts.dropLast().joined(separator: " ")
            
            return ScriptureReference(bookName: bookName, chapter: chapterNum, verse: nil)
        }
        
        return nil
    }
}

// MARK: - Updated Chat Bubble View
struct ChatBubbleView: View {
    let message: ChatMessage
    
    let userBubble = UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: 0, topTrailingRadius: 8, style: .continuous)
    let aiBubble = UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 0, bottomTrailingRadius: 8, topTrailingRadius: 8, style: .continuous)
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.blue.opacity(0.27) : Color(.clear))
                    .clipShape(message.isUser ? userBubble : aiBubble)
                    .glassEffect(in: message.isUser ? userBubble : aiBubble)
                    .foregroundStyle(message.isUser ? .white : .primary)
                
                if !message.scriptureReferences.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(message.scriptureReferences, id: \.self) { ref in
                                Button(action: { openReference(ref) }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "book.closed")
                                            .font(.caption2)
                                        Text(ref)
                                            .font(.caption2)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .glassEffect()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            
            if !message.isUser { Spacer() }
        }
    }
    
    private func openReference(_ ref: String) {
        // Post the reference string to be handled by the Bible tab
        NotificationCenter.default.post(
            name: Notification.Name("OpenScriptureReference"),
            object: ref
        )
    }
}

// MARK: - Updated Bible Feed View with Reference Navigation
extension BibleFeedView {
    func setupReferenceNavigation() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("OpenScriptureReference"),
            object: nil,
            queue: .main
        ) { notification in
            guard let referenceString = notification.object as? String,
                  let reference = ScriptureReference.parse(referenceString) else {
                print("⚠️ Could not parse reference: \(notification.object ?? "nil")")
                return
            }
            
            navigateToReference(reference)
        }
    }
    
    private func navigateToReference(_ reference: ScriptureReference) {
        // Find the testament containing this book
        guard let testament = controller.bible.testaments.first(where: {
            $0.books.contains(where: { $0.name == reference.bookName })
        }) else {
            print("⚠️ Testament not found for book: \(reference.bookName)")
            return
        }
        
        // Switch to correct testament section
        controller.selectedTestament = testament.name
        selectedSection = testament.name == "Old Testament" ? .oldTestament : .newTestament
        
        // Find and select the book
        guard let book = testament.books.first(where: { $0.name == reference.bookName }) else {
            print("⚠️ Book not found: \(reference.bookName)")
            return
        }
        controller.selectBook(book)
        
        // Find and select the chapter
        guard let chapterIndex = book.chapters.firstIndex(where: {
            $0.chapter == reference.chapter
        }) else {
            print("⚠️ Chapter not found: \(reference.chapter) in \(reference.bookName)")
            return
        }
        controller.selectedChapter = book.chapters[chapterIndex]
        selectedChapterIndex = chapterIndex
        
        // If a specific verse was provided, open it in the chat sheet
        if let verseNumber = reference.verse {
            guard let verse = controller.selectedChapter.verses.first(where: {
                $0.verse == verseNumber
            }) else {
                print("⚠️ Verse not found: \(verseNumber) in \(reference.bookName) \(reference.chapter)")
                return
            }
            
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
                selectedVerse = verse
            }
        }
    }
}

// MARK: - Updated Chat View with Tab Switching
struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var chatAssistant: BibleChatAssistant?
    @State private var messageText = ""
    @State private var isProcessing = false
    
    @State private var storeManager = IAPController()
    @State private var showPaywall = false
    
    @Query(sort: \ChatMessage.timestamp, order: .forward)
    private var messages: [ChatMessage]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            // Show typing indicator when processing
                            if isProcessing && chatAssistant?.currentResponse == nil {
                                TypingIndicatorView()
                                    .id("typing")
                            }
                            
                            if let response = chatAssistant?.currentResponse {
                                let shouldShowStream = messages.last?.isUser != false
                                if shouldShowStream {
                                    StreamingChatBubbleView(response: response)
                                        .id("streaming")
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: isProcessing) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                HStack(spacing: 12) {
                    TextField("Ask about Scripture...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)
                    
                    Button {
                        let gate = AccessGate(storeManager: storeManager, presentPaywall: { self.showPaywall = true })
                        if gate.canSendChatMessage() {
                            sendMessage()
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                    }
                    .disabled(messageText.isEmpty || isProcessing)
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
                .sheet(isPresented: $showPaywall) {
                    PaywallView(storeManager: storeManager)
                }
            }
            .navigationTitle("Bible Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenScriptureReference"))) { note in
            // First switch to Bible tab, then the Bible tab will handle the reference
            NotificationCenter.default.post(
                name: Notification.Name("SwitchToBibleTab"),
                object: note.object
            )
        }
        .task {
            if chatAssistant == nil {
                // Fetch or create the user profile just like in BibleController
                let userFetch = try? modelContext.fetch(FetchDescriptor<UserProfile>())
                let userProfile = userFetch?.first ?? UserProfile()
                
                // Initialize chat assistant with the user profile
                chatAssistant = BibleChatAssistant(modelContext: modelContext, userProfile: userProfile)
            }
            removeDuplicateMessages()
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if isProcessing {
            withAnimation {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        } else if let lastMessage = messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func removeDuplicateMessages() {
        // Remove adjacent duplicates by same role and same content
        var toDelete: [ChatMessage] = []
        var previous: ChatMessage?
        for msg in messages.sorted(by: { $0.timestamp < $1.timestamp }) {
            if let prev = previous, prev.isUser == msg.isUser, prev.content == msg.content {
                toDelete.append(msg)
            } else {
                previous = msg
            }
        }
        toDelete.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty, !isProcessing else { return }
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        messageText = ""
        isProcessing = true
        
        Task {
            await chatAssistant?.sendMessage(message)
            isProcessing = false
        }
    }
}







import SwiftUI
import SwiftData

struct BibleFeedView: View {
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
            // Chat feature
            .sheet(item: $selectedVerse) { verse in
                VerseChatSheet(
                    verse: verse,
                    book: controller.selectedBook,
                    chapter: controller.selectedChapter,
                    bible: controller.bible,
                    modelContext: modelContext
                )
            }
            .onAppear {
                loadBookmarks()
                setupReferenceNavigation()
            }
        }
    }
}

// MARK: - Temporary helpers to satisfy the compiler
private extension BibleFeedView {
    private func navigateTo(_ result: SearchResult) {
        // Select correct testament based on book
        guard let testament = controller.bible.testaments.first(where: { $0.books.contains(where: { $0.name == result.bookName }) }) else { return }
        controller.selectedTestament = testament.name
        selectedSection = testament.name == "Old Testament" ? .oldTestament : .newTestament
        
        // Select the book
        guard let book = testament.books.first(where: { $0.name == result.bookName }) else { return }
        controller.selectBook(book)
        
        // Select the chapter
        guard let chapterIndex = book.chapters.firstIndex(where: { $0.chapter == result.chapter }) else { return }
        controller.selectedChapter = book.chapters[chapterIndex]
        selectedChapterIndex = chapterIndex
        
        // Scroll to the verse once UI updates
        if let verse = controller.selectedChapter.verses.first(where: { $0.verse == result.verse }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                selectedVerse = verse
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
                            VerseCell(
                                verse: verse,
                                book: controller.selectedBook,
                                chapter: controller.selectedChapter,
                                isBookmarked: isBookmarked(verse),
                                onTap: {
                                    selectedVerse = verse
                                },
                                onBookmark: {
                                    toggleBookmark(verse)
                                }
                            )
                            .id(verse.verse)
                            
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
        guard let testament = controller.bible.testaments.first(where: {
            $0.books.contains(where: { $0.name == bookmark.bookName })
        }) else {
            print("⚠️ Testament not found for book: \(bookmark.bookName)")
            return
        }
        
        controller.selectedTestament = testament.name
        selectedSection = testament.name == "Old Testament" ? .oldTestament : .newTestament
        
        // Find and select the book
        guard let book = testament.books.first(where: { $0.name == bookmark.bookName }) else {
            print("⚠️ Book not found: \(bookmark.bookName)")
            return
        }
        controller.selectBook(book)
        
        // Find and select the chapter
        guard let chapterIndex = book.chapters.firstIndex(where: {
            $0.chapter == bookmark.chapterNumber
        }) else {
            print("⚠️ Chapter not found: \(bookmark.chapterNumber) in \(bookmark.bookName)")
            return
        }
        controller.selectedChapter = book.chapters[chapterIndex]
        selectedChapterIndex = chapterIndex
        
        // Scroll to the verse once UI updates
        guard let verse = controller.selectedChapter.verses.first(where: {
            $0.verse == bookmark.verseNumber
        }) else {
            print("⚠️ Verse not found: \(bookmark.verseNumber) in \(bookmark.bookName) \(bookmark.chapterNumber)")
            return
        }
        
        // Use a slightly longer delay to ensure UI has fully updated
        // Also wrap in Task to ensure it runs on MainActor
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
            selectedVerse = verse
        }
    }
}

import SwiftUI
import SwiftData
import FoundationModels
import Foundation
import StoreKit

// MARK: - Models

@Model
final class Devotional {
    var id: UUID
    var date: Date
    var title: String
    var content: String
    var scripture: String
    var scriptureReference: String
    var reflection: String
    var prayer: String
    var isCompleted: Bool
    var isBookmarked: Bool
    var createdAt: Date
    
    init(
        date: Date,
        title: String,
        content: String,
        scripture: String,
        scriptureReference: String,
        reflection: String,
        prayer: String
    ) {
        self.id = UUID()
        self.date = date
        self.title = title
        self.content = content
        self.scripture = scripture
        self.scriptureReference = scriptureReference
        self.reflection = reflection
        self.prayer = prayer
        self.isCompleted = false
        self.isBookmarked = false
        self.createdAt = Date()
    }
}

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var scriptureReferences: [String]
    
    init(content: String, isUser: Bool, scriptureReferences: [String] = []) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.scriptureReferences = scriptureReferences
    }
}

@Model
final class UserProgress {
    var id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var totalDevotionals: Int
    var lastCompletedDate: Date?
    var favoriteVerses: [String]
    
    init() {
        self.id = UUID()
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalDevotionals = 0
        self.lastCompletedDate = nil
        self.favoriteVerses = []
    }
}

// MARK: - Generable Structs
@Generable
struct DevotionalContent {
    @Guide(description: "An inspiring, engaging title for the devotional")
    let title: String
    
    @Guide(description: "The complete Bible verse text")
    let scripture: String
    
    @Guide(description: "The Bible reference (e.g., 'John 3:16', 'Psalm 23:1-3')")
    let scriptureReference: String
    
    @Guide(description: "The main devotional content, 300-400 words of thoughtful biblical reflection and practical application")
    let content: String
    
    @Guide(description: "Thought-provoking reflection questions for personal meditation")
    let reflection: String
    
    @Guide(description: "A heartfelt closing prayer related to the devotional theme")
    let prayer: String
    
    static let example = DevotionalContent(
        title: "Finding Peace in the Storm",
        scripture: "Peace I leave with you; my peace I give you. I do not give to you as the world gives. Do not let your hearts be troubled and do not be afraid.",
        scriptureReference: "John 14:27",
        content: """
        In the midst of life's uncertainties, Jesus offers us something the world cannot: His perfect peace. This isn't a peace dependent on circumstances or the absence of trouble. It's a deep, abiding peace that transcends understanding.
        
        When storms rage around us, we often search for stability in temporary solutions. But Christ's peace is different. It's rooted in His unchanging character and His sovereign control over all things. This peace doesn't mean we won't face challenges, but it does mean we don't face them alone.
        
        Today, whatever storm you're facing, remember that Jesus walks with you through it. His peace is available to you right now, not as the world gives, but as only He can provide—perfect, complete, and unwavering.
        """,
        reflection: """
        What situations in your life are causing your heart to be troubled today? How can you invite Christ's peace into those specific areas? What would it look like to trust Him more fully with your worries?
        """,
        prayer: """
        Dear Lord, thank You for Your gift of peace that surpasses all understanding. Help me to trust You more deeply today, knowing that You are in control of every circumstance I face. Replace my anxiety with Your peace, and help me to rest in Your presence. In Jesus' name, Amen.
        """
    )
}

@Generable
struct ChatResponse {
    @Guide(description: "A thoughtful, biblically-grounded answer to the user's question")
    let answer: String
    
    @Guide(description: "List of relevant Bible verse references cited in the answer (e.g., ['John 3:16', 'Romans 8:28'])")
    let scriptureReferences: [String]
}

// MARK: - ViewModels
@Observable
@MainActor
final class DevotionalGenerator {
    var error: Error?
    private var session: LanguageModelSession
    private(set) var devotional: DevotionalContent.PartiallyGenerated?
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        let instructions = Instructions {
            """
            You are a thoughtful Christian devotional writer who creates meaningful 
            daily devotionals based on Scripture. Your devotionals should be:
            
            - Biblically grounded and theologically sound
            - Encouraging and practical for daily life
            - Personal and relatable
            - Around 300-400 words in total
            - Include a specific Bible verse with reference
            - Provide thoughtful reflection questions
            - End with a heartfelt prayer
            
            Structure each devotional with:
            1. An engaging title that captures the theme
            2. A relevant Bible verse with its reference
            3. Devotional content that explains and applies the verse to daily life
            4. A reflection section with thought-provoking questions
            5. A closing prayer that relates to the theme
            """
        }
        
        self.session = LanguageModelSession(instructions: instructions)
    }
    
    func generateDailyDevotional(theme: String? = nil) async {
        do {
            let prompt = Prompt {
                if let theme = theme {
                    "Generate a daily devotional focused on the theme: \(theme)"
                } else {
                    "Generate an uplifting daily devotional for today"
                }
                "Here is an example of the desired format, but don't copy its content:"
                DevotionalContent.example
            }
            
            let stream = session.streamResponse(
                to: prompt,
                generating: DevotionalContent.self,
                includeSchemaInPrompt: false
            )
            
            for try await partialResponse in stream {
                self.devotional = partialResponse.content
            }
            
            if let title = self.devotional?.title,
               let scripture = self.devotional?.scripture,
               let reference = self.devotional?.scriptureReference,
               let content = self.devotional?.content,
               let reflection = self.devotional?.reflection,
               let prayer = self.devotional?.prayer {
                let finalDevotional = DevotionalContent(
                    title: title,
                    scripture: scripture,
                    scriptureReference: reference,
                    content: content,
                    reflection: reflection,
                    prayer: prayer
                )
                saveDevotional(finalDevotional)
            }
            
        } catch {
            self.error = error
        }
    }
    
    private func saveDevotional(_ content: DevotionalContent) {
        let devotional = Devotional(
            date: Date(),
            title: content.title,
            content: content.content,
            scripture: content.scripture,
            scriptureReference: content.scriptureReference,
            reflection: content.reflection,
            prayer: content.prayer
        )
        
        modelContext.insert(devotional)
        
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }
    
    func prewarmModel() {
        session.prewarm()
    }
}


//@Observable
//@MainActor
//final class BibleChatAssistant {
//    var error: Error?
//    private var session: LanguageModelSession
//    private(set) var currentResponse: ChatResponse.PartiallyGenerated?
//    private var modelContext: ModelContext
//    
//    init(modelContext: ModelContext) {
//        self.modelContext = modelContext
//        
//        let instructions = Instructions { """
//        You are a warm knowledgeable, compassionate and friendly Bible companion. Keep ALL responses under 227 characters - like texting a friend.
//                
//        Be conversational, warm, and brief. Use short sentences. No long paragraphs.
//        When discussing Bible features, mention them naturally without preaching or being judgmental.
//        
//        - Help users understand Scripture in its context
//        - Provide thoughtful answers to theological questions
//        - Offer relevant Bible verses for life situations
//        - Encourage spiritual growth and reflection
//        - Always be respectful, grace-filled, and doctrinally sound
//                    
//        When answering:
//        - Cite specific Bible verses when relevant
//        - Explain historical and cultural context when helpful
//        - Acknowledge different interpretations when appropriate
//        - Point users toward Scripture as the ultimate authority
//        - Be concise but thorough in your responses
//        """
//        }
//        
//        self.session = LanguageModelSession(instructions: instructions)
//    }
//    
//    func sendMessage(_ userMessage: String) async {
//        // Prevent immediate duplicate user messages (e.g., accidental double tap)
//        if let last = try? modelContext.fetch(FetchDescriptor<ChatMessage>(sortBy: [SortDescriptor(\ChatMessage.timestamp, order: .reverse)] )).first,
//           last.isUser, last.content == userMessage {
//            return
//        }
//        
//        let userChatMessage = ChatMessage(content: userMessage, isUser: true)
//        modelContext.insert(userChatMessage)
//        
//        do {
//            let prompt = Prompt {
//                userMessage
//            }
//            
//            let stream = session.streamResponse(
//                to: prompt,
//                generating: ChatResponse.self
//            )
//            
//            for try await partialResponse in stream {
//                self.currentResponse = partialResponse.content
//            }
//            
//            if let answer = self.currentResponse?.answer,
//               let references = self.currentResponse?.scriptureReferences {
//                // Avoid inserting duplicate assistant responses
//                let recent = try? modelContext.fetch(
//                    FetchDescriptor<ChatMessage>(
//                        predicate: #Predicate { !$0.isUser && $0.content == answer },
//                        sortBy: [SortDescriptor(\ChatMessage.timestamp, order: .reverse)]
//                    )
//                )
//                if recent?.isEmpty == false {
//                    // Already have this response saved
//                } else {
//                    let assistantMessage = ChatMessage(
//                        content: answer,
//                        isUser: false,
//                        scriptureReferences: references
//                    )
//                    modelContext.insert(assistantMessage)
//                    try modelContext.save()
//                }
//                // Clear streaming state after persisting the final message
//                self.currentResponse = nil
//            }
//            
//        } catch {
//            self.error = error
//        }
//    }
//    
//    func clearCurrentResponse() {
//        self.currentResponse = nil
//    }
//}

@Observable
@MainActor
final class BibleChatAssistant {
    var error: Error?
    private var session: LanguageModelSession
    private(set) var currentResponse: ChatResponse.PartiallyGenerated?
    private var modelContext: ModelContext
    private let userProfile: UserProfile
    
    init(modelContext: ModelContext, userProfile: UserProfile) {
        self.modelContext = modelContext
        self.userProfile = userProfile
        
        let profileSummary = Self.buildProfileSummary(from: userProfile)
        
        let instructions = Instructions {
            """
            You are a warm, compassionate, and knowledgeable Bible companion helping \(userProfile.name) grow in their faith journey.
            
            User's spiritual profile:
            \(profileSummary)
            
            Style:
            - Keep every reply under 227 characters — like texting a trusted friend.
            - Be gentle, conversational, and full of grace.
            - When appropriate, ask a short reflective follow-up question (e.g., “How does that verse speak to you today?” or “Would you like a verse about peace or strength?”).
            
            Focus:
            - Help users understand Scripture with clarity and heart
            - Provide relevant Bible verses and brief context
            - Encourage reflection, growth, and trust in God
            - Be respectful of personal beliefs and never preachy
            - Keep tone warm, humble, and hopeful
            
            Include verse references naturally (e.g., “That reminds me of Philippians 4:6”).
            Never include markdown, emojis, or long paragraphs.
            """
        }
        
        self.session = LanguageModelSession(instructions: instructions)
    }
    
    // MARK: - Messaging
    
    func sendMessage(_ userMessage: String) async {
        // Avoid duplicate message insertion
        if let last = try? modelContext.fetch(
            FetchDescriptor<ChatMessage>(
                sortBy: [SortDescriptor(\ChatMessage.timestamp, order: .reverse)]
            )
        ).first,
           last.isUser, last.content == userMessage {
            return
        }
        
        let userChatMessage = ChatMessage(content: userMessage, isUser: true)
        modelContext.insert(userChatMessage)
        
        do {
            let prompt = Prompt {
                """
                \(userProfile.name) says: "\(userMessage)"
                
                Context:
                - Current struggles: \(userProfile.struggles)
                - Goals: \(userProfile.goals)
                - Favorite themes: \(userProfile.favoriteVerseThemes)
                
                Respond in under 227 characters, friendly and thoughtful.
                Include a relevant Bible verse if it fits.
                Optionally, end with a gentle follow-up question to keep the chat flowing.
                """
            }
            
            let stream = session.streamResponse(to: prompt, generating: ChatResponse.self)
            
            for try await partialResponse in stream {
                self.currentResponse = partialResponse.content
            }
            
            if let answer = self.currentResponse?.answer,
               let references = self.currentResponse?.scriptureReferences {
                let recent = try? modelContext.fetch(
                    FetchDescriptor<ChatMessage>(
                        predicate: #Predicate { !$0.isUser && $0.content == answer },
                        sortBy: [SortDescriptor(\ChatMessage.timestamp, order: .reverse)]
                    )
                )
                
                if recent?.isEmpty == false {
                    // Avoid duplicate assistant message
                } else {
                    let assistantMessage = ChatMessage(
                        content: answer,
                        isUser: false,
                        scriptureReferences: references
                    )
                    modelContext.insert(assistantMessage)
                    try modelContext.save()
                }
                
                self.currentResponse = nil
            }
        } catch {
            self.error = error
        }
    }
    
    func clearCurrentResponse() {
        self.currentResponse = nil
    }
    
    // MARK: - Helpers
    
    private static func buildProfileSummary(from profile: UserProfile) -> String {
        """
        Name: \(profile.name)
        Struggles: \(profile.struggles.ifEmpty("not specified"))
        Goals: \(profile.goals.ifEmpty("general spiritual growth"))
        Favorite Themes: \(profile.favoriteVerseThemes.ifEmpty("hope, peace, and strength"))
        Prayer Focus Areas: \(profile.prayerFocus.ifEmpty("none listed"))
        """
    }
}

// Helper extension
private extension [String] {
    func ifEmpty(_ fallback: String) -> String {
        self.isEmpty ? fallback : self.joined(separator: ", ")
    }
}


// MARK: - Main Views
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            TabView(selection: $selectedTab) {
                TodayView()
                    .tabItem {
                        Label("Today", systemImage: "sun.max.fill")
                    }
                    .tag(0)
                
                BookmarksView()
                    .tabItem {
                        Label("Bookmarks", systemImage: "bookmark.fill")
                    }
                    .tag(1)
                
                ChatView()
                    .tabItem {
                        Label("Chat", systemImage: "message.fill")
                    }
                    .tag(2)
                
                BibleFeedView(modelContext: modelContext)
                    .tabItem {
                        Label("Bible", systemImage: "book")
                    }
                    .tag(3)
                
                SettingsViewWithSubscription()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SwitchToBibleTab"))) { note in
                self.selectedTab = 3
                if let ref = note.object as? String {
                    NotificationCenter.default.post(name: Notification.Name("BibleFeedNavigateToReference"), object: ref)
                }
            }
        }
    }
}


struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var devotionalGenerator: DevotionalGenerator?
    @State private var isGenerating = false
    @State private var showThemeInput = false
    @State private var customTheme = ""
    @State private var storeManager = IAPController()
    @State private var showPaywall = false
    
    @Query(sort: \Devotional.createdAt, order: .reverse)
    private var allDevotionals: [Devotional]
    
    private var todaysDevotionals: [Devotional] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date().addingTimeInterval(60*60*24)
        
        return allDevotionals.filter { devotional in
            devotional.date >= startOfDay && devotional.date < startOfTomorrow
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today's Devotional")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text(Date.now.formatted(date: .long, time: .omitted))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    if let devotional = todaysDevotionals.first {
                        DevotionalCardView(devotional: devotional)
                            .padding(.horizontal)
                    } else if let partialDevotional = devotionalGenerator?.devotional {
                        StreamingDevotionalView(devotional: partialDevotional)
                            .padding(.horizontal)
                    } else if isGenerating {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Generating your devotional...")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                    } else {
                        EmptyDevotionalView(
                            onGenerate: { generateDevotional() },
                            onCustomTheme: { showThemeInput = true }
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let gate = AccessGate(storeManager: storeManager, presentPaywall: { self.showPaywall = true })
                        if gate.canGenerateDevotional() {
                            showThemeInput = true
                        }
                    } label: {
                        Image(systemName: "sparkles")
                    }
                    .disabled(isGenerating)  // Disable while generating
                }
            }
            .sheet(isPresented: $showThemeInput) {
                ThemeInputSheet(
                    theme: $customTheme,
                    isGenerating: $isGenerating,  // Pass the binding
                    onGenerate: {
                        generateDevotional(theme: customTheme)
                    }
                )
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(storeManager: storeManager)
            }
        }
        .task {
            let generator = DevotionalGenerator(modelContext: modelContext)
            self.devotionalGenerator = generator
            generator.prewarmModel()
        }
    }
    
    private func generateDevotional(theme: String? = nil) {
        let gate = AccessGate(storeManager: storeManager, presentPaywall: { self.showPaywall = true })
        if gate.canGenerateDevotional() {
            isGenerating = true
            Task {
                await devotionalGenerator?.generateDailyDevotional(theme: theme)
                isGenerating = false
                showThemeInput = false  // Dismiss sheet after generation
            }
        } else {
            showPaywall = true
        }
    }
}

// MARK: - Bookmarks View
struct BookmarksView: View {
    @Query(
        filter: #Predicate<Devotional> { $0.isBookmarked == true },
        sort: \Devotional.createdAt,
        order: .reverse
    )
    private var bookmarkedDevotionals: [Devotional]
    
    var body: some View {
        NavigationStack {
            Group {
                if bookmarkedDevotionals.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "bookmark",
                        description: Text("Bookmark your favorite devotionals to find them here")
                    )
                } else {
                    List {
                        ForEach(bookmarkedDevotionals) { devotional in
                            NavigationLink {
                                DevotionalDetailView(devotional: devotional)
                            } label: {
                                DevotionalRowView(devotional: devotional)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bookmarks")
        }
    }
}

// MARK: - Chat View
//struct ChatView: View {
//    @Environment(\.modelContext) private var modelContext
//    @State private var chatAssistant: BibleChatAssistant?
//    @State private var messageText = ""
//    @State private var isProcessing = false
//    
//    @State private var storeManager = IAPController()
//    @State private var showPaywall = false
//    
//    @Query(sort: \ChatMessage.timestamp, order: .forward)
//    private var messages: [ChatMessage]
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 0) {
//                ScrollViewReader { proxy in
//                    ScrollView {
//                        LazyVStack(spacing: 16) {
//                            ForEach(messages) { message in
//                                ChatBubbleView(message: message)
//                                    .id(message.id)
//                            }
//                            
//                            // Show typing indicator when processing
//                            if isProcessing && chatAssistant?.currentResponse == nil {
//                                TypingIndicatorView()
//                                    .id("typing")
//                            }
//                            
//                            if let response = chatAssistant?.currentResponse {
//                                let shouldShowStream = messages.last?.isUser != false
//                                if shouldShowStream {
//                                    StreamingChatBubbleView(response: response)
//                                        .id("streaming")
//                                }
//                            }
//                        }
//                        .padding()
//                    }
//                    .onChange(of: messages.count) { _, _ in
//                        scrollToBottom(proxy: proxy)
//                    }
//                    .onChange(of: isProcessing) { _, _ in
//                        scrollToBottom(proxy: proxy)
//                    }
//                }
//                
//                HStack(spacing: 12) {
//                    TextField("Ask about Scripture...", text: $messageText, axis: .vertical)
//                        .textFieldStyle(.roundedBorder)
//                        .lineLimit(1...5)
//                    
//                    Button {
//                        let gate = AccessGate(storeManager: storeManager, presentPaywall: { self.showPaywall = true })
//                        if gate.canSendChatMessage() {
//                            sendMessage()
//                        }
//                    } label: {
//                        Image(systemName: "arrow.up.circle.fill")
//                            .font(.system(size: 32))
//                    }
//                    .disabled(messageText.isEmpty || isProcessing)
//                }
//                .padding()
//                .background(Color(uiColor: .systemBackground))
//                .sheet(isPresented: $showPaywall) {
//                    PaywallView(storeManager: storeManager)
//                }
//            }
//            .navigationTitle("Bible Chat")
//            .navigationBarTitleDisplayMode(.inline)
//        }
//        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenScriptureReference"))) { note in
//            NotificationCenter.default.post(name: Notification.Name("SwitchToBibleTab"), object: note.object)
//        }
//        .task {
//            if chatAssistant == nil {
//                chatAssistant = BibleChatAssistant(modelContext: modelContext)
//            }
//            removeDuplicateMessages()
//        }
//    }
//    
//    private func scrollToBottom(proxy: ScrollViewProxy) {
//        if isProcessing {
//            withAnimation {
//                proxy.scrollTo("typing", anchor: .bottom)
//            }
//        } else if let lastMessage = messages.last {
//            withAnimation {
//                proxy.scrollTo(lastMessage.id, anchor: .bottom)
//            }
//        }
//    }
//    
//    private func removeDuplicateMessages() {
//        // Remove adjacent duplicates by same role and same content
//        var toDelete: [ChatMessage] = []
//        var previous: ChatMessage?
//        for msg in messages.sorted(by: { $0.timestamp < $1.timestamp }) {
//            if let prev = previous, prev.isUser == msg.isUser, prev.content == msg.content {
//                toDelete.append(msg)
//            } else {
//                previous = msg
//            }
//        }
//        toDelete.forEach { modelContext.delete($0) }
//        try? modelContext.save()
//    }
//    
//    private func sendMessage() {
//        guard !messageText.isEmpty, !isProcessing else { return }
//        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !message.isEmpty else { return }
//        
//        messageText = ""
//        isProcessing = true
//        
//        Task {
//            await chatAssistant?.sendMessage(message)
//            isProcessing = false
//        }
//    }
//}

import Combine

struct TypingIndicatorView: View {
    @State private var numberOfDots = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "book.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.gray)
                        .frame(width: 8, height: 8)
                        .opacity(index < numberOfDots ? 1 : 0.3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemGray6))
            .cornerRadius(20)
            
            Spacer()
        }
        .onReceive(timer) { _ in
            numberOfDots = (numberOfDots + 1) % 4
        }
    }
}

// MARK: - Supporting Views
struct EmptyDevotionalView: View {
    let onGenerate: () -> Void
    let onCustomTheme: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
            
            Text("Start Your Day with Scripture")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Generate a personalized devotional to begin your spiritual journey today")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button(action: onGenerate) {
                Label("Generate Devotional", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.gradient)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Button(action: onCustomTheme) {
                Label("Custom Theme", systemImage: "slider.horizontal.3")
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 40)
    }
}

struct StreamingDevotionalView: View {
    let devotional: DevotionalContent.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = devotional.title {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .contentTransition(.opacity)
            }
            
            if let scripture = devotional.scripture,
               let reference = devotional.scriptureReference {
                VStack(alignment: .leading, spacing: 8) {
                    Text(scripture)
                        .font(.body)
                        .italic()
                        .contentTransition(.opacity)
                    
                    Text(reference)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .contentTransition(.opacity)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
            }
            
            if let content = devotional.content {
                Text(content)
                    .font(.body)
                    .lineSpacing(6)
                    .contentTransition(.opacity)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 10, y: 5)
    }
}

//struct ChatBubbleView: View {
//    let message: ChatMessage
//    
//    var body: some View {
//        HStack {
//            if message.isUser { Spacer() }
//            
//            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
//                Text(message.content)
//                    .padding(12)
//                    .background(message.isUser ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
//                    .foregroundStyle(message.isUser ? .white : .primary)
//                    .cornerRadius(16)
//                
//                if !message.scriptureReferences.isEmpty {
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 8) {
//                            ForEach(message.scriptureReferences, id: \.self) { ref in
//                                Button(action: { openReference(ref) }) {
//                                    HStack(spacing: 4) {
//                                        Image(systemName: "book.closed")
//                                            .font(.caption2)
//                                        Text(ref)
//                                            .font(.caption2)
//                                    }
//                                    .padding(.horizontal, 10)
//                                    .padding(.vertical, 6)
//                                    .background(Color.accentColor.opacity(0.12))
//                                    .clipShape(Capsule())
//                                }
//                                .buttonStyle(.plain)
//                            }
//                        }
//                    }
//                }
//            }
//            
//            if !message.isUser { Spacer() }
//        }
//    }
//    
//    private func openReference(_ ref: String) {
//        NotificationCenter.default.post(name: Notification.Name("OpenScriptureReference"), object: ref)
//    }
//}

struct StreamingChatBubbleView: View {
    let response: ChatResponse.PartiallyGenerated
    
    var body: some View {
        HStack {
            if let answer = response.answer {
                VStack(alignment: .leading, spacing: 4) {
                    Text(answer)
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .cornerRadius(16)
                        .contentTransition(.opacity)
                }
            }
            Spacer()
        }
    }
}

struct DevotionalRowView: View {
    let devotional: Devotional
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(devotional.title)
                    .font(.headline)
                
                Text(devotional.scriptureReference)
                    .font(.caption)
                
                Text(devotional.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if devotional.isBookmarked {
                Image(systemName: "bookmark.fill")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DevotionalDetailView: View {
    let devotional: Devotional
    
    var body: some View {
        ScrollView {
            DevotionalCardView(devotional: devotional)
                .padding()
        }
        .navigationTitle("Devotional")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Query private var progress: [UserProgress]
    @Environment(\.modelContext) private var modelContext
    
    private var userProgress: UserProgress {
        if let existing = progress.first {
            return existing
        } else {
            let newProgress = UserProgress()
            modelContext.insert(newProgress)
            try? modelContext.save()
            return newProgress
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: openFeedbackEmail) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .frame(width: 28)
                            Text("Send Feedback")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button(action: requestAppReview) {
                        HStack {
                            Image(systemName: "star.fill")
                                .frame(width: 28)
                            Text("Rate App")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func openFeedbackEmail() {
        if let url = URL(string: "mailto:caleb@olyevolutions.com?subject=Bible%20Feedback") {
            UIApplication.shared.open(url)
        }
    }
    
    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
    }
}

// MARK: - Devotional Card View
struct DevotionalCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var devotional: Devotional
    
    @State private var storeManager = IAPController()
    @State private var showPaywall = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(devotional.title)
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(devotional.scripture)
                    .font(.body)
                    .italic()
                    .foregroundStyle(.primary)
                
                Text(devotional.scriptureReference)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(12)
            
            Text(devotional.content)
                .font(.body)
                .lineSpacing(6)
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Reflection", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                
                Text(devotional.reflection)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.1))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Prayer", systemImage: "hands.sparkles.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                
                Text(devotional.prayer)
                    .font(.body)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.blue.opacity(0.1))
            .cornerRadius(12)
            
            HStack(spacing: 12) {
                Spacer()
                
                Button {
                    let gate = AccessGate(storeManager: storeManager, presentPaywall: { self.showPaywall = true })
                    if gate.canBookmark() {
                        devotional.isBookmarked.toggle()
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to save bookmark: \(error)")
                        }
                    }
                } label: {
                    Image(systemName: devotional.isBookmarked ? "bookmark.fill" : "bookmark")
                }
                
                
                Button {
                    shareDevotional()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.red)
            .padding(.top, 8)
            .sheet(isPresented: $showPaywall) {
                PaywallView(storeManager: storeManager)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 10, y: 5)
    }
    
    private func shareDevotional() {
        let text = """
        \(devotional.title)
        
        \(devotional.scripture)
        - \(devotional.scriptureReference)
        
        \(devotional.content)
        """
        
        let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
}


struct ThemeInputSheet: View {
    @Binding var theme: String
    @Binding var isGenerating: Bool  // Add this binding
    let onGenerate: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Choose a Theme")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter a specific topic or theme for your devotional")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                TextField("e.g., Faith, Hope, Love, Forgiveness", text: $theme)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .disabled(isGenerating)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Themes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(["Faith", "Hope", "Love", "Peace", "Joy", "Forgiveness"], id: \.self) { suggestion in
                            Button {
                                theme = suggestion
                            } label: {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(20)
                            }
                            .disabled(isGenerating)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button {
                    onGenerate()
                } label: {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Generating...")
                        } else {
                            Text("Generate Devotional")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.isEmpty || isGenerating ? Color.secondary : Color.accentColor)
                    .cornerRadius(12)
                }
                .disabled(theme.isEmpty || isGenerating)
                .padding(.horizontal)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isGenerating)
                }
            }
        }
        .interactiveDismissDisabled(isGenerating)  // Prevent dismissing while generating
    }
}





// MARK: - Root View with Onboarding Check


// MARK: - Paywall Gate (for existing users who haven't subscribed)
struct PaywallGateView: View {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    let storeManager: IAPController
    @State private var showPaywall = true
    
    var body: some View {
        ZStack {
            ContentView()
        }
        .onAppear {
            // Show paywall initially if no active subscription
            showPaywall = !storeManager.hasActiveSubscription
        }
        .onChange(of: storeManager.hasActiveSubscription) { _, newValue in
            withAnimation {
                showPaywall = !newValue
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(storeManager: storeManager)
        }
    }
}

// MARK: - Updated ContentView with Settings Integration
// Add this to your existing ContentView's Settings tab:

struct SettingsViewWithSubscription: View {
    @Query private var progress: [UserProgress]
    @Environment(\.modelContext) private var modelContext
    @State private var storeManager = IAPController()
    @State private var showPaywall = false
    
    private var userProgress: UserProgress {
        if let existing = progress.first {
            return existing
        } else {
            let newProgress = UserProgress()
            modelContext.insert(newProgress)
            try? modelContext.save()
            return newProgress
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
//                    StreakStepView()
                
                // Subscription section
                Section {
                    if storeManager.hasActiveSubscription {
                        HStack {
                            Image(systemName: "hands.sparkles.fill")
                                .foregroundStyle(.yellow)
                                .frame(width: 28)
                            VStack(alignment: .leading) {
                                Text("Premium Active")
                                    .font(.headline)
                                Text("Thank you for your support!")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    } else {
                        Button(action: { showPaywall = true }) {
                            HStack {
                                Image(systemName: "hands.sparkles.fill")
                                    .foregroundStyle(.yellow)
                                    .frame(width: 28)
                                VStack(alignment: .leading) {
                                    Text("Upgrade to Premium")
                                        .foregroundStyle(.primary)
                                    Text("Unlock all features")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    if !storeManager.hasActiveSubscription {
                        Button(action: {
                            Task {
                                await storeManager.restorePurchases()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .frame(width: 28)
                                Text("Restore Purchases")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                } header: {
                    Text("Subscription")
                }
                
                Section {
                    Button(action: openFeedbackEmail) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .frame(width: 28)
                            Text("Send Feedback")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button(action: requestAppReview) {
                        HStack {
                            Image(systemName: "star.fill")
                                .frame(width: 28)
                            Text("Rate App")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(storeManager: storeManager)
        }
        .task {
            await storeManager.updatePurchasedProducts()
        }
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func openFeedbackEmail() {
        if let url = URL(string: "mailto:caleb@olyevolutions.com?subject=Bible%20Feedback") {
            UIApplication.shared.open(url)
        }
    }
    
    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
    }
}

// MARK: - Usage Limits (Optional - for free tier limitations)
extension IAPController {
    func canGenerateDevotional(count: Int) -> Bool {
        // Allow unlimited for premium
        if hasActiveSubscription {
            return true
        }
        // Limit to 3 per day for free users
        return count < 3
    }
    
    func canUseBibleChat(count: Int) -> Bool {
        if hasActiveSubscription {
            return true
        }
        // Limit to 10 messages per day for free
        return count < 7
    }
}


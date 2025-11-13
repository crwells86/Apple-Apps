import SwiftUI
import PhotosUI
import SwiftData

//struct QuoteScreen: View {
//    @Environment(\.modelContext) private var modelContext
//    @AppStorage("backgroundImageData") private var backgroundImageData: Data?
//    @AppStorage("showPaywallForFirstTime") private var showPaywallForFirstTime = true
//    @State private var showPhotoSheet = false
//    @State private var backgroundImage: Image = Image("001 Mountains")
//    @Query private var userProfiles: [UserProfile]
//    @State private var storeManager = IAPController()
//    
//    // Dynamic scriptures
//    @State private var scriptures: [(String, String)] = []
//    @State private var isLoading = true
//    @State private var generator: ScriptureGenerator?
//    
//    @State private var currentScriptureIndex = 0
//    
//    var body: some View {
//        ZStack {
//            Group {
//                if let data = backgroundImageData,
//                   let uiImage = UIImage(data: data) {
//                    Image(uiImage: uiImage)
//                        .resizable()
//                        .scaledToFill()
//                        .ignoresSafeArea()
//                } else {
//                    backgroundImage
//                        .resizable()
//                        .scaledToFill()
//                        .ignoresSafeArea()
//                }
//            }
//            
//            LinearGradient(
//                gradient: Gradient(colors: [.black.opacity(0.25), .black.opacity(0.6)]),
//                startPoint: .top,
//                endPoint: .bottom
//            )
//            .ignoresSafeArea()
//            
//            if isLoading {
//                ProgressView("Loading scriptures...")
//                    .tint(.white)
//                    .foregroundColor(.white)
//            } else {
//                ScriptureScrollView(
//                    scriptures: scriptures,
//                    onScriptureChanged: { index in
//                        currentScriptureIndex = index
//                    }
//                )
//                    .ignoresSafeArea()
//            }
//            
//            ControlOverlayView(
//                currentScripture: scriptures.isEmpty ? nil : (
//                    reference: scriptures[currentScriptureIndex].0,
//                    text: scriptures[currentScriptureIndex].1
//                )
//            )
//        }
//        .scrollTargetBehavior(.paging)
//        .scrollIndicators(.hidden)
//        .onAppear {
//            // Generate fresh scriptures every time the screen appears
//            Task {
//                await loadScriptures()
//            }
//        }
//        .sheet(isPresented: $showPaywallForFirstTime) {
//            // Set to false when sheet is dismissed
//            showPaywallForFirstTime = false
//        } content: {
//            PaywallView(storeManager: storeManager)
//        }
//    }
//    
//    private func loadScriptures() async {
//        guard let user = userProfiles.first else {
//            isLoading = false
//            return
//        }
//        
//        // Create or reuse generator
//        if generator == nil {
//            generator = ScriptureGenerator(
//                userProfile: user,
//                bibleController: BibleController(modelContext: modelContext)
//            )
//        }
//        
//        guard let gen = generator else {
//            isLoading = false
//            return
//        }
//        
//        // Always generate new scriptures when screen appears
//        isLoading = true
//        await gen.generateDailyScriptures()
//        scriptures = gen.scriptures
//        isLoading = false
//    }
//}



import SwiftUI
import SwiftData
import StoreKit

struct QuoteScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @AppStorage("backgroundImageData") private var backgroundImageData: Data?
    @AppStorage("showPaywallForFirstTime") private var showPaywallForFirstTime = true
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    @State private var showPhotoSheet = false
    @State private var backgroundImage: Image = Image("001 Mountains")
    @Query private var userProfiles: [UserProfile]
    @Query private var favorites: [FavoriteScripture] // Add query for favorites
    @State private var storeManager = IAPController()
    
    // Dynamic scriptures
    @State private var scriptures: [(String, String)] = []
    @State private var isLoading = true
    @State private var generator: ScriptureGenerator?
    
    @State private var currentScriptureIndex = 0
    
    var body: some View {
        ZStack {
            Group {
                if let data = backgroundImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                } else {
                    backgroundImage
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            }
            
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.25), .black.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading scriptures...")
                    .tint(.white)
                    .foregroundColor(.white)
            } else {
                ScriptureScrollView(
                    scriptures: scriptures,
                    onScriptureChanged: { index in
                        currentScriptureIndex = index
                    }
                )
                    .ignoresSafeArea()
            }
            
            ControlOverlayView(
                currentScripture: scriptures.isEmpty ? nil : (
                    reference: scriptures[currentScriptureIndex].0,
                    text: scriptures[currentScriptureIndex].1
                )
            )
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .onAppear {
            // Generate fresh scriptures every time the screen appears
            Task {
                await loadScriptures()
            }
            
            // Check for review prompt
            checkAndRequestReview()
        }
        .sheet(isPresented: $showPaywallForFirstTime) {
            // Set to false when sheet is dismissed
            showPaywallForFirstTime = false
        } content: {
            PaywallView(storeManager: storeManager)
        }
    }
    
    private func loadScriptures() async {
        guard let user = userProfiles.first else {
            isLoading = false
            return
        }
        
        // Create or reuse generator
        if generator == nil {
            generator = ScriptureGenerator(
                userProfile: user,
                bibleController: BibleController(modelContext: modelContext)
            )
        }
        
        guard let gen = generator else {
            isLoading = false
            return
        }
        
        // Always generate new scriptures when screen appears
        isLoading = true
        await gen.generateDailyScriptures()
        scriptures = gen.scriptures
        isLoading = false
    }
    
    private func checkAndRequestReview() {
        // Only request once and only if user has more than 3 favorites
        guard !hasRequestedReview && favorites.count > 3 else { return }
        
        // Small delay to ensure screen is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            requestReview()
            hasRequestedReview = true
        }
    }
}


// MARK: - Scripture Generator

import Foundation
import FoundationModels

@MainActor
@Observable
final class ScriptureGenerator {
    private var session: LanguageModelSession
    private let userProfile: UserProfile
    private let bibleController: BibleController
    
    // Output
    private(set) var scriptures: [(String, String)] = []
    private(set) var isGenerating = false
    private(set) var error: Error?
    
    // MARK: - Init
    
    init(userProfile: UserProfile, bibleController: BibleController) {
        self.userProfile = userProfile
        self.bibleController = bibleController
        
        let summary = Self.buildProfileSummary(from: userProfile)
        
        let instructions = Instructions {
            """
            You are a compassionate spiritual guide helping \(userProfile.name) grow in their faith journey.
            
            User's spiritual profile:
            \(summary)
            
            Your task: Generate personalized Bible verse REFERENCES (book, chapter, verse) that speak directly to their current situation.
            - Consider their specific struggles and victories
            - Align with their prayer focus areas
            - Match themes they find meaningful
            - Provide encouragement relevant to their goals
            
            IMPORTANT: Return ONLY references in this exact format:
            ["John 3:16", "Psalm 23:1", "Romans 8:28", ...]
            
            Rules:
            - Return exactly 12 references
            - Use standard Bible book names (e.g., "John", "Psalm", "Romans", "1 Corinthians")
            - Format: "Book Chapter:Verse" (e.g., "John 3:16")
            - No markdown, no explanations - just a JSON array of strings
            """
        }
        
        self.session = LanguageModelSession(instructions: instructions)
        session.prewarm()
    }
    
    // MARK: - Generation
    
    func generateDailyScriptures() async {
        guard !isGenerating else { return }
        isGenerating = true
        error = nil
        
        do {
            let timeOfDay = getTimeOfDay()
            let struggles = userProfile.struggles.isEmpty ? "various life challenges" : userProfile.struggles.joined(separator: ", ")
            let goals = userProfile.goals.isEmpty ? "spiritual growth" : userProfile.goals.joined(separator: ", ")
            let themes = userProfile.favoriteVerseThemes.isEmpty ? "hope and faith" : userProfile.favoriteVerseThemes.joined(separator: ", ")
            
            let prompt = Prompt {
                """
                It's \(timeOfDay) on \(Date().formatted(date: .complete, time: .shortened)) and \(userProfile.name) needs spiritual encouragement.
                
                Their current struggles: \(struggles)
                Their spiritual goals: \(goals)
                Themes they connect with: \(themes)
                
                Generate 12 DIFFERENT Bible verse references that:
                1. Directly address their struggles with hope and practical wisdom
                2. Support their goals with scriptural truth
                3. Incorporate their favorite themes
                4. Feel personally chosen for THIS person's journey
                5. VARY from previous selections - choose diverse passages
                
                Return ONLY a JSON array of 12 reference strings:
                ["Book Chapter:Verse", "Book Chapter:Verse", ...]
                
                Example format: ["John 3:16", "Psalm 23:1", "Romans 8:28"]
                """
            }
            
            // Use temperature for variety - each generation will be different
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(
                    temperature: 0.9,  // High temperature (0-1) for more variety
                    maximumResponseTokens: 200
                )
            )
            
            // Clean and parse the response
            var jsonString = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Remove markdown code blocks if present
            if jsonString.hasPrefix("```json") {
                jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
                jsonString = jsonString.replacingOccurrences(of: "```", with: "")
                jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if jsonString.hasPrefix("```") {
                jsonString = jsonString.replacingOccurrences(of: "```", with: "")
                jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            guard let jsonData = jsonString.data(using: .utf8) else {
                throw NSError(domain: "ScriptureGenerator", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to data"])
            }
            
            let references = try JSONDecoder().decode([String].self, from: jsonData)
            
            print("✅ Generated \(references.count) references: \(references)")
            
            // Look up each reference in the Bible
            var foundScriptures: [(String, String)] = []
            
            for reference in references {
                if let scripture = lookupScripture(reference: reference) {
                    foundScriptures.append(scripture)
                    print("✅ Found: \(reference)")
                } else {
                    print("⚠️ Could not find: \(reference)")
                }
            }
            
            // Use found scriptures or fallback
            if !foundScriptures.isEmpty {
                self.scriptures = foundScriptures
                print("✅ Successfully loaded \(foundScriptures.count) scriptures")
            } else {
                throw NSError(domain: "ScriptureGenerator", code: 2,
                              userInfo: [NSLocalizedDescriptionKey: "No scriptures found"])
            }
            
        } catch {
            self.error = error
            print("❌ Error generating scriptures: \(error)")
            
            // Fallback to default verses
            self.scriptures = [
                ("John 3:16", "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."),
                ("Psalm 23:1", "The Lord is my shepherd; I shall not want."),
                ("Romans 8:28", "And we know that in all things God works for the good of those who love him, who have been called according to his purpose."),
                ("Philippians 4:13", "I can do all things through Christ who strengthens me."),
                ("Jeremiah 29:11", "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future."),
                ("Proverbs 3:5-6", "Trust in the Lord with all thine heart; and lean not unto thine own understanding. In all thy ways acknowledge him, and he shall direct thy paths.")
            ]
        }
        
        isGenerating = false
    }
    
    // MARK: - Bible Lookup
    
    private func lookupScripture(reference: String) -> (String, String)? {
        // Parse reference: "John 3:16" -> Book: "John", Chapter: 3, Verse: 16
        let components = reference.components(separatedBy: " ")
        guard components.count >= 2 else { return nil }
        
        // Handle books with numbers (e.g., "1 Corinthians")
        let bookName: String
        let chapterVerse: String
        
        if components[0].first?.isNumber == true && components.count >= 3 {
            // "1 Corinthians 13:4" -> Book: "1 Corinthians", ChapterVerse: "13:4"
            bookName = "\(components[0]) \(components[1])"
            chapterVerse = components[2]
        } else {
            // "John 3:16" -> Book: "John", ChapterVerse: "3:16"
            bookName = components[0]
            chapterVerse = components[1]
        }
        
        let chapterVerseComponents = chapterVerse.components(separatedBy: ":")
        guard chapterVerseComponents.count == 2,
              let chapterNum = Int(chapterVerseComponents[0]),
              let verseNum = Int(chapterVerseComponents[1]) else {
            return nil
        }
        
        // Search through Bible data
        for testament in bibleController.bible.testaments {
            for book in testament.books {
                // Case-insensitive book name matching
                if book.name.localizedCaseInsensitiveCompare(bookName) == .orderedSame {
                    // Find the chapter
                    if let chapter = book.chapters.first(where: { $0.chapter == chapterNum }) {
                        // Find the verse
                        if let verse = chapter.verses.first(where: { $0.verse == verseNum }) {
                            return (reference, verse.text)
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Helpers
    
    private func getTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }
    
    private static func buildProfileSummary(from profile: UserProfile) -> String {
        var summary: [String] = []
        
        summary.append("Name: \(profile.name)")
        summary.append("Motivation: \(profile.motivationSource)")
        
        if !profile.struggles.isEmpty {
            summary.append("Current struggles: \(profile.struggles.joined(separator: ", "))")
        }
        
        if !profile.goals.isEmpty {
            summary.append("Spiritual goals: \(profile.goals.joined(separator: ", "))")
        }
        
        if !profile.favoriteVerseThemes.isEmpty {
            summary.append("Favorite themes: \(profile.favoriteVerseThemes.joined(separator: ", "))")
        }
        
        if !profile.prayerFocus.isEmpty {
            summary.append("Prayer focus: \(profile.prayerFocus.joined(separator: ", "))")
        }
        
        return summary.joined(separator: "\n")
    }
}

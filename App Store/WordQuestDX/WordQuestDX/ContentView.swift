import SwiftUI
import GameKit

let themes = [
    "Animals", "Space", "Cities", "Fruits", "Colors", "Sports",
    "Vehicles", "Ocean", "Music", "Weather", "Plants", "Jobs",
    "Movies", "Food", "Fashion", "Technology", "History", "Mythology",
    "Books", "Instruments", "Games", "Transportation", "Tools", "Countries",
    "Desserts", "Nature",
    "Dinosaurs", "Birds", "Insects", "Reptiles", "Mammals", "Pets",
    "Superheroes", "Cartoons", "TV Shows", "Celebrities", "Fairy Tales",
    "Magic", "Science", "Mathematics", "Physics", "Chemistry", "Biology",
    "Planets", "Galaxies", "Astronauts", "Black Holes", "Weather Phenomena",
    "Mountains", "Rivers", "Forests", "Deserts", "Islands", "Lakes",
    "Cakes", "Cookies", "Ice Cream", "Beverages", "Snacks", "Seafood",
    "Vegetables", "Spices", "Herbs", "Breakfast Foods", "Lunch Foods",
    "Music Genres", "Bands", "Singers", "Composers", "Musical Notes",
    "Dance Styles", "Painting", "Sculpture", "Photography", "Architecture",
    "Cars", "Trains", "Planes", "Boats", "Bikes", "Motorcycles",
    "Electronics", "Computers", "Gadgets", "Apps", "Video Games", "Robots",
    "Historical Figures", "Ancient Civilizations", "Wars", "Inventions",
    "Mythical Creatures", "Gods & Goddesses", "Legends", "Folklore",
    "Languages", "Alphabet", "Grammar", "Poetry", "Novels",
    "Board Games", "Card Games", "Puzzle Games", "Sports Teams", "Olympics",
    "Camping", "Hiking", "Fishing", "Survival", "Adventure",
    "Fashion Accessories", "Clothing", "Shoes", "Jewelry", "Cosmetics",
    "Tools & Equipment", "Construction", "Gardening", "Fishing Tools",
    "Countries & Capitals", "Continents", "World Wonders",
    "Festivals", "Holidays", "Traditions", "Religions", "Philosophies",
    "Emotions", "Feelings", "Body Parts", "Senses", "Health & Fitness",
    "Space Exploration", "Aliens", "Fictional Worlds", "Time Travel",
    "Underwater Creatures", "Coral Reefs", "Marine Plants", "Ships",
    "Bird Species", "Flowers", "Trees", "Cacti", "Fruits & Nuts",
    "Kitchen Utensils", "Furniture", "Appliances", "Office Supplies",
    "Modes of Transport", "Traffic Signs", "Roads & Highways", "Bridges",
    "Science Experiments", "Laboratory Equipment", "Astronomy Tools",
    "Planets & Moons", "Stars & Constellations", "Natural Disasters",
    "Volcanoes", "Earthquakes", "Tornadoes", "Hurricanes", "Climate Change",
    "Recycling", "Pollution", "Energy Sources", "Renewable Energy",
    "Wildlife", "Endangered Species", "Habitats", "Eco-systems", "National Parks",
    "Fictional Characters", "Pirates", "Knights", "Vikings", "Robots & AI",
    "Fantasy Weapons", "Magic Spells", "Potions", "Dragons", "Wizards",
    "Space Missions", "Rockets", "Satellites", "Space Stations",
    "Pop Culture", "Memes", "Internet Trends", "Social Media", "Apps",
    "Transportation History", "Ancient Tools", "Modern Inventions"
]

var model = SystemLanguageModel.default

struct ContentView: View {
    @Environment(StoreController.self) var storeController
    @Environment(\.gameEnvironment) var gameEnvironment
    @State private var isPlaying = false
    @State private var puzzlesSolved = 0
    
    var body: some View {
        switch model.availability {
        case .available:
            ZStack {
                BackgroundView()
                    .environment(storeController)
                
                if isPlaying {
                    if !storeController.purchased && puzzlesSolved >= 7 {
                        PaywallView(isPlaying: $isPlaying, store: storeController)
                    } else {
                        WordSearchView(isPlaying: $isPlaying, puzzlesSolved: $puzzlesSolved)
                            .environment(storeController)
                            .padding()
                    }
                } else {
                    VStack(spacing: 30) {
                        TitleScreenView()
                        
                        Button {
                            isPlaying.toggle()
                        } label: {
                            Text("Play")
                                .font(.largeTitle)
                                .fontWeight(.heavy)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.glass)
                        .onAppear {
                            gameEnvironment.accessPoint.location = .topLeading
                            gameEnvironment.accessPoint.isActive = true
                        }
                        .onDisappear {
                            gameEnvironment.accessPoint.isActive = false
                        }
                    }
                }
            }
        case .unavailable(.deviceNotEligible):
            ZStack {
                BackgroundView()
                    .environment(storeController)
                
                ContentUnavailableView {
                    Label("Device Not Supported", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("Word Quest DX requires Apple Intelligence, which isn’t available on this device.")
                }
            }
            
        case .unavailable(.appleIntelligenceNotEnabled):
            ZStack {
                BackgroundView()
                    .environment(storeController)
                
                ContentUnavailableView {
                    Label("Apple Intelligence Disabled", systemImage: "sparkles")
                } description: {
                    Text("Enable Apple Intelligence in Settings to unlock your word adventure.")
                }
            }
            
        case .unavailable(.modelNotReady):
            ZStack {
                BackgroundView()
                    .environment(storeController)
                
                ContentUnavailableView {
                    Label("Preparing Your Journey", systemImage: "hourglass")
                } description: {
                    Text("Your word-crafting companion is getting ready. Please try again shortly.")
                }
            }
            
        case .unavailable(let other):
            ZStack {
                BackgroundView()
                    .environment(storeController)
                
                ContentUnavailableView {
                    Label("Unavailable", systemImage: "questionmark.circle")
                } description: {
                    Text("Something unexpected is preventing Word Quest DX from starting. \(String(describing: other))")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}


import Foundation
import FoundationModels


enum Difficulty: String, CaseIterable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"
}

import Foundation
import SwiftData


struct WordSearchView: View {
    @Environment(StoreController.self) var storeController
    @Environment(\.gameEnvironment) var gameEnvironment
    
    @Binding var isPlaying: Bool
    @Binding var puzzlesSolved: Int
    
    init(isPlaying: Binding<Bool>, puzzlesSolved: Binding<Int>) {
        self._isPlaying = isPlaying
        self._puzzlesSolved = puzzlesSolved
    }
    
    @State private var words: [String] = []
    @State private var grid: [[String]] = [[]]
    
    @AppStorage("totalWordsFound") private var totalWordsFound = 0
    @AppStorage("lastSessionDate") private var lastSessionDate: Double = 0
    @AppStorage("dailySessionStreak") var dailySessionStreak: Int = 0
    @AppStorage("totalPuzzlesSolved") private var totalPuzzlesSolved = 0
    
    @State private var selectedDifficulty: Difficulty = .normal
    
    @State private var isComplete = false
    @State private var showPromptSheet = false
    @State private var newTheme = ""
    
    // Reference the on-device model
    //    private var model = SystemLanguageModel.default
    
    // Game state
    @State private var foundWords: Set<String> = []
    @State private var foundPositions: Set<GridPosition> = []
    @State private var selectedPositions: [GridPosition] = []
    @State private var dragStart: GridPosition? = nil
    
    @State private var hintPositions: [GridPosition] = []
    @State private var activeHintIndex: Int? = nil
    
    @State private var lastActivity = Date()
    @State private var currentHint: String? = nil
    
    @State private var lastWordTime: Date? = nil
    @State private var fastWordCount = 0
    @State private var usedHint = false
    
    @State private var showPaywall = false
    
    // Layout tuning
    let cellSpacing: CGFloat = 6
    let sidePadding: CGFloat = 20
    let maxCellSize: CGFloat = 88
    let minCellSize: CGFloat = 26
    
    @State private var score: Int = 0
    
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let maxColumns = 6
    
    private var rows: [[String]] {
        stride(from: 0, to: words.count, by: maxColumns).map { startIndex in
            let endIndex = min(startIndex + maxColumns, words.count)
            return Array(words[startIndex..<endIndex])
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                ScoreView(score: $score)
                
                // Word List Grid
                if horizontalSizeClass == .compact {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(words, id: \.self) { word in
                            Text(word)
                                .strikethrough(foundWords.contains(word))
                                .foregroundStyle(foundWords.contains(word) ? .secondary : .primary)
                                .bold(!foundWords.contains(word))
                                .frame(maxWidth: .infinity)
                                .onTapGesture {
                                    showDefinition(for: word)
                                }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal)
                    .padding(.vertical)
                } else {
                    Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                        ForEach(rows, id: \.self) { rowWords in
                            GridRow {
                                ForEach(rowWords, id: \.self) { word in
                                    Text(word)
                                        .strikethrough(foundWords.contains(word))
                                        .foregroundStyle(foundWords.contains(word) ? .secondary : .primary)
                                        .bold(!foundWords.contains(word))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .onTapGesture {
                                            showDefinition(for: word)
                                        }
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal)
                    .padding(.vertical)
                }
                
                // Grid - the GeometryReader drives adaptive sizing
                GeometryReader { geo in
                    if !grid.isEmpty {
                        
                        // grid dimensions
                        let cols = grid[0].count
                        let rows = grid.count
                        
                        // compute maximum cell size using both width and height constraints
                        let availableWidth = max(0, geo.size.width - sidePadding * 2)
                        let totalSpacingW = CGFloat(cols - 1) * cellSpacing
                        let cellW = (availableWidth - totalSpacingW) / CGFloat(cols)
                        
                        // reserve some height for the word list and padding; this is conservative
                        let availableHeight = max(0, geo.size.height)
                        let totalSpacingH = CGFloat(rows - 1) * cellSpacing
                        let cellH = (availableHeight - totalSpacingH) / CGFloat(rows)
                        
                        // final cell size (clamped)
                        let dynamicCellSize = max(minCellSize, min(maxCellSize, floor(min(cellW, cellH))))
                        
                        let totalWidth = CGFloat(cols) * dynamicCellSize + totalSpacingW
                        let totalHeight = CGFloat(rows) * dynamicCellSize + totalSpacingH
                        let originX = (geo.size.width - totalWidth) / 2
                        let originY = (geo.size.height - totalHeight) / 2
                        
                        // Grid content
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<rows, id: \.self) { row in
                                HStack(spacing: cellSpacing) {
                                    ForEach(0..<cols, id: \.self) { col in
                                        let pos = GridPosition(row: row, col: col)
                                        Text(grid[row][col])
                                            .font(.system(size: max(12, dynamicCellSize * 0.45), weight: .semibold))
                                            .frame(width: dynamicCellSize, height: dynamicCellSize)
                                            .background(backgroundForCell(pos))
                                            .cornerRadius(6)
                                            .animation(.easeInOut(duration: 0.12), value: foundPositions)
                                            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                }
                            }
                        }
                        .padding()
                        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .position(x: originX + totalWidth / 2, y: originY + totalHeight / 2)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    // convert global gesture location to grid-local coordinates
                                    let localX = value.location.x - originX
                                    let localY = value.location.y - originY
                                    
                                    guard let hit = hitTestCell(at: CGPoint(x: localX, y: localY),
                                                                cellSize: dynamicCellSize,
                                                                cols: cols,
                                                                rows: rows) else {
                                        return
                                    }
                                    
                                    if dragStart == nil {
                                        dragStart = hit
                                    }
                                    if let start = dragStart {
                                        selectedPositions = positionsBetween(start: start, end: hit)
                                    }
                                }
                                .onEnded { _ in
                                    checkSelectedWord()
                                    selectedPositions.removeAll()
                                    dragStart = nil
                                }
                        )
                    } else {
                        ProgressView("Generating puzzle…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                
                HStack {
                    Button {
                        isPlaying.toggle()
                    } label: {
                        Image(systemName: "arrowshape.turn.up.backward.fill")
                            .padding()
                    }
                    .buttonStyle(.glass)
                    .frame(maxWidth: .infinity)
                    
                    Button {
                        let randomTheme = themes.randomElement()!
                        
                        Task {
                            await generatePuzzle(theme: randomTheme)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .padding()
                    }
                    .buttonStyle(.glass)
                    .frame(maxWidth: .infinity)
                    
                    Button {
                        showPromptSheet = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .padding()
                    }
                    .buttonStyle(.glass)
                    .frame(maxWidth: .infinity)
                    
                    Button {
                        // Only show paywall if not purchased
                        if storeController.purchased {
                            giveHint()
                            usedHint = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "lightbulb.fill")
                            .padding()
                    }
                    .buttonStyle(.glass)
                    .frame(maxWidth: .infinity)
                }
                .padding(.top)
                
                Spacer()
            }
            
            if isComplete {
                VStack(spacing: 20) {
                    Text("🎉 Puzzle Completed!")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("Score: \(score)")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Button("Next Puzzle") {
                        let randomTheme = themes.randomElement()!
                        
                        Task {
                            await generatePuzzle(theme: randomTheme)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal)
                    .buttonStyle(.glass)
                }
                .padding()
                .padding()
                .background(Color.black.opacity(0.42).cornerRadius(8))
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            puzzlesSolved = totalPuzzlesSolved
            let randomTheme = themes.randomElement()!
            
            Task {
                await generatePuzzle(theme: randomTheme)
            }
        }
        .onChange(of: foundWords) {
            lastActivity = Date()
            currentHint = nil
            wordFound()
        }
        .sheet(isPresented: $showPromptSheet) {
            CustomPuzzleSheet(
                newTheme: $newTheme,
                selectedDifficulty: $selectedDifficulty
            ) { theme, difficulty in
                Task {
                    await generatePuzzle(theme: theme)
                }
            }
        }
        
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPlaying: $isPlaying, store: storeController)
        }
        .onChange(of: totalPuzzlesSolved) {
            puzzlesSolved = totalPuzzlesSolved
        }
        .onChange(of: foundWords) {
            checkPuzzleCompletion()
        }
    }
    
    private func checkPuzzleCompletion() {
        let normalizedFound = Set(foundWords.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() })
        let normalizedWords = Set(words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() })
        
        if normalizedFound == normalizedWords {
            puzzleCompleted()
            withAnimation {
                isComplete = true
            }
        }
    }
    
    let session = LanguageModelSession(model: .default)
    
    @MainActor
    func generatePuzzle(theme: String, difficulty: Difficulty = .normal) async {
        resetGame()
        grid = []
        isComplete = false
        
        guard model.availability == .available else {
            resetGame()
            return
        }
        
        let difficultyHint: String
        switch difficulty {
        case .easy:
            difficultyHint = "Use short, common, simple English words that most children would know."
        case .normal:
            difficultyHint = "Use standard, everyday English words."
        case .hard:
            difficultyHint = "Use more advanced, less common English words, at least 6+ letters long."
        }
        
        do {
            // Step 1: Ask AI to generate words as plain text
            let prompt = """
            You are a word search puzzle creator. Generate a list of exactly 6 words related to the theme: \(theme). 
            
            Rules:
            1. \(difficultyHint)
            2. Do not generate any word longer than 16 characters.
            3. Include exactly 6 words, separated by commas, with no extra text.
            4. Words must contain only letters (no numbers, punctuation, spaces, or special characters).
            5. Only return the words, do not include explanations, descriptions, or additional text.
            """
            
            
            let response = try await session.respond(to: prompt)
            let rawWords = response.content.components(separatedBy: CharacterSet([",", "\n"]))
            
            // Step 2: Clean and uppercase words
            //            let newWords = rawWords
            //                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            //                .filter { !$0.isEmpty }
            //
            //            guard !newWords.isEmpty else {
            //                resetGame()
            //                return
            //            }
            //            words = newWords
            
            // Step 2: Clean and uppercase words
            let newWords = rawWords
            //                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters)).uppercased() }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
                .map { word in
                    // Optionally, remove a trailing period if you only want to remove periods at the end
                    if word.hasSuffix(".") {
                        return String(word.dropLast())
                    }
                    return word
                }
                .filter { !$0.isEmpty }
            
            guard !newWords.isEmpty else {
                resetGame()
                return
            }
            
            words = newWords
            
            
            // Step 3: Determine grid size
            let longest = newWords.map(\.count).max() ?? 6
            let size = max(8, min(16, longest)) // clamp between 8 and 16
            
            // Step 4: Generate grid locally with retries
            var finalGrid: [[String]]? = nil
            for _ in 0..<500 {
                let attempt = makeGrid(with: newWords, width: size, height: size)
                if newWords.allSatisfy({ locateWordPositions($0, in: attempt) != nil }) {
                    finalGrid = attempt
                    break
                }
            }
            
            // Step 5: Assign grid or fallback
            if let finalGrid {
                grid = finalGrid
            } else {
                print("⚠️ Failed to generate valid grid after multiple attempts: \(newWords.joined(separator: ", "))")
                resetGame()
            }
            
        } catch {
            print("⚠️ Puzzle generation failed: \(error)")
            resetGame()
        }
    }
    
    private func makeGrid(with words: [String], width: Int, height: Int) -> [[String]] {
        var grid = Array(repeating: Array(repeating: "", count: width), count: height)
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let directions = [(0,1),(1,0),(1,1),(1,-1)]
        
        let sortedWords = words.sorted { $0.count > $1.count }
        
        for word in sortedWords {
            var placed = false
            for dir in directions.shuffled() {
                for row in 0..<height {
                    for col in 0..<width {
                        if canPlace(word: word, at: row, col: col, dir: dir, grid: grid) {
                            place(word: word, at: row, col: col, dir: dir, grid: &grid)
                            placed = true
                            break
                        }
                    }
                    if placed { break }
                }
                if placed { break }
            }
            if !placed {
                print("⚠️ Could not place word \(word)")
            }
        }
        
        for r in 0..<height {
            for c in 0..<width {
                if grid[r][c].isEmpty {
                    grid[r][c] = String(letters.randomElement()!)
                }
            }
        }
        
        return grid
    }
    
    func wordFound() {
        totalWordsFound += 1
        
        // Check thresholds
        switch totalWordsFound {
        case 1:
            gameEnvironment.gameCenterController.reportAchievement(identifier: "word_1", percentComplete: 100.0)
        case 25:
            gameEnvironment.gameCenterController.reportAchievement(identifier: "words_25", percentComplete: 100.0)
        case 100:
            gameEnvironment.gameCenterController.reportAchievement(identifier: "words_100", percentComplete: 100.0)
        case 500:
            gameEnvironment.gameCenterController.reportAchievement(identifier: "words_500", percentComplete: 100.0)
        case 1000:
            gameEnvironment.gameCenterController.reportAchievement(identifier: "words_1000", percentComplete: 100.0)
        default:
            break
        }
    }
    
    func puzzleCompleted() {
        totalPuzzlesSolved += 1
        
        switch totalPuzzlesSolved {
        case 1:
            gameEnvironment.gameCenterController.reportAchievement(identifier: "puzzles_1", percentComplete: 100.0)
        case 10:
            gameEnvironment.gameCenterController.reportAchievement(identifier: "puzzles_10", percentComplete: 100.0)
        case 25:
            gameEnvironment.gameCenterController.reportAchievement(identifier: "puzzles_25", percentComplete: 100.0)
        case 50:
            gameEnvironment.gameCenterController.reportAchievement(identifier: "puzzles_50", percentComplete: 100.0)
        case 100:
            gameEnvironment.gameCenterController.reportAchievement(identifier: "puzzles_100", percentComplete: 100.0)
        default:
            break
        }
        
        if !usedHint {
            gameEnvironment.gameCenterController.reportAchievement(identifier: "skill_no_hints", percentComplete: 100.0)
        }
        usedHint = false
        
        Task {
            await gameEnvironment.gameCenterController.submitScoreToGameCenter(score: score)
        }
    }
    
    func puzzleCompleted(finalScore: Int) {
        if finalScore >= 500 {
            gameEnvironment.gameCenterController.reportAchievement(identifier: "score_500", percentComplete: 100.0)
        }
        if finalScore >= 1000 {
            gameEnvironment.gameCenterController.reportAchievement(identifier: "score_1000", percentComplete: 100.0)
        }
        if finalScore >= 2500 {
            gameEnvironment.gameCenterController.reportAchievement(identifier: "score_2500", percentComplete: 100.0)
        }
    }
    
    func startSession() {
        let now = Date()
        let oneDay: TimeInterval = 60 * 60 * 24
        
        if lastSessionDate == 0 {
            // first session ever
            dailySessionStreak = 1
        } else {
            let lastDate = Date(timeIntervalSince1970: lastSessionDate)
            
            if now.timeIntervalSince(lastDate) >= oneDay && now.timeIntervalSince(lastDate) < oneDay * 2 {
                // within 24–48 hours → streak continues
                dailySessionStreak += 1
            } else if now.timeIntervalSince(lastDate) >= oneDay * 2 {
                // missed a day → streak resets
                dailySessionStreak = 1
            }
        }
        
        lastSessionDate = now.timeIntervalSince1970
        
        checkSessionAchievements()
    }
    
    private func checkSessionAchievements() {
        if dailySessionStreak == 7 {
            gameEnvironment.gameCenterController.reportAchievement(identifier: "streak_session_7", percentComplete: 100.0)
        }
        
        if dailySessionStreak == 30 {
            gameEnvironment.gameCenterController.reportAchievement(identifier: "streak_session_30", percentComplete: 100.0)
        }
    }
    
    private func canPlace(word: String, at row: Int, col: Int, dir: (Int, Int), grid: [[String]]) -> Bool {
        let rows = grid.count
        let cols = grid[0].count
        var r = row
        var c = col
        for char in word {
            if r < 0 || r >= rows || c < 0 || c >= cols { return false }
            if !grid[r][c].isEmpty && grid[r][c] != String(char) { return false }
            r += dir.0
            c += dir.1
        }
        return true
    }
    
    private func place(word: String, at row: Int, col: Int, dir: (Int, Int), grid: inout [[String]]) {
        var r = row
        var c = col
        for char in word {
            grid[r][c] = String(char)
            r += dir.0
            c += dir.1
        }
    }
    
    @ViewBuilder
    private func backgroundForCell(_ pos: GridPosition) -> some View {
        if foundPositions.contains(pos) {
            Color.green.opacity(0.44)
        } else if selectedPositions.contains(pos) {
            Color.yellow.opacity(0.7)
        } else if let i = activeHintIndex, i < hintPositions.count, hintPositions[i] == pos {
            Color.orange.opacity(0.5) // glowing hint cell
        } else {
            Color.gray.opacity(0.12)
        }
    }
    
    // Map local grid point to a grid cell using the actual computed cell size.
    private func hitTestCell(at point: CGPoint, cellSize: CGFloat, cols: Int, rows: Int) -> GridPosition? {
        // Each block includes cell plus spacing
        let blockW = cellSize + cellSpacing
        let blockH = cellSize + cellSpacing
        
        if point.x < 0 || point.y < 0 { return nil }
        
        // Allow small margin inside a cell to be tolerant
        let col = Int(point.x / blockW)
        let row = Int(point.y / blockH)
        
        guard row >= 0, row < rows, col >= 0, col < cols else {
            return nil
        }
        return GridPosition(row: row, col: col)
    }
    
    // Build straight-line positions between two grid cells (snapped to one of 8 directions)
    private func positionsBetween(start: GridPosition, end: GridPosition) -> [GridPosition] {
        let dc = end.col - start.col
        let dr = end.row - start.row
        
        // If same cell
        if dc == 0 && dr == 0 { return [start] }
        
        // Determine normalized direction (one of 8)
        let absDC = abs(dc)
        let absDR = abs(dr)
        var dx = 0
        var dy = 0
        var steps = 0
        
        if absDC == absDR { // perfect diagonal
            dx = dc == 0 ? 0 : (dc / absDC)
            dy = dr == 0 ? 0 : (dr / absDR)
            steps = absDC
        } else if absDC > absDR {
            dx = dc > 0 ? 1 : -1
            dy = 0
            steps = absDC
        } else {
            dx = 0
            dy = dr > 0 ? 1 : -1
            steps = absDR
        }
        
        var result: [GridPosition] = []
        for i in 0...steps {
            let r = start.row + i * dy
            let c = start.col + i * dx
            if r >= 0 && r < grid.count && c >= 0 && c < grid[0].count {
                result.append(GridPosition(row: r, col: c))
            } else {
                break
            }
        }
        return result
    }
    
    private func checkSelectedWord() {
        guard !selectedPositions.isEmpty else { return }
        let word = selectedPositions.map { grid[$0.row][$0.col] }.joined()
        let reversed = String(word.reversed())
        
        for w in words {
            if w == word || w == reversed {
                if !foundWords.contains(w) {
                    foundWords.insert(w)
                    foundPositions.formUnion(selectedPositions)
                    
                    let now = Date()
                    if let lastTime = lastWordTime, now.timeIntervalSince(lastTime) <= 3 {
                        gameEnvironment.gameCenterController.reportAchievement(identifier: "skill_fast_word", percentComplete: 100.0)
                    }
                    lastWordTime = now
                    
                    if let lastTime = lastWordTime, now.timeIntervalSince(lastTime) <= 3 {
                        fastWordCount += 1
                        if fastWordCount >= 5 {
                            gameEnvironment.gameCenterController.reportAchievement(identifier: "skill_fast_5words", percentComplete: 100.0)
                        }
                    } else {
                        fastWordCount = 1
                    }
                    
                    // --- scoring ---
                    let base = 10
                    let lengthBonus = w.count * 2
                    score += base + lengthBonus
                    
                    if word.count >= 8 {
                        gameEnvironment.gameCenterController.reportAchievement(identifier: "skill_long_word", percentComplete: 100.0)
                    }
                }
                return
            }
        }
    }
    
    private func animateHint(for word: String) {
        // Find the word’s grid positions in the current grid
        guard let positions = locateWordPositions(word, in: grid) else { return }
        
        hintPositions = positions
        
        Task {
            for i in 0..<positions.count {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeHintIndex = i
                    }
                }
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25s per cell
            }
            
            // Fade out the trail
            for i in positions.indices.reversed() {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeHintIndex = i
                    }
                }
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            
            // Clear after done
            await MainActor.run {
                activeHintIndex = nil
                hintPositions = []
            }
        }
    }
    
    private func locateWordPositions(_ word: String, in grid: [[String]]) -> [GridPosition]? {
        guard !grid.isEmpty, !grid[0].isEmpty else { return nil } // safety check
        
        let rows = grid.count
        let cols = grid[0].count
        let directions = [(0,1),(1,0),(1,1),(1,-1)]
        
        for row in 0..<rows {
            for col in 0..<cols {
                for dir in directions {
                    var r = row
                    var c = col
                    var positions: [GridPosition] = []
                    for char in word {
                        if r < 0 || r >= rows || c < 0 || c >= cols { break }
                        if grid[r][c] != String(char) { break }
                        positions.append(GridPosition(row: r, col: c))
                        r += dir.0
                        c += dir.1
                    }
                    if positions.count == word.count { return positions }
                }
            }
        }
        return nil
    }
    
    private func giveHint() {
        let remaining = words.filter { !foundWords.contains($0) }
        if let hintWord = remaining.randomElement() {
            animateHint(for: hintWord)
            lastActivity = Date() // reset timer
        }
    }
    
    private func resetGame() {
        foundWords.removeAll()
        foundPositions.removeAll()
        selectedPositions.removeAll()
        dragStart = nil
        currentHint = nil
        lastActivity = Date()
        withAnimation { isComplete = false }
        score = 0
    }
    
    func showDefinition(for word: String) {
        guard UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: word) else {
            print("No definition found for \(word)")
            return
        }
        
        let vc = UIReferenceLibraryViewController(term: word)
        
        // Get the current top UIViewController
        if let topVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController {
            topVC.present(vc, animated: true)
        }
    }
}

// Simple hashable position
struct GridPosition: Hashable {
    let row: Int
    let col: Int
}

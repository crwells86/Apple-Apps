import Foundation
import SwiftData

@MainActor
class GameController: ObservableObject {
    @Published var decks: [Deck] = [
        spicySecrets,
        playfulRomCom,
        naughtyChoices,
        risquéDilemmas,
        kinkyQuandaries,
        playfulPerils,
        forbiddenFun,
        saucyScenarios,
        provocativePredicaments,
        lustyLines,
        afterDarkDares,
        shakespeare,
        hauntedHearts,
        wickedWhispers,
        midnightMischief,
        graveyardGames,
        thanksgivingSpice,
        flirtyFeast
    ]
    
    // Custom questions saved persistently
    @Published var customDeck = Deck(name: "Custom Cards", icon: "", questions: [])
    
    // Selected deck and current question
    @Published var selectedDeckIndices: Set<Int> = []
    @Published private(set) var currentQuestionIndex: Int = 0
    
    // Timed choice properties
    @Published var timedChoiceEnabled = false
    @Published var challengeEnabled = false
    @Published var timeRemaining: Int = 10
    var timer: Timer?
    
    // Game state
    @Published var currentQuestion: Question? = nil
    
    // Currently playing deck index - for game mode single deck (first selected deck)
    @Published var playingDeckIndex: Int? = nil
    
    func loadDecks(from context: ModelContext) async {
            do {
                let fetchedDecks = try context.fetch(FetchDescriptor<Deck>())
                DispatchQueue.main.async {
                    self.decks.append(contentsOf: fetchedDecks) // = fetchedDecks
                }
            } catch {
                print("Failed to fetch decks: \(error)")
            }
        }
    
    func appendDeck(named deckName: String, from context: ModelContext) async {
        do {
            let fetchedDecks = try context.fetch(FetchDescriptor<Deck>())
            if let deckToAppend = fetchedDecks.first(where: { $0.name == deckName }) {
                DispatchQueue.main.async {
                    self.decks.append(deckToAppend)
                }
            } else {
                print("Deck named '\(deckName)' not found")
            }
        } catch {
            print("Failed to fetch decks: \(error)")
        }
    }


    // MARK: - Deck selection toggling
    
    func toggleDeckSelection(at index: Int) {
        if selectedDeckIndices.contains(index) {
            selectedDeckIndices.remove(index)
        } else {
            selectedDeckIndices.insert(index)
        }
    }
    
    // Returns all questions of selected decks concatenated
    var combinedSelectedQuestions: [Question] {
        var questions: [Question] = []
        for index in selectedDeckIndices.sorted() {
            if index == decks.count {
                // custom deck
                questions.append(contentsOf: customDeck.questions)
            } else if index < decks.count {
                questions.append(contentsOf: decks[index].questions)
            }
        }
        return questions
    }
    
    // Helper to get total cards and decks selected
    var totalSelectedCards: Int {
        combinedSelectedQuestions.count
    }
    
    var selectedDecksCount: Int {
        selectedDeckIndices.count
    }
    
    // MARK: - Game play management
    
    func startGame() {
        guard !selectedDeckIndices.isEmpty else { return }
        playingDeckIndex = selectedDeckIndices.sorted().first
        currentQuestionIndex = 0
        loadCurrentQuestion()
        if timedChoiceEnabled {
            startTimer()
        }
    }
    
    func startRandomGame(deckIndex: Int) {
        playingDeckIndex = deckIndex
        currentQuestionIndex = 0
        loadCurrentQuestion()
        if timedChoiceEnabled {
            startTimer()
        }
    }

    
    func loadCurrentQuestion() {
        guard let playingDeckIndex = playingDeckIndex else {
            currentQuestion = nil
            return
        }
        let deck: Deck
        if playingDeckIndex == decks.count {
            deck = customDeck
        } else {
            deck = decks[playingDeckIndex]
        }
        if currentQuestionIndex < deck.questions.count {
            currentQuestion = deck.questions[currentQuestionIndex]
        } else {
            currentQuestion = nil
        }
    }
    
    func nextQuestion() {
        currentQuestionIndex += 1
        loadCurrentQuestion()
        if timedChoiceEnabled {
            startTimer()
        }
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        loadCurrentQuestion()
        if timedChoiceEnabled {
            startTimer()
        }
    }
    
    func stopGame() {
        playingDeckIndex = nil
        stopTimer()
    }
    
    // MARK: - Timer
    
    func startTimer() {
        guard timedChoiceEnabled else { return }
        stopTimer()
        timeRemaining = 10
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timeExpired()
                }
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func timeExpired() {
        stopTimer()
        // Auto-skip to next question on timeout
//        withAnimation {
//            nextQuestion()
//        }
    }
    
    // MARK: - Selection and challenges
    
    func selectOption(_ option: String) {
        stopTimer()
        // Optional challenge message
        if challengeEnabled, let question = currentQuestion {
            var challengeText: String? = nil
            if option == question.optionA {
                challengeText = question.challengeA
            } else if option == question.optionB {
                challengeText = question.challengeB
            }
            if let challenge = challengeText {
                // Show challenge alert
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .showChallenge, object: challenge)
                }
            }
        }
//        withAnimation {
//            nextQuestion()
//        }
    }
    
    // MARK: - Custom Cards
    
    func addCustomQuestion(_ question: Question) {
        customDeck.questions.append(question)
        //        saveCustomDeck()
    }
    
    func deleteCustomQuestion(_ question: Question) {
        customDeck.questions.removeAll { $0.id == question.id }
        //        saveCustomDeck()
    }
}

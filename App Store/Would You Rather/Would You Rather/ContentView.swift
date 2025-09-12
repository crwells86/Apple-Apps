import SwiftUI
import StoreKit

struct QuestionView: View {
    @EnvironmentObject var game: GameController
    @State private var selectedOption: String? = nil
    @State private var topFlip: Double = 0
    @State private var bottomFlip: Double = 0
    
    @State private var challengeMessage: ChallengeMessage?
    @State private var selectedChallengeMessageOption: String? = nil
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.orange, .pink, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                if let question = game.currentQuestion {
                    Text(question.text)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.horizontal, .bottom])
                    
                    VStack {
                        // Top option
                        optionCard(title: question.optionA)
                            .rotation3DEffect(
                                .degrees(topFlip),
                                axis: (x: 0, y: 1, z: 0),
                                perspective: 0.5
                            )
                            .onTapGesture {
                                selectedChallengeMessageOption = "A"
                            }
                        
                        // Bottom option
                        optionCard(title: question.optionB)
                            .rotation3DEffect(
                                .degrees(bottomFlip),
                                axis: (x: 0, y: 1, z: 0),
                                perspective: 0.5
                            )
                            .onTapGesture {
                                selectedChallengeMessageOption = "B"
                            }
                    }
                    .overlay {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 9)
                            
                            Circle()
                                .fill(.pink)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(Double(game.timeRemaining) / 10.0))
                                .stroke(
                                    LinearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1.0), value: game.timeRemaining)
                            
                            Text("OR")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(width: 87, height: 87)
                        .onReceive(game.$timeRemaining) { timeLeft in
                            if timeLeft == 0 {
                                if let question = game.currentQuestion {
                                    // Randomly pick "A" or "B"
                                    let choice = Bool.random() ? "A" : "B"
                                    
                                    let challengeText: String
                                    if choice == "A" {
                                        challengeText = question.challengeA ?? "No challenge for A"
                                    } else {
                                        challengeText = question.challengeB ?? "No challenge for B"
                                    }
                                    
                                    challengeMessage = ChallengeMessage(message: challengeText)
                                }
                            }
                        }
                        .alert(item: $challengeMessage) { challenge in
                            Alert(
                                title: Text("Challenge!"),
                                message: Text(challenge.message),
                                dismissButton: .default(Text("Got it!"))
                            )
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                game.stopGame() // assuming this goes back to deck selection
                            }
                        }) {
                            Text("Pick a new deck")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.7))
                                .cornerRadius(16)
                        }
                        
                        //                        Button(action: {
                        //                            if let randomDeckIndex = game.selectedDeckIndices.randomElement() {
                        //                                game.startRandomGame(deckIndex: randomDeckIndex)
                        //                            }
                        //                        }) {
                        //                            Text("Play New Deck")
                        //                                .font(.headline)
                        //                                .foregroundColor(.white)
                        //                                .padding()
                        //                                .frame(maxWidth: .infinity)
                        //                                .background(Color.green.opacity(0.7))
                        //                                .cornerRadius(16)
                        //                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
        }
    }
    
    func optionCard(title: String) -> some View {
        Button {
            guard selectedOption == nil else { return }
            selectedOption = title
            game.selectOption(title)
            
            // Trigger flip animations
            withAnimation(.easeInOut(duration: 0.6)) {
                if title == game.currentQuestion?.optionA {
                    topFlip = -180
                    bottomFlip = 180
                } else {
                    topFlip = -180
                    bottomFlip = 180
                }
            }
            
            // Reset after delay and go to next
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                selectedOption = nil
                topFlip = 0
                bottomFlip = 0
                game.nextQuestion()
            }
            
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.7))
                    .frame(maxWidth: .infinity, minHeight: 150)
                
                Text(title)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
}




extension Notification.Name {
    static let showChallenge = Notification.Name("showChallenge")
}

// MARK: - Views

struct ContentView: View {
    @Environment(SubscriptionController.self) var subscriptionController
    @StateObject private var game = GameController()
    @State private var showingSettings = false
    @State private var showingAddCard = false
    @State private var showingGame = false
    @State private var challengeMessage: ChallengeMessage?
    
    @AppStorage("sessionCount") private var sessionCount = 0
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if game.playingDeckIndex != nil {
                    QuestionView()
                        .environmentObject(game)
                        .transition(.move(edge: .top))
                } else {
                    DeckListView(onPlay: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            game.startGame()
                        }
                    })
                    .environmentObject(game)
                    .environment(subscriptionController)
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.spring(duration: 0.5, bounce: 0.42), value: game.playingDeckIndex)
            .navigationTitle("Would You Rather")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if game.playingDeckIndex != nil {
                        Button("Back") {
                            withAnimation {
                                game.stopGame()
                            }
                        }
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if game.playingDeckIndex == nil {
                        Button {
                            handlePremiumAction {
                                showingAddCard = true
                            }
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        
                        
                        Button {
                            handlePremiumAction {
                                showingSettings = true
                            }
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(game)
            }
            .sheet(isPresented: $showingAddCard) {
                DeckBuilderView()
                    .environmentObject(game)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environment(subscriptionController)
            }
        }
        .foregroundStyle(.white)
        .onAppear {
            sessionCount += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                maybeRequestReview()
            }
        }
    }
    
    private func handlePremiumAction(action: () -> Void) {
        if subscriptionController.isSubscribed {
            action()
        } else {
            showingPaywall = true
        }
    }
    
    private func maybeRequestReview() {
        guard sessionCount >= 7, !hasRequestedReview else { return }
        
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: scene)
            hasRequestedReview.toggle()
        }
    }
}



struct ChallengeMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct DeckListView: View {
    @Environment(SubscriptionController.self) var subscriptionController
    @EnvironmentObject var game: GameController
    @Environment(\.modelContext) private var modelContext
    
    @Query private var customDecks: [Deck]
    @Query private var customQuestion: [Question]
    
    @State private var showingPaywall = false
    
    let onPlay: () -> Void
    
    // Two-column layout
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.orange, .pink, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Title bar
                Text("Select Decks")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                
                // Deck grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(game.decks.enumerated()), id: \.element.id) { index, deck in
                            deckCard(deck: deck, isSelected: game.selectedDeckIndices.contains(index)) {
                                //game.toggleDeckSelection(at: index)
                                handleDeckSelection(at: index)
                            }
                        }
                        // Custom deck as last item if available
                        if !game.customDeck.questions.isEmpty {
                            let customIndex = game.decks.count
                            deckCard(deck: game.customDeck, isSelected: game.selectedDeckIndices.contains(customIndex)) {
                                //game.toggleDeckSelection(at: customIndex)
                                handleDeckSelection(at: customIndex)
                            }
                        }
                    }
                    .padding()
                    .background(.clear)
                }
                
                // Play button
                VStack {
                    let deckCount = game.selectedDeckIndices.count
                    let cardCount = game.totalSelectedCards
                    
                    Button {
                        onPlay()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Play")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("\(deckCount) deck\(deckCount != 1 ? "s" : ""), \(cardCount) card\(cardCount != 1 ? "s" : "") selected")
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.title2)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(deckCount > 0 ? Color.green : Color.gray)
                        .cornerRadius(16)
                    }
                    .padding()
                    .disabled(deckCount == 0)
                }
                .background(.clear)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environment(subscriptionController)
            }
        }
        .onAppear {
            Task {
                await game.loadDecks(from: modelContext)
            }
        }
    }
    
    @ViewBuilder
    func deckCard(deck: Deck, isSelected: Bool, action: @escaping () -> Void) -> some View {
        VStack {
            HStack {
                Text(deck.icon)
                    .font(.largeTitle)
                    .foregroundColor(.pink)
                    .blendMode(.screen)
                Spacer()
                Button(action: action) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .green : .primary)
                }
            }
            .padding(.horizontal)
            Spacer()
            Text(deck.name)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom)
        }
        .frame(height: 140)
        .background(.pink)
        .cornerRadius(16)
        .shadow(radius: 5)
        .onTapGesture {
            action()
        }
    }
    
    private func handleDeckSelection(at index: Int) {
        // Allow only first two decks if not subscribed
        if !subscriptionController.isSubscribed {
            // First two decks allowed without subscription (index 0 and 1)
            if index > 1 {
                // Show paywall instead of allowing selection
                showingPaywall = true
                return
            }
            // Also block custom deck (which is at index = game.decks.count)
            if index == game.decks.count {
                showingPaywall = true
                return
            }
        }
        game.toggleDeckSelection(at: index)
    }
}


struct SettingsView: View {
    @EnvironmentObject var game: GameController
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Game Options")) {
                    Toggle("Timed Choice", isOn: $game.timedChoiceEnabled)
                    Toggle("Challenge Mode", isOn: $game.challengeEnabled)
                }
                
                Section {
                    Button {
                        sendFeedbackEmail()
                    } label: {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func sendFeedbackEmail() {
        let subject = "App Feedback – Spicy Would You Rather"
        let body = "Share some feedback..."
        let email = "calebrwells@gmail.com"
        
        let emailURL = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        
        if let url = emailURL {
            UIApplication.shared.open(url)
        }
    }
}


import SwiftUI
import SwiftData

struct DeckBuilderView: View {
    @EnvironmentObject var game: GameController
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var deckName: String = ""
    @State private var selectedIcon: String = "🃏"
    @State private var questions: [QuestionInput] = []
    @State private var saveError: String?
    
    let emojiIcons = [
        "🍑", // peach - playful
        "🍆", // eggplant - cheeky
        "🔥", // fire - hot
        "😈", // devilish grin - mischievous
        "💋", // kiss mark - flirtatious
        "🍒", // cherries - playful
        "💦", // sweat droplets - suggestive
        "👅", // tongue - cheeky
        "💣", // bomb - explosive fun
        "🎉", // party - playful
        "💃", // dancing woman - flirty
        "🖤", // black heart - edgy
        "🍸", // cocktail glass - naughty fun
        "💄", // lipstick - sexy
        "🩸", // drop of blood - edgy or intense
        "🔞", // 18+ symbol - adult only
        "👙", // bikini - playful sexy
        "🌶️", // chili pepper - spicy
        "🥵", // hot face - steamy
        "👠", // high-heel shoe - seductive
        "💍", // ring - suggestive or romantic
        "🙈", // see-no-evil monkey - cheeky innocence
        "🙉", // hear-no-evil monkey - mischievous
        "🙊", // speak-no-evil monkey - secretive
        "😏", // smirking face - flirtatious
        "🤭", // face with hand over mouth - playful secret
        "🥂", // clinking glasses - celebration
        "🛏️", // bed - obvious ;)
        "🧸", // teddy bear - playful/cute contrast
        "👑", // crown - feeling royal, sexy
        "🎀", // ribbon - wrapped gift, tease
        "🧴", // lotion bottle - suggestive
    ]
    
    
    struct QuestionInput: Identifiable {
        let id = UUID()
        var text: String = ""
        var optionA: String = ""
        var optionB: String = ""
        var challengeA: String = ""
        var challengeB: String = ""
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Deck Info") {
                    TextField("Deck Name", text: $deckName)
                    
                    Text("Choose Icon")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(emojiIcons, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.largeTitle)
                                    .padding(8)
                                    .background(selectedIcon == emoji ? Color.accentColor.opacity(0.3) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture {
                                        selectedIcon = emoji
                                    }
                            }
                        }
                    }
                }
                
                Section("Questions") {
                    ForEach($questions) { $q in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Question Text", text: $q.text)
                            TextField("Option A", text: $q.optionA)
                            TextField("Option B", text: $q.optionB)
                            TextField("Challenge A (optional)", text: $q.challengeA)
                            TextField("Challenge B (optional)", text: $q.challengeB)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Button {
                        questions.append(QuestionInput())
                    } label: {
                        Label("Add Question", systemImage: "plus.circle")
                    }
                }
                
                if let saveError {
                    Section {
                        Text(saveError)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Save Deck") {
                        Task {
                            await saveDeck()
                        }
                    }
                    .disabled(deckName.isEmpty || questions.isEmpty || !areQuestionsValid())
                }
            }
            .navigationTitle("Build Deck")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func areQuestionsValid() -> Bool {
        !questions.contains(where: { $0.text.isEmpty || $0.optionA.isEmpty || $0.optionB.isEmpty })
    }
    
    @MainActor
    func saveDeck() async {
        do {
            let newDeck = Deck(name: deckName, icon: selectedIcon)
            
            // Create Question models and add to the deck's relationship
            for q in questions {
                let question = Question(
                    text: q.text,
                    optionA: q.optionA,
                    optionB: q.optionB,
                    challengeA: q.challengeA.isEmpty ? nil : q.challengeA,
                    challengeB: q.challengeB.isEmpty ? nil : q.challengeB
                )
                newDeck.questions.append(question)  // add question to the deck relationship
            }
            
            modelContext.insert(newDeck)
            try modelContext.save()
            
            Task {
                await game.appendDeck(named: deckName, from: modelContext)
            }
            
            dismiss()
        } catch {
            saveError = "Failed to save deck: \(error.localizedDescription)"
        }
    }
}


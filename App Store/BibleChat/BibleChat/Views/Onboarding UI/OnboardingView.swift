//import SwiftUI
//
//struct OnboardingView: View {
//    @Environment(\.dismiss) private var dismiss
//    @State private var currentStep = 0
//    @State private var selectedThemes: Set<String> = []
//    @State private var selectedTime = "Morning"
//    @State private var storeManager = IAPController()
//    @State private var isPurchasing = false
//    @State private var showError = false
//    @State private var errorMessage = ""
//    
//    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
//    
//    let totalSteps = OnboardingStep.allCases.count
//    
//    var body: some View {
//        ZStack {
//            // Background gradient
//            LinearGradient(
//                colors: [
//                    Color.accentColor.opacity(0.1),
//                    Color.accentColor.opacity(0.05)
//                ],
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//            .ignoresSafeArea()
//            
//            VStack(spacing: 0) {
//                // Progress bar
//                if currentStep < totalSteps - 1 {
//                    ProgressView(value: Double(currentStep), total: Double(totalSteps - 1))
//                        .tint(Color.accentColor)
//                        .padding(.horizontal)
//                        .padding(.top)
//                }
//                
//                // Content
//                TabView(selection: $currentStep) {
//                    WelcomeStepView()
//                        .tag(0)
//                    
//                    FeaturesStepView()
//                        .tag(1)
//                    
//                    //                    PersonalizeStepView(
//                    //                        selectedThemes: $selectedThemes,
//                    //                        selectedTime: $selectedTime
//                    //                    )
//                    //                    .tag(2)
//                    
//                    PaywallView(storeManager: storeManager)
//                        .tag(2)
//                }
//                .tabViewStyle(.page(indexDisplayMode: .never))
//                .animation(.easeInOut, value: currentStep)
//                
//                // Navigation buttons
//                HStack(spacing: 16) {
//                    if currentStep > 0 && currentStep < totalSteps - 1 {
//                        Button("Back") {
//                            withAnimation {
//                                currentStep -= 1
//                            }
//                        }
//                        .foregroundStyle(.secondary)
//                    }
//                    
//                    Spacer()
//                    
//                    if currentStep < totalSteps - 1 {
//                        Button(action: {
//                            withAnimation {
//                                if currentStep == totalSteps - 2 {
//                                    // Moving to paywall
//                                    currentStep += 1
//                                } else {
//                                    currentStep += 1
//                                }
//                            }
//                        }) {
//                            Text(currentStep == totalSteps - 2 ? "Continue" : "Next")
//                                .fontWeight(.semibold)
//                                .foregroundStyle(.white)
//                                .frame(maxWidth: currentStep == 0 ? .infinity : nil)
//                                .padding(.horizontal, 32)
//                                .padding(.vertical, 16)
//                                .background(Color.accentColor)
//                                .cornerRadius(12)
//                        }
//                    }
//                }
//                .padding()
//                .background(Color(uiColor: .systemBackground).opacity(0.95))
//            }
//        }
//        .alert("Error", isPresented: $showError) {
//            Button("OK", role: .cancel) {}
//        } message: {
//            Text(errorMessage)
//        }
//    }
//}
//
//// MARK: - Welcome Step
//struct WelcomeStepView: View {
//    var body: some View {
//        VStack(spacing: 32) {
//            Spacer()
//            
//            // App icon or illustration
//            ZStack {
//                Circle()
//                    .fill(Color.accentColor.opacity(0.2))
//                    .frame(width: 140, height: 140)
//                
//                Image(systemName: "book.closed.fill")
//                    .font(.system(size: 60))
//                    .foregroundStyle(Color.accentColor)
//            }
//            
//            VStack(spacing: 12) {
//                Text("Welcome to")
//                    .font(.title2)
//                    .foregroundStyle(.secondary)
//                
//                Text("Holy Bible Chat")
//                    .font(.system(size: 40, weight: .bold))
//                    .multilineTextAlignment(.center)
//                
//                Text("Start each day with inspiration, scripture, and spiritual growth")
//                    .font(.body)
//                    .multilineTextAlignment(.center)
//                    .foregroundStyle(.secondary)
//                    .padding(.horizontal, 32)
//            }
//            
//            Spacer()
//            
//            // Trust indicators
//            VStack(spacing: 16) {
//                HStack(spacing: 32) {
//                    TrustBadge(icon: "checkmark.seal.fill", text: "Biblically Grounded")
//                    TrustBadge(icon: "sparkles", text: "AI-Powered")
//                }
//                
//                HStack(spacing: 32) {
//                    TrustBadge(icon: "heart.fill", text: "Personalized")
//                    TrustBadge(icon: "lock.fill", text: "Private & Secure")
//                }
//            }
//            .padding(.bottom, 32)
//        }
//        .padding()
//    }
//}
//
//struct TrustBadge: View {
//    let icon: String
//    let text: String
//    
//    var body: some View {
//        VStack(spacing: 8) {
//            Image(systemName: icon)
//                .font(.title3)
//                .foregroundStyle(Color.accentColor)
//            
//            Text(text)
//                .font(.caption)
//                .foregroundStyle(.secondary)
//        }
//        .frame(maxWidth: .infinity)
//    }
//}
//
//// MARK: - Features Step
//struct FeaturesStepView: View {
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 40) {
//                VStack(spacing: 12) {
//                    Text("Your Spiritual Journey")
//                        .font(.system(size: 32, weight: .bold))
//                        .multilineTextAlignment(.center)
//                    
//                    Text("Everything you need for daily spiritual growth")
//                        .font(.body)
//                        .foregroundStyle(.secondary)
//                        .multilineTextAlignment(.center)
//                }
//                .padding(.top, 40)
//                
//                VStack(spacing: 32) {
//                    FeatureRow(
//                        icon: "sun.max.fill",
//                        color: .orange,
//                        title: "Daily Devotionals",
//                        description: "Fresh, personalized devotionals generated anytime based on your spiritual journey."
//                    )
//                    
//                    FeatureRow(
//                        icon: "message.fill",
//                        color: .blue,
//                        title: "Bible Chat Assistant",
//                        description: "Get instant, thoughtful answers to your theological questions with scripture references"
//                    )
//                    
//                    FeatureRow(
//                        icon: "bookmark.fill",
//                        color: .purple,
//                        title: "Save & Reflect",
//                        description: "Bookmark meaningful devotionals and revisit them anytime for deeper meditation"
//                    )
//                    
//                    FeatureRow(
//                        icon: "sparkles",
//                        color: .pink,
//                        title: "Custom Themes",
//                        description: "Generate devotionals on specific topics like faith, hope, love, or forgiveness"
//                    )
//                }
//                .padding(.horizontal)
//            }
//        }
//    }
//}
//
//struct FeatureRow: View {
//    let icon: String
//    let color: Color
//    let title: String
//    let description: String
//    
//    var body: some View {
//        HStack(alignment: .top, spacing: 16) {
//            ZStack {
//                Circle()
//                    .fill(color.opacity(0.2))
//                    .frame(width: 56, height: 56)
//                
//                Image(systemName: icon)
//                    .font(.title3)
//                    .foregroundStyle(color)
//            }
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text(title)
//                    .font(.headline)
//                
//                Text(description)
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
//                    .fixedSize(horizontal: false, vertical: true)
//            }
//            
//            Spacer()
//        }
//    }
//}
//
//// MARK: - Personalize Step
//struct PersonalizeStepView: View {
//    @Binding var selectedThemes: Set<String>
//    @Binding var selectedTime: String
//    
//    let themes = ["Faith", "Hope", "Love", "Peace", "Joy", "Forgiveness", "Strength", "Wisdom"]
//    let times = ["Morning", "Afternoon", "Evening"]
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 32) {
//                VStack(spacing: 12) {
//                    Text("Personalize Your Experience")
//                        .font(.system(size: 28, weight: .bold))
//                        .multilineTextAlignment(.center)
//                    
//                    Text("Help us create devotionals that resonate with you")
//                        .font(.body)
//                        .foregroundStyle(.secondary)
//                        .multilineTextAlignment(.center)
//                }
//                .padding(.top, 40)
//                
//                // Preferred time
//                VStack(alignment: .leading, spacing: 16) {
//                    Label("Preferred Time", systemImage: "clock.fill")
//                        .font(.headline)
//                        .foregroundStyle(Color.accentColor)
//                    
//                    HStack(spacing: 12) {
//                        ForEach(times, id: \.self) { time in
//                            Button {
//                                selectedTime = time
//                            } label: {
//                                Text(time)
//                                    .font(.subheadline)
//                                    .fontWeight(.medium)
//                                    .foregroundStyle(selectedTime == time ? .white : .primary)
//                                    .padding(.horizontal, 20)
//                                    .padding(.vertical, 12)
//                                    .background(selectedTime == time ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
//                                    .cornerRadius(20)
//                            }
//                        }
//                    }
//                }
//                
//                // Themes of interest
//                VStack(alignment: .leading, spacing: 16) {
//                    Label("Themes of Interest", systemImage: "heart.fill")
//                        .font(.headline)
//                        .foregroundStyle(Color.accentColor)
//                    
//                    Text("Select topics you'd like to explore")
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                    
//                    LazyVGrid(columns: [
//                        GridItem(.flexible()),
//                        GridItem(.flexible())
//                    ], spacing: 12) {
//                        ForEach(themes, id: \.self) { theme in
//                            Button {
//                                if selectedThemes.contains(theme) {
//                                    selectedThemes.remove(theme)
//                                } else {
//                                    selectedThemes.insert(theme)
//                                }
//                            } label: {
//                                HStack {
//                                    Text(theme)
//                                        .font(.subheadline)
//                                        .fontWeight(.medium)
//                                    
//                                    if selectedThemes.contains(theme) {
//                                        Image(systemName: "checkmark.circle.fill")
//                                            .font(.caption)
//                                    }
//                                }
//                                .foregroundStyle(selectedThemes.contains(theme) ? .white : .primary)
//                                .frame(maxWidth: .infinity)
//                                .padding(.vertical, 12)
//                                .background(selectedThemes.contains(theme) ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
//                                .cornerRadius(12)
//                            }
//                        }
//                    }
//                }
//                
//                Spacer(minLength: 100)
//            }
//            .padding()
//        }
//    }
//}






import SwiftUI
import SwiftData
import UserNotifications

// MARK: - SwiftData Models

@Model
final class UserProfile {
    var name: String
    var motivationSource: String
    var struggles: [String]
    var unmotivatedActions: [String]
    var motivationPush: String
    var goals: [String]
    var dailyHabits: [String]
    var notificationCount: Int
    var notificationStartTime: Date
    var notificationEndTime: Date
    var favoriteVerseThemes: [String]
    var prayerFocus: [String]
    var spiritualGoals: [String]
    var readingPreference: String
    var favoriteBookGenre: String
    var devotionalTime: String
    var currentStreak: Int
    var lastOpenedDate: Date?
    var hasCompletedOnboarding: Bool
    
    init(
        name: String = "",
        motivationSource: String = "",
        struggles: [String] = [],
        unmotivatedActions: [String] = [],
        motivationPush: String = "",
        goals: [String] = [],
        dailyHabits: [String] = [],
        notificationCount: Int = 3,
        notificationStartTime: Date = Calendar.current.date(from: DateComponents(hour: 9)) ?? Date(),
        notificationEndTime: Date = Calendar.current.date(from: DateComponents(hour: 20)) ?? Date(),
        favoriteVerseThemes: [String] = [],
        prayerFocus: [String] = [],
        spiritualGoals: [String] = [],
        readingPreference: String = "morning",
        favoriteBookGenre: String = "psalms",
        devotionalTime: String = "morning",
        currentStreak: Int = 0,
        lastOpenedDate: Date? = nil,
        hasCompletedOnboarding: Bool = false
    ) {
        self.name = name
        self.motivationSource = motivationSource
        self.struggles = struggles
        self.unmotivatedActions = unmotivatedActions
        self.motivationPush = motivationPush
        self.goals = goals
        self.dailyHabits = dailyHabits
        self.notificationCount = notificationCount
        self.notificationStartTime = notificationStartTime
        self.notificationEndTime = notificationEndTime
        self.favoriteVerseThemes = favoriteVerseThemes
        self.prayerFocus = prayerFocus
        self.spiritualGoals = spiritualGoals
        self.readingPreference = readingPreference
        self.favoriteBookGenre = favoriteBookGenre
        self.devotionalTime = devotionalTime
        self.currentStreak = currentStreak
        self.lastOpenedDate = lastOpenedDate
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

// MARK: - App Storage Keys

struct AppStorageKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @State private var currentStep = 1
    @State private var userProfile = UserProfile()
//    @State private var storeManager = IAPController()
    
    private let totalSteps = 16
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.25),
                    Color(red: 0.15, green: 0.25, blue: 0.4),
                    Color(red: 0.1, green: 0.15, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 4)
                            .animation(.spring(response: 0.3), value: currentStep)
                    }
                }
                .frame(height: 4)
                
                // Content
                ScrollView {
                    VStack {
                        stepView
                            .padding(.horizontal, 24)
                            .padding(.top, 40)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Spacer()
                
                // Navigation
                HStack {
                    if currentStep > 1 {
                        Button(action: { withAnimation { currentStep -= 1 } }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(25)
                        }
                    }
//                    else {
//                        Spacer()
//                            .frame(width: 100)
//                    }
                    
//                    Spacer()
                    
                    // Step Indicators
//                    HStack(spacing: 4) {
//                        ForEach(1...totalSteps, id: \.self) { step in
//                            RoundedRectangle(cornerRadius: 2)
//                                .fill(step == currentStep ? Color.blue : Color.white.opacity(0.3))
//                                .frame(width: step == currentStep ? 24 : 6, height: 6)
//                                .animation(.spring(response: 0.3), value: currentStep)
//                        }
//                    }
//                    
//                    Spacer()
                    
                    Button(action: handleNext) {
                        HStack(spacing: 8) {
                            Text(currentStep == totalSteps ? "Finish" : "Continue")
//                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: canProceed() ? [.blue, .purple] : [.gray.opacity(0.5), .gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: canProceed() ? .blue.opacity(0.5) : .clear, radius: 10)
                    }
                    .disabled(!canProceed())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
    }
    
    @ViewBuilder
    private var stepView: some View {
        Group {
            switch currentStep {
            case 1: WelcomeStepView()
            case 2: NameStepView(name: $userProfile.name)
            case 3: MotivationStepView(motivation: $userProfile.motivationSource)
            case 4: StrugglesStepView(struggles: $userProfile.struggles)
            case 5: UnmotivatedActionsStepView(actions: $userProfile.unmotivatedActions)
            case 6: MotivationPushStepView(push: $userProfile.motivationPush)
                //
            case 7: GoalsStepView(goals: $userProfile.goals)
            case 8: DailyHabitsStepView(habits: $userProfile.dailyHabits)
//            case 9: StreakStepView()
            case 9: NotificationSetupStepView(
                count: $userProfile.notificationCount,
                startTime: $userProfile.notificationStartTime,
                endTime: $userProfile.notificationEndTime
            )
            case 10: VerseThemesStepView(themes: $userProfile.favoriteVerseThemes)
            case 11: PrayerFocusStepView(focus: $userProfile.prayerFocus)
            case 12: SpiritualGoalsStepView(goals: $userProfile.spiritualGoals)
            case 13: ReadingPreferenceStepView(preference: $userProfile.readingPreference)
            case 14: FavoriteBookStepView(genre: $userProfile.favoriteBookGenre)
            case 15: DevotionalTimeStepView(time: $userProfile.devotionalTime)
//            case 17: CommunityStepView()
            case 16: FinalStepView(name: userProfile.name)
//            case 17: PaywallView(storeManager: storeManager)
            default: EmptyView()
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    private func canProceed() -> Bool {
        switch currentStep {
        case 2: return !userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 3: return !userProfile.motivationSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 4: return !userProfile.struggles.isEmpty
        case 5: return !userProfile.unmotivatedActions.isEmpty
        case 6: return !userProfile.motivationPush.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 7: return !userProfile.goals.isEmpty
        case 8: return !userProfile.dailyHabits.isEmpty
        case 11: return !userProfile.favoriteVerseThemes.isEmpty
        case 12: return !userProfile.prayerFocus.isEmpty
        case 13: return !userProfile.spiritualGoals.isEmpty
        default: return true
        }
    }
    
    private func handleNext() {
        if currentStep < totalSteps {
            withAnimation(.spring(response: 0.4)) {
                currentStep += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        userProfile.hasCompletedOnboarding = true
        userProfile.lastOpenedDate = Date()
        modelContext.insert(userProfile)
        try? modelContext.save()
        
        // Schedule notifications
        scheduleNotifications()
        
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
    
    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            
            center.removeAllPendingNotificationRequests()
            
            let calendar = Calendar.current
            let startHour = calendar.component(.hour, from: userProfile.notificationStartTime)
            let startMinute = calendar.component(.minute, from: userProfile.notificationStartTime)
            let endHour = calendar.component(.hour, from: userProfile.notificationEndTime)
            
            let totalMinutes = (endHour - startHour) * 60
            let interval = totalMinutes / userProfile.notificationCount
            
            for i in 0..<userProfile.notificationCount {
                let minutesFromStart = i * interval
                let notificationHour = startHour + (minutesFromStart / 60)
                let notificationMinute = startMinute + (minutesFromStart % 60)
                
                var dateComponents = DateComponents()
                dateComponents.hour = notificationHour
                dateComponents.minute = notificationMinute
                
                let content = UNMutableNotificationContent()
                content.title = "Daily Inspiration"
                content.body = "A moment of motivation awaits you 🙏"
                content.sound = .default
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "motivation-\(i)",
                    content: content,
                    trigger: trigger
                )
                
                center.add(request)
            }
        }
    }
}

// MARK: - Step 1: Welcome

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 16) {
                Text("Welcome to Your\nSpiritual Journey")
                    .font(.system(size: 36, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Let's personalize your experience with daily inspiration from Scripture")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
        }
    }
}

// MARK: - Step 2: Name

struct NameStepView: View {
    @Binding var name: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What should we call you?")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("We'll use this to personalize your experience")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            TextField("Enter your name", text: $name)
                .font(.system(size: 20))
                .padding(20)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color.blue : Color.white.opacity(0.2), lineWidth: 2)
                )
                .focused($isFocused)
                .onAppear {
                    isFocused = true
                }
        }
        .padding(.top, 60)
    }
}

// MARK: - Step 3: Motivation Source

struct MotivationStepView: View {
    @Binding var motivation: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What is your source of\nmotivation every day?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Understanding what drives you helps us provide relevant inspiration")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Share what motivates you")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                TextEditor(text: $motivation)
                    .font(.system(size: 18))
                    .frame(height: 150)
                    .padding(16)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isFocused ? Color.blue : Color.white.opacity(0.2), lineWidth: 2)
                    )
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
            }
        }
        .padding(.top, 40)
    }
}

// MARK: - Step 4: Struggles

struct StrugglesStepView: View {
    @Binding var struggles: [String]
    
    let options = [
        "Healthy habits",
        "Staying motivated",
        "Managing stress and anxiety",
        "Mental health",
        "Personal relationships",
        "School/work"
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Do you struggle to stay\nconsistent in any area?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    SelectableButton(
                        title: option,
                        isSelected: struggles.contains(option)
                    ) {
                        toggleSelection(option)
                    }
                }
            }
        }
        .padding(.top, 40)
    }
    
    private func toggleSelection(_ item: String) {
        if struggles.contains(item) {
            struggles.removeAll { $0 == item }
        } else {
            struggles.append(item)
        }
    }
}

// MARK: - Step 5: Unmotivated Actions

struct UnmotivatedActionsStepView: View {
    @Binding var actions: [String]
    
    let options = [
        "Take a break",
        "Talk to someone",
        "Exercise or move",
        "Listen to music",
        "Read or watch something inspiring",
        "Pray or meditate"
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What do you do when\nyou're not motivated?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    SelectableButton(
                        title: option,
                        isSelected: actions.contains(option)
                    ) {
                        toggleSelection(option)
                    }
                }
            }
        }
        .padding(.top, 40)
    }
    
    private func toggleSelection(_ item: String) {
        if actions.contains(item) {
            actions.removeAll { $0 == item }
        } else {
            actions.append(item)
        }
    }
}

// MARK: - Step 6: Motivation Push

struct MotivationPushStepView: View {
    @Binding var push: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What gives you a push\nwhen you're unmotivated?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("This helps us understand what inspires you")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Describe what helps you most")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                TextEditor(text: $push)
                    .font(.system(size: 18))
                    .frame(height: 150)
                    .padding(16)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isFocused ? Color.blue : Color.white.opacity(0.2), lineWidth: 2)
                    )
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
            }
        }
        .padding(.top, 40)
    }
}

// MARK: - Step 7: Goals

struct GoalsStepView: View {
    @Binding var goals: [String]
    
    let options = [
        "Build better habits",
        "Improve mental health",
        "Strengthen relationships",
        "Grow spiritually",
        "Achieve work/school goals",
        "Develop self-discipline"
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Customize the app to\nwhat you want to achieve")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Select your primary goals")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    SelectableButton(
                        title: option,
                        isSelected: goals.contains(option)
                    ) {
                        toggleSelection(option)
                    }
                }
            }
        }
        .padding(.top, 40)
    }
    
    private func toggleSelection(_ item: String) {
        if goals.contains(item) {
            goals.removeAll { $0 == item }
        } else {
            goals.append(item)
        }
    }
}

// MARK: - Step 8: Daily Habits

struct DailyHabitsStepView: View {
    @Binding var habits: [String]
    
    let options = [
        "Daily reminders",
        "Morning devotionals",
        "Evening reflection",
        "Gratitude journaling",
        "Scripture memorization",
        "Prayer time"
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What would help make\nmotivation a daily habit?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Choose what resonates with you")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    SelectableButton(
                        title: option,
                        isSelected: habits.contains(option)
                    ) {
                        toggleSelection(option)
                    }
                }
            }
        }
        .padding(.top, 40)
    }
    
    private func toggleSelection(_ item: String) {
        if habits.contains(item) {
            habits.removeAll { $0 == item }
        } else {
            habits.append(item)
        }
    }
}

// MARK: - Step 9: Streak

//struct StreakStepView: View {
//    @State private var animateFlame = false
//    
//    var body: some View {
//        VStack(spacing: 40) {
//            VStack(spacing: 16) {
//                Text("Stay motivated with a\nconsistent daily routine")
//                    .font(.system(size: 28, weight: .bold))
//                    .multilineTextAlignment(.center)
//                
//                Text("Build a streak one day at a time")
//                    .font(.system(size: 16))
//                    .foregroundColor(.white.opacity(0.7))
//            }
//            
//            VStack(spacing: 24) {
//                ZStack {
//                    Circle()
//                        .fill(
//                            RadialGradient(
//                                colors: [.orange.opacity(0.3), .clear],
//                                center: .center,
//                                startRadius: 20,
//                                endRadius: 80
//                            )
//                        )
//                        .frame(width: 160, height: 160)
//                        .scaleEffect(animateFlame ? 1.1 : 1.0)
//                    
//                    Image(systemName: "flame.fill")
//                        .font(.system(size: 80))
//                        .foregroundStyle(
//                            LinearGradient(
//                                colors: [.orange, .red],
//                                startPoint: .top,
//                                endPoint: .bottom
//                            )
//                        )
//                        .offset(y: animateFlame ? -5 : 0)
//                }
//                
//                VStack(spacing: 8) {
//                    Text("0")
//                        .font(.system(size: 56, weight: .bold))
//                    
//                    Text("Day Streak")
//                        .font(.system(size: 18))
//                        .foregroundColor(.white.opacity(0.7))
//                }
//                
//                VStack(spacing: 12) {
//                    HStack(spacing: 8) {
//                        ForEach(0..<7) { index in
//                            RoundedRectangle(cornerRadius: 8)
//                                .fill(Color.white.opacity(0.1))
//                                .frame(width: 40, height: 50)
//                                .overlay(
//                                    VStack(spacing: 4) {
//                                        Text(["M", "T", "W", "T", "F", "S", "S"][index])
//                                            .font(.system(size: 12, weight: .medium))
//                                            .foregroundColor(.white.opacity(0.5))
//                                        
//                                        Circle()
//                                            .fill(Color.white.opacity(0.2))
//                                            .frame(width: 6, height: 6)
//                                    }
//                                )
//                        }
//                    }
//                    
//                    Text("Your journey starts tomorrow")
//                        .font(.system(size: 14))
//                        .foregroundColor(.white.opacity(0.5))
//                }
//            }
//        }
//        .padding(.top, 40)
//        .onAppear {
//            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
//                animateFlame = true
//            }
//        }
//    }
//}

// MARK: - Step 10: Notification Setup

struct NotificationSetupStepView: View {
    @Binding var count: Int
    @Binding var startTime: Date
    @Binding var endTime: Date
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Get quotes throughout\nthe day")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Small doses of motivation can make a big difference in your life")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 24) {
                // Notification Count
                VStack(alignment: .leading, spacing: 12) {
                    Text("How many times per day?")
                        .font(.system(size: 16, weight: .semibold))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(1...10, id: \.self) { num in
                                Button(action: { count = num }) {
                                    Text("\(num)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(count == num ? .white : .white.opacity(0.5))
                                        .frame(width: 50, height: 50)
                                        .background(
                                            count == num ?
                                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                            LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                
                // Time Range
                VStack(alignment: .leading, spacing: 16) {
                    Text("When should we send them?")
                        .font(.system(size: 16, weight: .semibold))
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start time")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            
                            DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white.opacity(0.5))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("End time")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            
                            DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                
                // Preview
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.blue)
                    Text("You'll receive \(count) inspirational \(count == 1 ? "quote" : "quotes") per day")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.top, 40)
    }
}

// MARK: - Step 11: Verse Themes

struct VerseThemesStepView: View {
    @Binding var themes: [String]
    
    let options = [
        "Hope and Encouragement",
        "Peace and Comfort",
        "Strength and Courage",
        "Love and Compassion",
        "Faith and Trust",
        "Wisdom and Guidance",
        "Gratitude and Praise",
        "Forgiveness and Grace"
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What themes resonate\nwith you most?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("We'll personalize your daily verses")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    SelectableButton(
                        title: option,
                        isSelected: themes.contains(option)
                    ) {
                        toggleSelection(option)
                    }
                }
            }
        }
        .padding(.top, 40)
    }
    
    private func toggleSelection(_ item: String) {
        if themes.contains(item) {
            themes.removeAll { $0 == item }
        } else {
            themes.append(item)
        }
    }
}

// MARK: - Step 12: Prayer Focus

struct PrayerFocusStepView: View {
    @Binding var focus: [String]
    
    let options = [
        "Family and relationships",
        "Health and healing",
        "Career and purpose",
        "Financial provision",
        "Spiritual growth",
        "Peace and anxiety",
        "Guidance and direction",
        "Gratitude and thanksgiving"
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What are you praying\nabout right now?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Select your areas of focus")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    SelectableButton(
                        title: option,
                        isSelected: focus.contains(option)
                    ) {
                        toggleSelection(option)
                    }
                }
            }
        }
        .padding(.top, 40)
    }
    
    private func toggleSelection(_ item: String) {
        if focus.contains(item) {
            focus.removeAll { $0 == item }
        } else {
            focus.append(item)
        }
    }
}

// MARK: - Step 13: Spiritual Goals

struct SpiritualGoalsStepView: View {
    @Binding var goals: [String]
    
    let options = [
        "Read through the Bible",
        "Memorize Scripture",
        "Develop prayer life",
        "Understand God's word deeper",
        "Share faith with others",
        "Serve my community",
        "Overcome challenges",
        "Grow in character"
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What are your\nspiritual goals?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Let's focus your journey")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    SelectableButton(
                        title: option,
                        isSelected: goals.contains(option)
                    ) {
                        toggleSelection(option)
                    }
                }
            }
        }
        .padding(.top, 40)
    }
    
    private func toggleSelection(_ item: String) {
        if goals.contains(item) {
            goals.removeAll { $0 == item }
        } else {
            goals.append(item)
        }
    }
}

// MARK: - Step 14: Reading Preference

struct ReadingPreferenceStepView: View {
    @Binding var preference: String
    
    let options = [
        ("morning", "Morning", "Start your day with inspiration", "sunrise.fill"),
        ("afternoon", "Afternoon", "Midday spiritual refreshment", "sun.max.fill"),
        ("evening", "Evening", "End your day with reflection", "moon.stars.fill"),
        ("anytime", "Anytime", "Whenever the moment feels right", "clock.fill")
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("When do you prefer\nto read Scripture?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("We'll optimize your experience")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(options, id: \.0) { option in
                    Button(action: { preference = option.0 }) {
                        HStack(spacing: 16) {
                            Image(systemName: option.3)
                                .font(.system(size: 24))
                                .foregroundColor(preference == option.0 ? .blue : .white.opacity(0.5))
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.1)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(option.2)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Image(systemName: preference == option.0 ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(preference == option.0 ? .blue : .white.opacity(0.3))
                        }
                        .padding(20)
                        .background(
                            preference == option.0 ?
                            Color.blue.opacity(0.15) :
                            Color.white.opacity(0.05)
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(preference == option.0 ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
        .padding(.top, 40)
    }
}

// MARK: - Step 15: Favorite Book

struct FavoriteBookStepView: View {
    @Binding var genre: String
    
    let options = [
        ("psalms", "Psalms", "Poetry and worship", "music.note"),
        ("proverbs", "Proverbs", "Wisdom and guidance", "lightbulb.fill"),
        ("gospels", "Gospels", "Life of Jesus", "cross.fill"),
        ("epistles", "Epistles", "Letters to churches", "envelope.fill"),
        ("prophets", "Prophets", "God's messengers", "megaphone.fill"),
        ("all", "All Books", "Explore everything", "book.fill")
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What's your favorite\npart of the Bible?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("We'll prioritize these in your feed")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(options, id: \.0) { option in
                    Button(action: { genre = option.0 }) {
                        HStack(spacing: 16) {
                            Image(systemName: option.3)
                                .font(.system(size: 22))
                                .foregroundColor(genre == option.0 ? .purple : .white.opacity(0.5))
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.1)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(option.2)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Image(systemName: genre == option.0 ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(genre == option.0 ? .purple : .white.opacity(0.3))
                        }
                        .padding(20)
                        .background(
                            genre == option.0 ?
                            Color.purple.opacity(0.15) :
                            Color.white.opacity(0.05)
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(genre == option.0 ? Color.purple.opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
        .padding(.top, 40)
    }
}

// MARK: - Step 16: Devotional Time

struct DevotionalTimeStepView: View {
    @Binding var time: String
    
    let options = [
        ("morning", "Morning Devotional", "Start your day in His word", "sunrise.fill", [Color.orange, .yellow]),
        ("lunch", "Midday Reflection", "Pause and refocus", "sun.max.fill", [.yellow, .orange]),
        ("evening", "Evening Meditation", "Reflect on the day", "sunset.fill", [.orange, .red]),
        ("night", "Night Prayer", "End in gratitude", "moon.stars.fill", [.blue, .purple])
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("When would you like\nyour devotional time?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Choose your daily moment with God")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                ForEach(options, id: \.0) { option in
                    Button(action: { time = option.0 }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: time == option.0 ? option.4 : [.white.opacity(0.1), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: option.3)
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.1)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(option.2)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Image(systemName: time == option.0 ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(time == option.0 ? .green : .white.opacity(0.3))
                        }
                        .padding(20)
                        .background(
                            time == option.0 ?
                            LinearGradient(
                                colors: option.4.map { $0.opacity(0.15) },
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.05), Color.white.opacity(0.05)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    time == option.0 ?
                                    LinearGradient(colors: option.4, startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [.clear, .clear], startPoint: .leading, endPoint: .trailing),
                                    lineWidth: 2
                                )
                        )
                    }
                }
            }
        }
        .padding(.top, 40)
    }
}

// MARK: - Step 17: Community

//struct CommunityStepView: View {
//    var body: some View {
//        VStack(spacing: 40) {
//            VStack(spacing: 16) {
//                Text("Join a community\nof believers")
//                    .font(.system(size: 28, weight: .bold))
//                    .multilineTextAlignment(.center)
//                
//                Text("Connect with others on their faith journey")
//                    .font(.system(size: 16))
//                    .foregroundColor(.white.opacity(0.7))
//                    .multilineTextAlignment(.center)
//            }
//            
//            VStack(spacing: 24) {
//                CommunityFeatureCard(
//                    icon: "person.2.fill",
//                    title: "Share Insights",
//                    description: "Discuss verses with fellow believers"
//                )
//                
//                CommunityFeatureCard(
//                    icon: "heart.text.square.fill",
//                    title: "Prayer Requests",
//                    description: "Support others through prayer"
//                )
//                
//                CommunityFeatureCard(
//                    icon: "bookmark.fill",
//                    title: "Favorite Verses",
//                    description: "Save and share meaningful scriptures"
//                )
//                
////                CommunityFeatureCard(
////                    icon: "chart.line.uptrend.xyaxis",
////                    title: "Track Growth",
////                    description: "See your spiritual journey progress"
////                )
//            }
//            
//            Text("You can explore these features anytime in settings")
//                .font(.system(size: 14))
//                .foregroundColor(.white.opacity(0.5))
//                .multilineTextAlignment(.center)
//                .padding(.horizontal)
//        }
//        .padding(.top, 40)
//    }
//}

struct CommunityFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Step 18: Final

struct FinalStepView: View {
    let name: String
    @State private var animateCheck = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
//                        LinearGradient(
//                            colors: [.green.opacity(0.3), .clear],
////                            center: .center,
//                            startRadius: 20,
//                            endRadius: 80
//                        )
                        .green
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(animateCheck ? 1.0 : 0.8)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateCheck ? 1.0 : 0.5)
            }
            
            VStack(spacing: 16) {
                Text("You're all set, \(name)!")
                    .font(.system(size: 36, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Your personalized Bible experience is ready. Let's begin your journey of daily inspiration and spiritual growth.")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 12) {
                FeatureBadge(icon: "bell.fill", text: "Daily reminders set")
                FeatureBadge(icon: "heart.fill", text: "Personalized quotes ready")
//                FeatureBadge(icon: "chart.line.uptrend.xyaxis", text: "Streak tracker active")
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                animateCheck = true
            }
        }
    }
}

struct FeatureBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

// MARK: - Reusable Components

struct SelectableButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.3))
            }
            .padding(20)
            .background(
                isSelected ?
                Color.blue.opacity(0.15) :
                Color.white.opacity(0.05)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
    }
}

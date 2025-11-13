import SwiftUI
import SwiftData
import StoreKit

// MARK: - Onboarding View
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var showHealthAccess = false
    let healthKit: HealthKitManager
    let onComplete: () -> Void
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "figure.walk.circle.fill",
            title: "Track Your Health Goals",
            description: "Set personalized fitness goals and monitor your progress with ease. From steps to workouts, we've got you covered.",
            color: .green
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis.circle.fill",
            title: "Visualize Your Progress",
            description: "See your daily achievements at a glance with beautiful charts and weekly calendars that keep you motivated.",
            color: .blue
        ),
        OnboardingPage(
            icon: "calendar.circle.fill",
            title: "Build Healthy Streaks",
            description: "Stay consistent with streak tracking and detailed statistics that celebrate your dedication to wellness.",
            color: .purple
        ),
        OnboardingPage(
            icon: "heart.circle.fill",
            title: "Connect with Health",
            description: "Seamlessly sync with Apple Health to automatically track your activities and maintain accurate records.",
            color: .red
        )
    ]
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if showHealthAccess {
                HealthAccessView(healthKit: healthKit, onComplete: {
                    hasCompletedOnboarding = true
                    onComplete()
                })
                .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 0) {
                    // Skip button
                    HStack {
                        Spacer()
                        Button("Skip") {
                            showHealthAccess = true
                        }
                        .padding()
                        .foregroundStyle(.secondary)
                    }
                    
                    // Page content
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            OnboardingPageView(page: pages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? pages[currentPage].color : Color.gray.opacity(0.3))
                                .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Action button
                    Button {
                        withAnimation {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                showHealthAccess = true
                            }
                        }
                    } label: {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(pages[currentPage].color)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut, value: showHealthAccess)
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 120))
                .foregroundStyle(page.color)
                .symbolEffect(.bounce, value: page.icon)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Health Access View
struct HealthAccessView: View {
    let healthKit: HealthKitManager
    let onComplete: () -> Void
    @State private var isRequesting = false
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 120))
                .foregroundStyle(.red)
                .symbolEffect(.pulse)
            
            // Content
            VStack(spacing: 16) {
                Text("Health Data Access")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("To track your goals automatically, we need permission to read your health data from the Health app.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Privacy info
            VStack(alignment: .leading, spacing: 16) {
                PrivacyInfoRow(
                    icon: "lock.shield.fill",
                    text: "Your data stays on your device"
                )
                PrivacyInfoRow(
                    icon: "eye.slash.fill",
                    text: "We never share your health information"
                )
                PrivacyInfoRow(
                    icon: "checkmark.seal.fill",
                    text: "You control what data we can access"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Error message
            if showError {
                Text(healthKit.authorizationError ?? "Failed to access Health data")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 32)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button {
                    isRequesting = true
                    Task {
                        await healthKit.requestAuthorization()
                        isRequesting = false
                        if healthKit.isAuthorized {
                            onComplete()
                        } else {
                            showError = true
                        }
                    }
                } label: {
                    Group {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Allow Health Access")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red)
                    .cornerRadius(16)
                }
                .disabled(isRequesting)
                
//                Button {
//                    onComplete()
//                } label: {
//                    Text("Maybe Later")
//                        .font(.headline)
//                        .foregroundStyle(.secondary)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color(.systemGray6))
//                        .cornerRadius(16)
//                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Privacy Info Row
struct PrivacyInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 30)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Updated ContentView with Onboarding
struct ContentViewWithOnboarding: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Goal.createdAt)]) private var goals: [Goal]
    @State private var viewModel = HealthViewModel()
    @State private var showingAddGoal = false
    @State private var showOnboarding = false
    private let store = StoreManager.shared
    
    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        if !viewModel.healthKit.isAuthorized {
                            AuthorizationView(viewModel: viewModel)
                        } else if viewModel.goals.isEmpty {
                            EmptyStateView(showingAddGoal: $showingAddGoal)
                        } else {
                            ForEach(viewModel.goals, id: \.id) { goal in
                                GoalCardView(goal: goal, viewModel: viewModel)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Health Goals")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddGoal = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    
                    if viewModel.healthKit.isAuthorized && !viewModel.goals.isEmpty {
                        ToolbarItem(placement: .topBarLeading) {
                            Menu {
                                Button {
                                    Task { await viewModel.refreshAllGoals() }
                                } label: {
                                    Label("Refresh", systemImage: "arrow.clockwise")
                                }
                                Button {
                                    openFeedbackEmail()
                                } label: {
                                    Label("Send Feedback", systemImage: "envelope")
                                }
                                Button {
                                    requestAppReview()
                                } label: {
                                    Label("Rate App", systemImage: "star")
                                }
                                Button {
                                    Task { await store.restorePurchases() }
                                } label: {
                                    Label("Restore Purchases", systemImage: "arrow.uturn.left")
                                }
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingAddGoal) {
                    if goals.count >= 2 && !store.hasUnlockedUnlimitedGoals {
                        PaywallView()
                    } else {
                        AddGoalView(viewModel: viewModel)
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
                if !hasCompletedOnboarding {
                    showOnboarding = true
                } else if !viewModel.healthKit.isAuthorized {
                    Task {
                        await viewModel.healthKit.requestAuthorization()
                        if viewModel.healthKit.isAuthorized {
                            viewModel.loadData()
                        }
                    }
                }
            }
            .onChange(of: goals.count) { _, _ in
                viewModel.loadData()
            }
            
            // Onboarding overlay
            if showOnboarding {
                OnboardingView(healthKit: viewModel.healthKit) {
                    withAnimation {
                        showOnboarding = false
                    }
                    viewModel.loadData()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshAllGoals()
            }
        }
    }
    
    private func openFeedbackEmail() {
        if let url = URL(string: "mailto:caleb@olyevolutions.com?subject=Health%20Habitss%20Feedback") {
            UIApplication.shared.open(url)
        }
    }

    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Preview
#Preview("Onboarding") {
    OnboardingView(healthKit: HealthKitManager()) {
        print("Onboarding completed")
    }
}

#Preview("Health Access") {
    HealthAccessView(healthKit: HealthKitManager()) {
        print("Health access completed")
    }
}

#Preview("Full App with Onboarding") {
    ContentViewWithOnboarding()
        .modelContainer(for: [Goal.self, DailyGoalData.self], inMemory: true)
}

import SwiftUI
import StoreKit
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(SubscriptionController.self) var subscriptionController
    @Query private var bills: [Transaction]
    @Query(sort: \Category.name) private var categories: [Category]
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("sessionCount") private var sessionCount = 0
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    @AppStorage("hasSeenReviewPrompt") private var hasSeenReviewPrompt = false
    
    @State private var budget = BudgetController()
    @State private var isAddTransactionsShowing = false
    @State private var draftBill = Transaction()
    @State private var tabSelection = 1
    @State private var showingPaywall = false
    
    init() {
        // Navigation Bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor.label
        
        // Tab Bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    var body: some View {
        NavigationStack {
            if hasSeenOnboarding {
                TabView(selection: $tabSelection) {
                    Tab("Summary", systemImage: "dollarsign.gauge.chart.leftthird.topthird.rightthird", value: 1) {
                        if subscriptionController.isSubscribed {
                            SummaryTabView()
                                .environment(budget)
                                .environment(subscriptionController)
                        } else {
                            PaywallView()
                        }
                    }
                    
                    Tab("Expenses", systemImage: "creditcard", value: 2) {
                        ExpenseTrackerView(tabSelection: $tabSelection)
                            .environment(budget)
                    }
                    
                    Tab("Bills", systemImage: "calendar.badge.clock", value: 3) {
                        BillsListView(
                            isAddTransactionsShowing: $isAddTransactionsShowing,
                            draftBill: $draftBill,
                            tabSelection: $tabSelection
                        )
                        .environment(budget)
                    }
                    
                    Tab("Income", systemImage: "dollarsign.circle", value: 4) {
                        if subscriptionController.isSubscribed {
                            IncomeTabView(tabSelection: $tabSelection)
                        } else {
                            PaywallView()
                        }
                    }
                }
                .navigationTitle(tabSelection == 1 && subscriptionController.isSubscribed ? "\(Date().formatted(.dateTime.month(.wide))) overview" : "")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            sendFeedbackEmail()
                        } label: {
                            Label("Send Feedback", systemImage: "envelope")
                        }
                    }
                }
                .onAppear {
                    tabSelection = subscriptionController.isSubscribed ? 1: 2
                    sessionCount += 1
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        maybeRequestReview()
                    }
                    
                    let center = UNUserNotificationCenter.current()
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                }
                .whatsNewSheet()
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            }
        }
        .onAppear {
            preloadDefaultCategoriesIfNeeded()
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
    
    func sendFeedbackEmail() {
        let subject = "App Feedback – Simpler Budget"
        let body = "Share some feedback..."
        let email = "calebrwells@gmail.com"
        
        let emailURL = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")

        if let url = emailURL {
            UIApplication.shared.open(url)
        }
    }
    
    func preloadDefaultCategoriesIfNeeded() {
        let descriptor = FetchDescriptor<Category>()
        let existing = try? context.fetch(descriptor)
        
        guard existing?.isEmpty ?? true else { return }
        
        for expenseCategory in ExpenseCategory.allCases {
            let category = Category(
                name: expenseCategory.label,
                icon: expenseCategory.symbolName,
                isDefault: true
            )
            context.insert(category)
        }
        
        try? context.save()
    }
}

#Preview {
    ContentView()
}

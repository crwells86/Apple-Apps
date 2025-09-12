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
    
    //    init() {
    //        // Navigation Bar appearance
    //        let navBarAppearance = UINavigationBarAppearance()
    //        navBarAppearance.configureWithOpaqueBackground()
    //        navBarAppearance.backgroundColor = UIColor.systemBackground
    //        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
    //        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
    //
    //        UINavigationBar.appearance().standardAppearance = navBarAppearance
    //        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    //        UINavigationBar.appearance().compactAppearance = navBarAppearance
    //        UINavigationBar.appearance().tintColor = UIColor.label
    //
    //        // Tab Bar appearance
    //        let tabBarAppearance = UITabBarAppearance()
    //        tabBarAppearance.configureWithOpaqueBackground()
    //        tabBarAppearance.backgroundColor = UIColor.systemBackground
    //        UITabBar.appearance().standardAppearance = tabBarAppearance
    //        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    //    }
    
    var body: some View {
        //        NavigationStack {
        if hasSeenOnboarding {
            TabView(selection: $tabSelection) {
                Tab("Summary", systemImage: "dollarsign.gauge.chart.leftthird.topthird.rightthird", value: 1) {
                    if subscriptionController.isSubscribed {
                        //                            NavigationStack {
                        SummaryTabView()
                            .environment(budget)
                            .environment(subscriptionController)
                            .navigationTitle("Summary")
                        //                                    .toolbar {
                        //                                        ToolbarItem(placement: .topBarLeading) {
                        //                                            Image(systemName: "figure.pickleball")
                        //                                        }
                        //                                    }
                        //                            }
                    } else {
                        PaywallView()
                    }
                }
                
                Tab("Expenses", systemImage: "creditcard", value: 2) {
                    //                        NavigationStack {
                    ExpenseTrackerView(tabSelection: $tabSelection)
                        .environment(budget)
                    //                                .toolbar {
                    //                                    ToolbarItem(placement: .topBarLeading) {
                    //                                        Image(systemName: "gear")
                    //                                    }
                    //                                }
                    //                        }
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
                
                //                    Tab("Dashboard", systemImage: "swift", value: 5) {
                //                        DashboardView()
                //                    }
            }
            //                .navigationTitle(tabSelection == 1 && subscriptionController.isSubscribed ? "\(Date().formatted(.dateTime.month(.wide))) overview" : "")
            //                .toolbar {
            //                    ToolbarItem(placement: .navigationBarTrailing) {
            //                        Button {
            //                            sendFeedbackEmail()
            //                        } label: {
            //                            Label("Send Feedback", systemImage: "envelope")
            //                        }
            //                    }
            //                }
            .onAppear {
                preloadDefaultCategoriesIfNeeded()
                
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
        //        }
        //        .onAppear {
        //            preloadDefaultCategoriesIfNeeded()
        //        }
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
















import SwiftUI
import SwiftData
import Foundation

// MARK: - Controller (dynamic state + models)
@Observable
class DashboardController {
    var totalBalance: Decimal = 25000.40
    var incomeTotal: Decimal = 20000
    var outcomeTotal: Decimal = 17000
    
    var earnings: [(initial: String, source: String, amount: Decimal, color: Color)] = [
        ("U", "Upwork", 3000, .orange),
        ("F", "Freepik", 3000, .pink),
        ("W", "Envato", 2000, .blue)
    ]
    
    var savings: [(title: String, amount: Decimal, progress: Double, color: Color)] = [
        ("Iphone 13 Mini", 699, 0.2, .red),
        ("Macbook Pro M1", 1499, 0.45, .pink),
        ("Car", 20000, 0.6, .yellow),
        ("House", 30500, 0.8, .blue)
    ]
    
    var transactions: [Transaction] = [
        Transaction(name: "Adobe Illustrator",
                    amount: -32.0,
                    frequency: .monthly,
                    dueDate: nil,
                    isAutoPaid: false,
                    isPaid: true,
                    notes: "Subscription fee",
                    vendor: "Adobe",
                    isActive: true)
    ]
}

// MARK: - Helpers
extension Date {
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: self)
        switch hour {
        case 5..<12: return "Good Morning!"
        case 12..<17: return "Good Afternoon!"
        default: return "Good Evening!"
        }
    }
}

// MARK: - Header
struct HeaderView: View {
    var name: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date().greeting)
                    .font(.callout.weight(.medium))
                    .foregroundColor(.secondary)
                Text(name)
                    .font(.title3.weight(.semibold))
            }
            
            Spacer()
            
            Image(systemName: "bell")
                .font(.title2)
                .foregroundColor(.primary)
                .overlay(
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 8, y: -8),
                    alignment: .topTrailing
                )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Balance Card
struct BalanceCard: View {
    var totalBalance: Decimal
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(height: 120)
            
            //            GeometryReader { geo in
            //                let w = geo.size.width
            //                Circle().fill(Color.blue).frame(width: 72).offset(x: w - 70, y: -10)
            //                Circle().fill(Color.yellow).frame(width: 60).offset(x: w - 25, y: 50)
            //                Circle().fill(Color.green).frame(width: 60).offset(x: -20, y: 70)
            //            }
            //            .clipped()
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Balance")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text("$\(String(format: "%0.2f", NSDecimalNumber(decimal: totalBalance).doubleValue))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("My Wallet")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Circle()
                        .stroke(.white, lineWidth: 1)
                        .frame(width: 34, height: 34)
                        .overlay(Image(systemName: "arrow.right").foregroundColor(.white))
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Income Outcome Row
struct IncomeOutcomeView: View {
    var income: Decimal
    var outcome: Decimal
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "arrow.down").foregroundStyle(.green)
                    Text("Income").font(.footnote.weight(.medium)).foregroundColor(.white.opacity(0.8))
                }
                Text("$\(Int(truncating: NSDecimalNumber(decimal: income)))")
                    .font(.title3.weight(.semibold)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "arrow.up").foregroundStyle(.red)
                    Text("Outcome").font(.footnote.weight(.medium)).foregroundColor(.white.opacity(0.8))
                }
                Text("$\(Int(truncating: NSDecimalNumber(decimal: outcome)))")
                    .font(.title3.weight(.semibold)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .frame(height: 70)
        .background(Color.black)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

// MARK: - Earnings Pill
struct EarningsPill: View {
    var initial: String
    var title: String
    var amount: Decimal
    var color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Circle().fill(color).frame(width: 42, height: 42).overlay(Text(initial).foregroundColor(.white).font(.headline.bold()))
            Text(title).font(.footnote.weight(.semibold))
            Text("$\(Int(truncating: NSDecimalNumber(decimal: amount)))")
                .font(.headline.bold())
        }
        .frame(width: 100, height: 100)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Savings Card
struct SavingsCard: View {
    var title: String
    var amount: Decimal
    var progress: Double
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.footnote.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            Text("$\(Int(truncating: NSDecimalNumber(decimal: amount)))")
                .font(.headline.bold())
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(color)
                .frame(height: 6)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    var transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(Color.yellow.opacity(0.2)).frame(width: 42, height: 42)
                .overlay(Image(systemName: "laptopcomputer").foregroundColor(.yellow))
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.name).font(.subheadline.weight(.semibold))
                Text(transaction.notes.isEmpty ? transaction.vendor : transaction.notes)
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(String(format: "%@%.2f", transaction.amount < 0 ? "-" : "+", abs(transaction.amount)))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(transaction.amount < 0 ? .red : .green)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal, 20)
    }
}

// MARK: - Root Dashboard
struct DashboardView: View {
    @State private var controller = DashboardController()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HeaderView(name: "C Muthu Krishnan").padding(.top, 12)
                
                BalanceCard(totalBalance: controller.totalBalance)
                
                IncomeOutcomeView(income: controller.incomeTotal, outcome: controller.outcomeTotal)
                
                // Earnings
                SectionHeader2(title: "Earnings")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(controller.earnings, id: \.source) { e in
                            EarningsPill(initial: e.initial, title: e.source, amount: e.amount, color: e.color)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Savings
                SectionHeader2(title: "Savings")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(controller.savings, id: \.title) { s in
                        SavingsCard(title: s.title, amount: s.amount, progress: s.progress, color: s.color)
                    }
                }
                .padding(.horizontal, 20)
                
                // Transactions
                SectionHeader2(title: "Transactions")
                ForEach(controller.transactions) { t in
                    TransactionRow(transaction: t)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGray6).ignoresSafeArea())
    }
}

// MARK: - Section Header
struct SectionHeader2: View {
    var title: String
    var body: some View {
        HStack {
            Text(title).font(.headline.weight(.semibold))
            Spacer()
            Text("See All").font(.footnote.weight(.semibold)).foregroundColor(.blue)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}

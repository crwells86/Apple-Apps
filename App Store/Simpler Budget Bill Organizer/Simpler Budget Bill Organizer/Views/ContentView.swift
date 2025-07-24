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
//                                .onAppear {
//                                    //
//                                    budget.checkCategorySpending(categories)
//                                }
                            
//                                .onChange(of: categories.map { $0.limit }) {
//                                    // ?
//                                    budget.checkCategorySpending(categories)
//                                }
                        } else {
                            PaywallView()
                        }
                    }
                    
                    Tab("Expenses", systemImage: "creditcard", value: 2) {
                        ExpenseTrackerView(tabSelection: $tabSelection)
                            .environment(budget)
//                            .onAppear {
//                                budget.checkCategorySpending(categories)
//                            }
                    }
                    
                    Tab("Bills", systemImage: "calendar.badge.clock", value: 3) {
                        BillsListView(
                            isAddTransactionsShowing: $isAddTransactionsShowing,
                            draftBill: $draftBill,
                            tabSelection: $tabSelection
                        )
                        .environment(budget)
//                        .onAppear {
//                            budget.checkCategorySpending(categories)
//                        }
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
//                .onChange(of: categories.map { $0.limit }) {
//                    // ?
//                    budget.checkCategorySpending(categories)
//                }
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








struct CategorySpending: Identifiable {
    var id: UUID
    var name: String
    var icon: String
    var total: Decimal
    
    static func == (lhs: CategorySpending, rhs: CategorySpending) -> Bool {
        lhs.id == rhs.id
    }
}


extension Category {
    var totalSpending: Decimal {
        let expensesTotal = expenses
            .filter(\.isActive)
            .reduce(Decimal(0)) { $0 + $1.amount }
        
        let transactionsTotal = transactions
            .filter(\.isActive)
            .reduce(Decimal(0)) { $0 + Decimal($1.amount) }

        return expensesTotal + transactionsTotal
    }
}


func spendingByCategory(from categories: [Category]) -> [CategorySpending] {
    categories
        .filter { $0.totalSpending > 0 }
        .map {
            CategorySpending(
                id: $0.id,
                name: $0.name,
                icon: $0.icon,
                total: $0.totalSpending
            )
        }
}


import Charts
import SwiftUI

struct DoughnutChartView: View {
    let data: [CategorySpending]
    
//    @Environment(BudgetController.self) private var budget: BudgetController
    @Query(sort: \Category.name) private var allCategories: [Category]

    @State private var selectedCategory: CategorySpending?
    @State private var isCategoryDetailsPresented = false

    var body: some View {
        ZStack {
            VStack {
                Text(selectedCategory?.name ?? "Total")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text(formattedAmount)
                    .font(.title3)
                    .bold()
            }

            Chart(data) { item in
                let isSelected = selectedCategory?.id == item.id
                let outerRadiusRatio = isSelected ? 1.15 : 1.0
                let opacityValue = (selectedCategory == nil || isSelected) ? 1.0 : 0.5

                SectorMark(
                    angle: .value("Spending", item.total),
                    innerRadius: .ratio(0.6),
                    outerRadius: .ratio(outerRadiusRatio),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("Category", item.name))
                .opacity(opacityValue)
            }
            .chartLegend(position: .bottom, spacing: 8)
        }
        .frame(height: 300)
        .onTapGesture {
            isCategoryDetailsPresented.toggle()
        }
        .sheet(isPresented: $isCategoryDetailsPresented) {
//            if let selected = selectedCategory,
//                   let fullCategory = allCategories.first(where: { $0.id == selected.id }) {
                        CategoryDetailView(fullCategory: allCategories)
//                }
        }
    }

    // MARK: - Helpers

    private var formattedAmount: String {
        let amount = selectedCategory?.total ?? data.reduce(Decimal(0)) { $0 + $1.total }
        return formatCurrency(amount)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }

    private func angleFrom(center: CGPoint, to point: CGPoint) -> Angle {
        let dx = point.x - center.x
        let dy = center.y - point.y // Flip Y-axis
        var radians = atan2(dy, dx)
        if radians < 0 { radians += 2 * .pi }
        return Angle(radians: radians)
    }

    private func distanceFrom(center: CGPoint, to point: CGPoint) -> CGFloat {
        hypot(point.x - center.x, point.y - center.y)
    }

    private func categoryAt(angle: Angle) -> CategorySpending? {
        let total = data.reduce(Decimal(0)) { $0 + $1.total }
        var cumulative = Decimal(0)

        for item in data {
            let startAngle = cumulative / total * Decimal(360)
            cumulative += item.total
            let endAngle = cumulative / total * Decimal(360)

            if angle.degrees >= Double(truncating: startAngle as NSNumber) &&
                angle.degrees < Double(truncating: endAngle as NSNumber) {
                return item
            }
        }
        return nil
    }
}




import SwiftUI


struct CategoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let fullCategory: [Category]
    
    var body: some View {
        VStack {
            HStack {
                Text("Spending by Category")
                    .font(.title)
                    .fontWeight(.heavy)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding([.horizontal, .top])
            
            List {
                ForEach(filteredCategories) { category in
                    BudgetRowView(category: category)
                }
            }
        }
    }
    
    private var filteredCategories: [Category] {
        fullCategory.filter { $0.limit != nil }
    }
}

struct BudgetRowView: View {
    let category: Category

    var body: some View {
        let limit = category.limit ?? 0
        let spent = category.totalSpending
        let remaining = limit - spent
        let isUnder = remaining >= 0

        let percentage = min((spent as NSDecimalNumber).doubleValue / (limit as NSDecimalNumber).doubleValue, 1.0)
        let color: Color = {
            if !isUnder { return .red }
            else if percentage > 0.8 { return .yellow }
            else { return .green }
        }()

        HStack(spacing: 16) {
            iconView(for: category.icon)

            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)

                Text("Spent: \(formatCurrency(spent)) of \(formatCurrency(limit))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView(value: percentage)
                    .tint(color)
            }

            Spacer()

            Text(isUnder ? "✓" : "⚠️")
                .font(.title3)
                .foregroundStyle(color)
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
    
    @ViewBuilder
    private func iconView(for icon: String) -> some View {
        if UIImage(systemName: icon) != nil {
            Image(systemName: icon)
                .foregroundStyle(.accent)
        } else {
            Text(icon)
                .font(.title3)
        }
    }
}














import Foundation

struct BudgetStatus: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let spent: Decimal
    let limit: Decimal?

    var spentDouble: Double {
        (spent as NSDecimalNumber).doubleValue
    }

    var limitDouble: Double {
        guard let limit else { return 1.0 }
        return NSDecimalNumber(decimal: limit).doubleValue
    }


    var percentUsed: Double {
//        guard let limit else { return 1.0 }
        return min(spentDouble / limitDouble, 1.0)
    }

    var isOver: Bool {
        guard let limit else { return false }
        return spent > limit
    }

    var isNearLimit: Bool {
//        guard let limit else { return false }
        let percent = spentDouble / limitDouble
        return percent >= 0.9 && !isOver
    }

    var difference: Decimal {
        guard let limit else { return 0 }
        return isOver ? spent - limit : limit - spent
    }

    var color: Color {
        if isOver { return .red }
        if isNearLimit { return .orange }
        return .green
    }

    var statusText: String {
        let value = difference
        return "\(value.formatted(.currency(code: "USD"))) \(isOver ? "over" : "left")"
    }
}


import SwiftUI

struct CategoryBudgetCircleView: View {
    let status: BudgetStatus

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: CGFloat(status.percentUsed))
                    .stroke(status.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.4), value: status.percentUsed)

                Text(status.emoji)
                    .font(.system(size: 28))
            }
            .frame(width: 60, height: 60)

            Text(status.statusText)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(width: 70)
        .padding()
    }
}


struct BudgetCategoryListView: View {
    let statuses: [BudgetStatus]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("BUDGETS")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("Categories ›")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(statuses) { status in
                        CategoryBudgetCircleView(status: status)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}


func calculateBudgetStatuses(categories: [Category]) -> [BudgetStatus] {
    categories
        .filter { $0.limit != nil }
        .map { category in
            let totalSpent = category.expenses.reduce(Decimal(0)) { $0 + $1.amount }

            return BudgetStatus(
                emoji: category.icon,
                name: category.name,
                spent: totalSpent,
                limit: category.limit
            )
        }
}

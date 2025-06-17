import SwiftUI
import StoreKit
import SwiftData

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("sessionCount") private var sessionCount = 0
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    
    @State private var controller = FinanceController()
    @State private var isAddTransactionsShowing = false
    @State private var draftBill = Transaction()
    @State private var tabSelection = 2
    
    @Environment(\.modelContext) private var context
    @Query private var bills: [Transaction]
    
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground // or any custom color

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    var body: some View {
        NavigationStack {
            if hasSeenOnboarding {
                TabView(selection: $tabSelection) {
                    //                    Tab("Summary", systemImage: "dollarsign.gauge.chart.leftthird.topthird.rightthird", value: 1) {
                    //                        //
                    //                    }
                    
                    Tab("Expenses", systemImage: "creditcard", value: 2) {
//                        let annually = controller.neededAnnual(from: bills)
//                        ExpenseTrackerView(controller: controller, totalBudget: annually)
                        ExpenseTrackerView(tabSelection: $tabSelection)
                    }
                    
                    Tab("Bills", systemImage: "calendar.badge.clock", value: 3) {
                        BillsListView(controller: controller, isAddTransactionsShowing: $isAddTransactionsShowing, draftBill: $draftBill, tabSelection: $tabSelection)
                    }
                    
                    //                    Tab("Settings", systemImage: "gear", value: 4) {
                    //                        //
                    //                    }
                }
                .onAppear {
                    sessionCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        maybeRequestReview()
                    }
                }
                .whatsNewSheet()
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            }
        }
    }
    
    private func maybeRequestReview() {
        guard sessionCount >= 14, !hasRequestedReview else { return }
        
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: scene)
            hasRequestedReview.toggle()
        }
    }
}

#Preview {
    ContentView()
}

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    @State private var controller = FinanceController()
    @State private var isAddTransactionsShowing = false
    @State private var draftBill = Transaction()
    
    @Environment(\.modelContext) private var context
    @Query private var bills: [Transaction]
    
    var body: some View {
        NavigationStack {
            if hasSeenOnboarding {
                BillsListView(controller: controller, isAddTransactionsShowing: $isAddTransactionsShowing, draftBill: $draftBill)
                
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            }
        }
    }
}

#Preview {
    ContentView()
}

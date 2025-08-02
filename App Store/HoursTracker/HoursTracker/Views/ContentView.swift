import SwiftUI

struct ContentView: View {
    @Environment(SubscriptionController.self) var subscriptionController
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        if hasCompletedOnboarding {
            TabView {
                NavigationStack {
                    TimeLogView()
                }
                .tabItem {
                    Label("Log", systemImage: "calendar.badge.clock")
                }
                
                NavigationStack {
                    JobListView()
                }
                .tabItem {
                    Label("History", systemImage: "chart.bar.doc.horizontal")
                }
                
                NavigationStack {
                    EarningsView()
                }
                .tabItem {
                    Label("Earnings", systemImage: "dollarsign.ring.dashed")
                }
            }
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
}

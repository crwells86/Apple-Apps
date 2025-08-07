import SwiftUI

struct ContentView: View {
    @Environment(SubscriptionController.self) var subscriptionController
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        if hasCompletedOnboarding {
            TabView {
                NavigationStack {
                    TimeLogView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    sendFeedbackEmail()
                                } label: {
                                    Label("Send Feedback", systemImage: "envelope")
                                }
                            }
                        }
                }
                .tabItem {
                    Label("Log", systemImage: "calendar.badge.clock")
                }
                
                NavigationStack {
                    JobListView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    sendFeedbackEmail()
                                } label: {
                                    Label("Send Feedback", systemImage: "envelope")
                                }
                            }
                        }
                }
                .tabItem {
                    Label("History", systemImage: "chart.bar.doc.horizontal")
                }
                
                NavigationStack {
                    EarningsView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    sendFeedbackEmail()
                                } label: {
                                    Label("Send Feedback", systemImage: "envelope")
                                }
                            }
                        }
                }
                .tabItem {
                    Label("Earnings", systemImage: "dollarsign.ring.dashed")
                }
            }
        } else {
            OnboardingView()
        }
    }
    
    
    func sendFeedbackEmail() {
        let subject = "App Feedback – Hours Tracker"
        let body = "Share some feedback..."
        let email = "calebrwells@gmail.com"
        
        let emailURL = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        
        if let url = emailURL {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ContentView()
}

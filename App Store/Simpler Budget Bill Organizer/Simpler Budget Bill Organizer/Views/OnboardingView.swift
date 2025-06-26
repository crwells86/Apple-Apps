import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    
    var body: some View {
        VStack {
            TabView {
                // 1: Auto‐budget from bills
                OnboardingPage(
                    image: "list.bullet.rectangle.portrait",
                    title: "Auto-Budget in Seconds",
                    description: "Enter your recurring bills once and watch as we calculate exactly what you need to earn—hourly, daily, weekly, monthly, or yearly."
                )
                
                // 2: Track spending live
                OnboardingPage(
                    image: "chart.bar.doc.horizontal",
                    title: "Live Expense Tracking",
                    description: "Log your expenses on the go and see in real time how much you’ve spent vs. how much you have left for your chosen period."
                )
                
                // 3: Set reminders & alerts
                OnboardingPage(
                    image: "bell.and.waves.left.and.right",
                    title: "Never Miss a Payment",
                    description: "Schedule reminders for due dates and get notified so late fees become a thing of the past."
                )
                
                // 4: Privacy-first, no ads
                OnboardingPage(
                    image: "hand.raised.slash",
                    title: "Private & Ad-Free",
                    description: "All your data stays on your device. No bank links, no ads—just you in control of your budget."
                )
            }
            .tabViewStyle(.page)
            
            Button(action: {
                hasSeenOnboarding = true
            }) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.accentColor)
            UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.accentColor.opacity(0.3))
        }
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}

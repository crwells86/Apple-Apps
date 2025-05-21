import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    
    var body: some View {
        TabView {
            OnboardingPage(image: "chart.line.uptrend.xyaxis", title: "Know What You Need", description: "Add your bills once and instantly see how much you need to earn annually, monthly, weekly, or hourly.")
            
            OnboardingPage(image: "bell.badge", title: "Never Miss a Due Date", description: "Set reminders to stay on top of your expenses. Peace of mind, built-in.")
            
            OnboardingPage(image: "lock.shield", title: "Private. Personal. Precise.", description: "No bank links. No ads. Just your bills and total control.")
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("Ready to Budget Smarter?")
                    .font(.title)
                    .bold()
                
                Button {
                    hasSeenOnboarding.toggle()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .tabViewStyle(.page)
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.green)
            UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.green.opacity(0.3))
        }
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(true))
}

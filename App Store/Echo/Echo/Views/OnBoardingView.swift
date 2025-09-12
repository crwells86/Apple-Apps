import SwiftUI

struct OnBoardingView: View {
    @Binding var isPaywallShowing: Bool
    
    var body: some View {
        DrawOnSymbolView(data: [
            .init(name: "waveform",
                  title: "Real-Time Transcription",
                  subtitle: "Turn conversations, meetings, and lectures into clear, actionable notes.",
                  preDelay: 0.72),
            
                .init(name: "list.bullet.clipboard",
                      title: "Instant Summaries",
                      subtitle: "Get concise takeaways, and task lists automatically."),
            
            .init(name: "questionmark.bubble",
                      title: "AI Chat Assistant",
                      subtitle: "Ask follow-up questions, draft emails, or get tailored insights from your notes."),
            
                .init(name: "lock.shield",
                      title: "100% Private",
                      subtitle: "Works entirely on-device. No accounts. No servers. No Internet needed. Nothing leaves your phone.")
        ], showPaywall: $isPaywallShowing)
    }
}

#Preview {
    OnBoardingView(isPaywallShowing: .constant(true))
}

struct DrawOnSymbolView: View {
    @State private var currentIndex = 0
    @State var data: [SymbolData]
    @Binding var showPaywall: Bool
    var tint: Color = .blue
    
    var body: some View {
        VStack {
            VStack {
                Spacer()
                
                ZStack {
                    ForEach(data) { symbolData in
                        if symbolData.drawOn {
                            Image(systemName: symbolData.name)
                                .font(.system(size: symbolData.symbolSize, weight: .regular))
                                .transition(.symbolEffect(.drawOn.individually))
                        }
                    }
                }
                .frame(width: 120, height: 120)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(tint.gradient)
                }
            }
            
            VStack {
                Text(data[currentIndex].title)
                    .font(.title)
                    .bold()
                    .padding(.top, 16)
                
                Text(data[currentIndex].subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                
                Spacer()
                
                Button {
                    showNext()
                } label: {
                    Text(currentIndex < data.count - 1 ? "Next" : "Get Started")
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .glassEffect()
                .padding()
            }
            .contentTransition(.numericText())
            .animation(.snappy(duration: 1, extraBounce: 0.27), value: currentIndex)
            .padding()
        }
        .onAppear {
            // Start first animation automatically
            withAnimation(.snappy(duration: 1, extraBounce: 0.27)) {
                data[0].drawOn = true
            }
        }
    }
    
    func showNext() {
        // Turn off current symbol
        withAnimation(.snappy(duration: 1, extraBounce: 0.27)) {
            data[currentIndex].drawOn = false
        }
        
        // Advance to next after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if currentIndex < data.count - 1 {
                currentIndex += 1
                // Immediately start drawing the new one
                withAnimation(.snappy(duration: 1, extraBounce: 0.27)) {
                    data[currentIndex].drawOn = true
                }
            } else {
                // End of onboarding → show paywall
                showPaywall = true
                UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
            }
        }
    }
    
    struct SymbolData: Identifiable {
        var id = UUID()
        var name: String
        var title: String
        var subtitle: String
        var symbolSize: CGFloat = 72
        var preDelay: CGFloat = 1
        var postDelay: CGFloat = 2
        fileprivate var drawOn = false
    }
}

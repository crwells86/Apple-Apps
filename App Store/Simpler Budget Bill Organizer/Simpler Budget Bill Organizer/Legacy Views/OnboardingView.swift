//import SwiftUI
//
//struct OnboardingView: View {
//    @Binding var hasSeenOnboarding: Bool
//    
//    var body: some View {
//        VStack {
//            TabView {
//                OnboardingPage(
//                    image: "list.bullet.rectangle.portrait",
//                    title: "Auto-Budget in Seconds",
//                    description: "Enter your recurring bills once and watch as we calculate exactly what you need to earn—hourly, daily, weekly, monthly, or yearly."
//                )
//                
//                OnboardingPage(
//                    image: "chart.bar.doc.horizontal",
//                    title: "Live Expense Tracking",
//                    description: "Log your expenses on the go and see in real time how much you’ve spent vs. how much you have left for your chosen period."
//                )
//                
//                OnboardingPage(
//                    image: "bell.and.waves.left.and.right",
//                    title: "Never Miss a Payment",
//                    description: "Schedule reminders for due dates and get notified so late fees become a thing of the past."
//                )
//                
//                OnboardingPage(
//                    image: "hand.raised.slash",
//                    title: "Private & Ad-Free",
//                    description: "All your data stays on your device. No bank links, no ads—just you in control of your budget."
//                )
//            }
//            .tabViewStyle(.page)
//            
//            Button(action: {
//                hasSeenOnboarding = true
//            }) {
//                Text("Get Started")
//                    .font(.headline)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.accentColor)
//                    .foregroundColor(.white)
//                    .cornerRadius(12)
//            }
//            .padding(.horizontal)
//        }
//        .onAppear {
//            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.accentColor)
//            UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.accentColor.opacity(0.3))
//        }
//    }
//}
//
//#Preview {
//    OnboardingView(hasSeenOnboarding: .constant(false))
//}


import SwiftUI

private struct OnboardingPageData: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
    let accentColor: Color
    let index: Int
}

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    @State private var currentPage = 0
    @State private var appeared = false
    @State private var buttonPressed = false

    private let pages: [OnboardingPageData] = [
        OnboardingPageData(
            image: "list.bullet.rectangle.portrait.fill",
            title: "Auto-Budget\nin Seconds",
            description: "Enter your recurring bills once and watch as we calculate exactly what you need to earn — hourly, daily, weekly, or monthly.",
            accentColor: .green,
            index: 0
        ),
        OnboardingPageData(
            image: "chart.bar.doc.horizontal.fill",
            title: "Live Expense\nTracking",
            description: "Log expenses on the go and see in real time how much you've spent vs. how much you have left.",
            accentColor: Color(red: 0.2, green: 0.85, blue: 0.6),
            index: 1
        ),
        OnboardingPageData(
            image: "bell.and.waves.left.and.right.fill",
            title: "Never Miss\na Payment",
            description: "Schedule reminders for due dates and get notified before they're due. Late fees are a thing of the past.",
            accentColor: Color(red: 0.3, green: 0.9, blue: 0.5),
            index: 2
        ),
        OnboardingPageData(
            image: "hand.raised.slash.fill",
            title: "Private\n& Ad-Free",
            description: "All your data stays on your device. No bank links, no ads, no tracking — just you and your budget.",
            accentColor: .green,
            index: 3
        )
    ]

    private var isLastPage: Bool { currentPage == pages.count - 1 }
    private var currentAccent: Color { pages[currentPage].accentColor }

    var body: some View {
        ZStack {
            // MARK: - Background
            backgroundLayer

            VStack(spacing: 0) {

                // MARK: - Top Safe Area Logo
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(currentAccent)
                    Text("Bill Organizer")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 12)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: appeared)

                // MARK: - Tab View
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPage(
                            image: page.image,
                            title: page.title,
                            description: page.description,
                            accentColor: page.accentColor,
                            index: page.index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                // MARK: - Bottom Controls
                VStack(spacing: 28) {
                    // Custom page indicator
                    customPageIndicator

                    // CTA Button
                    Button {
                        if isLastPage {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                hasSeenOnboarding = true
                            }
                        } else {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [currentAccent, currentAccent.opacity(0.75)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: currentAccent.opacity(0.45), radius: 16, y: 6)

                            HStack(spacing: 10) {
                                Text(isLastPage ? "Get Started" : "Continue")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.black.opacity(0.85))
                                Image(systemName: isLastPage ? "sparkles" : "arrow.right")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.black.opacity(0.7))
                            }
                        }
                        .frame(height: 58)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 28)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)

                    // Skip / Legal
                    if !isLastPage {
                        Button("Skip for now") {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                hasSeenOnboarding = true
                            }
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                    } else {
                        Text("Free to try • One-time purchase to unlock all features")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(.quaternary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.3), value: appeared)
            }
        }
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.green)
            UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.green.opacity(0.3))
            withAnimation { appeared = true }
        }
    }

    // MARK: - Background
    private var backgroundLayer: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            // Soft mesh gradient
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(currentAccent.opacity(0.12))
                        .frame(width: geo.size.width * 1.2)
                        .offset(x: -geo.size.width * 0.2, y: -geo.size.height * 0.15)
                        .blur(radius: 80)

                    Circle()
                        .fill(currentAccent.opacity(0.07))
                        .frame(width: geo.size.width * 0.9)
                        .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.5)
                        .blur(radius: 60)
                }
                .animation(.easeInOut(duration: 0.7), value: currentPage)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Page Indicator
    private var customPageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? currentAccent : currentAccent.opacity(0.25))
                    .frame(width: index == currentPage ? 24 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}


#Preview {
    @Previewable @State var hasSeenOnboarding = false
    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
}

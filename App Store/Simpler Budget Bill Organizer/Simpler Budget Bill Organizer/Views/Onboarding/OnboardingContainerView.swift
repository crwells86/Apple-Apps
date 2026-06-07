//
//
//
//
//// MARK: - OnboardingFlow.swift
//// iOS 26+ | Apple Foundation Models Framework
//// Full onboarding with live AI demo interactions
//
//import SwiftUI
//import FoundationModels  // iOS 26 Apple Intelligence framework
//
//// MARK: - App Entry Point Hook
//
//struct OnboardingContainerView: View {
//    
//    @State private var pageIndex: Int = 0
//    @State private var isComplete: Bool = false
//    @Namespace private var heroNamespace
//    
//    private let pagesCount = 6
//    
//    var body: some View {
//        if isComplete {
//            // Replace with your main app view
//            Text("Main App")
//                .transition(.push(from: .trailing))
//        } else {
//            onboardingBody
//                .transition(.push(from: .trailing))
//        }
//    }
//    
//    private var onboardingBody: some View {
//        ZStack(alignment: .top) {
//            // Ambient background — shifts hue per page
//            AnimatedMeshBackground(pageIndex: pageIndex)
//                .ignoresSafeArea()
//            
//            VStack(spacing: 0) {
//                
//                // ── Pill progress bar ──
//                OnboardingProgressBar(current: pageIndex, total: pagesCount)
//                    .padding(.horizontal, 28)
//                    .padding(.top, 16)
//                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: pageIndex)
//                
//                // ── Pages ──
//                TabView(selection: $pageIndex) {
//                    WelcomePage(next: goNext)
//                        .tag(0)
//                    PrivacyPage(next: goNext)
//                        .tag(1)
//                    FeaturesPage(next: goNext)
//                        .tag(2)
//                    AIInteractivePage(next: goNext)   // ← Live AI demo
//                        .tag(3)
//                    InsightDemoPage(next: goNext)      // ← Interactive insight builder
//                        .tag(4)
//                    FinalPage(done: finish)
//                        .tag(5)
//                }
//                .tabViewStyle(.page(indexDisplayMode: .never))
//                .animation(.interactiveSpring(response: 0.55, dampingFraction: 0.82), value: pageIndex)
//            }
//        }
//        .preferredColorScheme(.dark)
//    }
//    
//    private func goNext() {
//        guard pageIndex < pagesCount - 1 else { return }
//        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
//            pageIndex += 1
//        }
//    }
//    
//    private func finish() {
//        UserDefaults.standard.set(true, forKey: "onboardingComplete")
//        withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
//            isComplete = true
//        }
//    }
//}
//
//// MARK: - Animated Mesh Background
//
//struct AnimatedMeshBackground: View {
//    let pageIndex: Int
//    
//    // Each page gets its own color signature
//    private var colors: (Color, Color, Color) {
//        switch pageIndex {
//        case 0: return (.init(red: 0.04, green: 0.04, blue: 0.12), .init(red: 0.1, green: 0.08, blue: 0.3), .init(red: 0.06, green: 0.05, blue: 0.2))
//        case 1: return (.init(red: 0.02, green: 0.06, blue: 0.15), .init(red: 0.04, green: 0.18, blue: 0.35), .init(red: 0.02, green: 0.1, blue: 0.25))
//        case 2: return (.init(red: 0.05, green: 0.03, blue: 0.15), .init(red: 0.2, green: 0.05, blue: 0.35), .init(red: 0.12, green: 0.04, blue: 0.28))
//        case 3: return (.init(red: 0.08, green: 0.03, blue: 0.18), .init(red: 0.3, green: 0.08, blue: 0.4), .init(red: 0.18, green: 0.05, blue: 0.3))
//        case 4: return (.init(red: 0.03, green: 0.08, blue: 0.18), .init(red: 0.05, green: 0.25, blue: 0.45), .init(red: 0.04, green: 0.15, blue: 0.32))
//        case 5: return (.init(red: 0.02, green: 0.1, blue: 0.08), .init(red: 0.04, green: 0.3, blue: 0.2), .init(red: 0.03, green: 0.2, blue: 0.14))
//        default: return (.black, .black, .black)
//        }
//    }
//    
//    @State private var phase: CGFloat = 0
//    
//    var body: some View {
//        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
//            MeshGradient(
//                width: 3, height: 3,
//                points: meshPoints(time: CGFloat(timeline.date.timeIntervalSinceReferenceDate)),
//                colors: [
//                    colors.0, colors.1, colors.0,
//                    colors.2, colors.1, colors.2,
//                    colors.0, colors.2, colors.1
//                ]
//            )
//        }
//        .animation(.easeInOut(duration: 1.2), value: pageIndex)
//    }
//    
//    private func meshPoints(time: CGFloat) -> [SIMD2<Float>] {
//        let s = Float(sin(time * 0.4) * 0.06)
//        let c = Float(cos(time * 0.3) * 0.06)
//        return [
//            [0, 0], [0.5 + s, 0], [1, 0],
//            [0, 0.5 + c], [0.5 - s, 0.5 + s], [1, 0.5 - c],
//            [0, 1], [0.5 + c, 1], [1, 1]
//        ]
//    }
//}
//
//// MARK: - Progress Bar
//
//struct OnboardingProgressBar: View {
//    let current: Int
//    let total: Int
//    
//    var body: some View {
//        GeometryReader { geo in
//            ZStack(alignment: .leading) {
//                Capsule()
//                    .fill(.white.opacity(0.12))
//                    .frame(height: 4)
//                
//                Capsule()
//                    .fill(
//                        LinearGradient(
//                            colors: [.white.opacity(0.9), .white.opacity(0.5)],
//                            startPoint: .leading,
//                            endPoint: .trailing
//                        )
//                    )
//                    .frame(width: geo.size.width * CGFloat(current + 1) / CGFloat(total), height: 4)
//            }
//        }
//        .frame(height: 4)
//    }
//}
//
//// MARK: - Shared Page Shell
//
//struct PageShell<Content: View>: View {
//    let content: Content
//    
//    init(@ViewBuilder content: () -> Content) {
//        self.content = content()
//    }
//    
//    var body: some View {
//        ScrollView(.vertical, showsIndicators: false) {
//            content
//                .frame(maxWidth: .infinity)
//                .padding(.horizontal, 28)
//                .padding(.top, 32)
//                .padding(.bottom, 48)
//        }
//    }
//}
//
//// MARK: - Primary Button Style
//
//struct PrimaryButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .font(.system(size: 17, weight: .semibold, design: .rounded))
//            .foregroundStyle(.black)
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 17)
//            .background(
//                Capsule()
//                    .fill(.white)
//                    .shadow(color: .white.opacity(0.25), radius: 20, y: 6)
//            )
//            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
//            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
//    }
//}
//
//// MARK: - Page 1: Welcome
//
//struct WelcomePage: View {
//    let next: () -> Void
//    @State private var appeared = false
//    
//    var body: some View {
//        PageShell {
//            VStack(spacing: 0) {
//                Spacer(minLength: 60)
//                
//                // Wordmark logo lockup
//                ZStack {
//                    Circle()
//                        .fill(
//                            RadialGradient(
//                                colors: [.white.opacity(0.15), .clear],
//                                center: .center,
//                                startRadius: 20,
//                                endRadius: 80
//                            )
//                        )
//                        .frame(width: 160, height: 160)
//                        .blur(radius: 20)
//                    
//                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
//                        .font(.system(size: 72))
//                        .foregroundStyle(
//                            LinearGradient(
//                                colors: [.white, .white.opacity(0.7)],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                        .symbolEffect(.variableColor.iterative.dimInactiveLayers, options: .repeating)
//                }
//                .scaleEffect(appeared ? 1 : 0.5)
//                .opacity(appeared ? 1 : 0)
//                
//                Spacer(minLength: 40)
//                
//                VStack(spacing: 16) {
//                    Text("Your money.\nUnder your control.")
//                        .font(.system(size: 38, weight: .bold, design: .rounded))
//                        .multilineTextAlignment(.center)
//                        .foregroundStyle(.white)
//                        .opacity(appeared ? 1 : 0)
//                        .offset(y: appeared ? 0 : 20)
//                    
//                    Text("Track spending, income, bills, and savings\n— privately on your device.")
//                        .font(.system(size: 17, weight: .regular, design: .rounded))
//                        .multilineTextAlignment(.center)
//                        .foregroundStyle(.white.opacity(0.55))
//                        .opacity(appeared ? 1 : 0)
//                        .offset(y: appeared ? 0 : 15)
//                }
//                
//                Spacer(minLength: 60)
//                
//                Button("Get Started", action: next)
//                    .buttonStyle(PrimaryButtonStyle())
//                    .opacity(appeared ? 1 : 0)
//                    .offset(y: appeared ? 0 : 10)
//                
//                Text("No account required · No data leaves your device")
//                    .font(.system(size: 12, weight: .regular, design: .rounded))
//                    .foregroundStyle(.white.opacity(0.3))
//                    .multilineTextAlignment(.center)
//                    .padding(.top, 14)
//                    .opacity(appeared ? 1 : 0)
//            }
//        }
//        .onAppear {
//            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.15)) {
//                appeared = true
//            }
//        }
//    }
//}
//
//// MARK: - Page 2: Privacy
//
//struct PrivacyPage: View {
//    let next: () -> Void
//    @State private var appeared = false
//    @State private var shieldPulsing = false
//    
//    private let pillars: [(String, String)] = [
//        ("No accounts required", "person.slash.fill"),
////        ("No cloud sync ever", "icloud.slash.fill"),
//        ("Data never leaves device", "lock.iphone"),
//        ("On-device AI processing", "brain.filled.head.profile")
//    ]
//    
//    var body: some View {
//        PageShell {
//            VStack(spacing: 32) {
//                
//                // Shield hero
//                ZStack {
//                    ForEach(0..<3) { i in
//                        Circle()
//                            .stroke(.blue.opacity(0.15 - Double(i) * 0.04), lineWidth: 1)
//                            .frame(width: CGFloat(120 + i * 44), height: CGFloat(120 + i * 44))
//                            .scaleEffect(shieldPulsing ? 1.08 : 1.0)
//                            .animation(
//                                .easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(Double(i) * 0.3),
//                                value: shieldPulsing
//                            )
//                    }
//                    Image(systemName: "lock.shield.fill")
//                        .font(.system(size: 64))
//                        .foregroundStyle(
//                            LinearGradient(
//                                colors: [.cyan, .blue],
//                                startPoint: .top,
//                                endPoint: .bottom
//                            )
//                        )
//                        .symbolEffect(.bounce, options: .speed(0.5))
//                }
//                .frame(height: 170)
//                .opacity(appeared ? 1 : 0)
//                .scaleEffect(appeared ? 1 : 0.6)
//                
//                VStack(spacing: 10) {
//                    Text("100% Private")
//                        .font(.system(size: 32, weight: .bold, design: .rounded))
//                        .foregroundStyle(.white)
//                    
//                    Text("Built on a foundation of trust.\nYour financial data is yours alone.")
//                        .font(.system(size: 16, weight: .regular, design: .rounded))
//                        .foregroundStyle(.white.opacity(0.5))
//                        .multilineTextAlignment(.center)
//                }
//                .opacity(appeared ? 1 : 0)
//                
//                // Privacy pillars
//                VStack(spacing: 12) {
//                    ForEach(Array(pillars.enumerated()), id: \.offset) { i, pillar in
//                        PrivacyPillarRow(icon: pillar.1, text: pillar.0)
//                            .opacity(appeared ? 1 : 0)
//                            .offset(x: appeared ? 0 : -30)
//                            .animation(
//                                .spring(response: 0.6, dampingFraction: 0.8).delay(0.1 + Double(i) * 0.08),
//                                value: appeared
//                            )
//                    }
//                }
//                
//                Spacer(minLength: 8)
//                
//                Button("I Understand", action: next)
//                    .buttonStyle(PrimaryButtonStyle())
//                    .opacity(appeared ? 1 : 0)
//            }
//        }
//        .onAppear {
//            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
//                appeared = true
//            }
//            shieldPulsing = true
//        }
//    }
//}
//
//struct PrivacyPillarRow: View {
//    let icon: String
//    let text: String
//    
//    var body: some View {
//        HStack(spacing: 14) {
//            ZStack {
//                RoundedRectangle(cornerRadius: 10, style: .continuous)
//                    .fill(.white.opacity(0.08))
//                    .frame(width: 40, height: 40)
//                Image(systemName: icon)
//                    .font(.system(size: 17, weight: .medium))
//                    .foregroundStyle(.cyan)
//            }
//            
//            Text(text)
//                .font(.system(size: 16, weight: .medium, design: .rounded))
//                .foregroundStyle(.white.opacity(0.85))
//            
//            Spacer()
//            
//            Image(systemName: "checkmark")
//                .font(.system(size: 13, weight: .bold))
//                .foregroundStyle(.green.opacity(0.8))
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 12)
//        .background(
//            RoundedRectangle(cornerRadius: 14, style: .continuous)
//                .fill(.white.opacity(0.05))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 14, style: .continuous)
//                        .stroke(.white.opacity(0.07), lineWidth: 1)
//                )
//        )
//    }
//}
//
//// MARK: - Page 3: Features
//
//struct FeaturesPage: View {
//    let next: () -> Void
//    @State private var appeared = false
//    @State private var selectedFeature: Int? = nil
//    
//    private let features: [(String, String, String, String)] = [
//        ("Track Everything", "Log income, expenses, and transfers in seconds.", "list.bullet.rectangle.fill", "blue"),
//        ("Bill Reminders", "Never miss a due date with smart recurring bill tracking.", "calendar.badge.clock", "purple"),
//        ("Savings Goals", "Set targets and watch your progress grow.", "target", "green"),
//        ("Trend Analysis", "See exactly where your money goes over time.", "chart.line.uptrend.xyaxis", "orange")
//    ]
//    
//    var body: some View {
//        PageShell {
//            VStack(spacing: 28) {
//                
//                VStack(spacing: 10) {
//                    Text("Everything in\none place.")
//                        .font(.system(size: 36, weight: .bold, design: .rounded))
//                        .foregroundStyle(.white)
//                        .multilineTextAlignment(.center)
//                }
//                .opacity(appeared ? 1 : 0)
//                
//                // Feature cards grid
//                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
//                    ForEach(Array(features.enumerated()), id: \.offset) { i, feature in
//                        FeatureCard(
//                            title: feature.0,
//                            subtitle: feature.1,
//                            icon: feature.2,
//                            colorName: feature.3,
//                            isSelected: selectedFeature == i
//                        )
//                        .opacity(appeared ? 1 : 0)
//                        .scaleEffect(appeared ? 1 : 0.85)
//                        .animation(
//                            .spring(response: 0.55, dampingFraction: 0.75).delay(Double(i) * 0.07),
//                            value: appeared
//                        )
//                        .onTapGesture {
//                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//                                selectedFeature = selectedFeature == i ? nil : i
//                            }
//                        }
//                    }
//                }
//                
//                Button("Continue", action: next)
//                    .buttonStyle(PrimaryButtonStyle())
//                    .opacity(appeared ? 1 : 0)
//            }
//        }
//        .onAppear {
//            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
//                appeared = true
//            }
//        }
//    }
//}
//
//struct FeatureCard: View {
//    let title: String
//    let subtitle: String
//    let icon: String
//    let colorName: String
//    let isSelected: Bool
//    
//    private var accentColor: Color {
//        switch colorName {
//        case "blue": return .blue
//        case "purple": return .purple
//        case "green": return .green
//        case "orange": return .orange
//        default: return .blue
//        }
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            ZStack {
//                RoundedRectangle(cornerRadius: 10, style: .continuous)
//                    .fill(accentColor.opacity(0.18))
//                    .frame(width: 44, height: 44)
//                Image(systemName: icon)
//                    .font(.system(size: 20, weight: .medium))
//                    .foregroundStyle(accentColor)
//            }
//            
//            Text(title)
//                .font(.system(size: 15, weight: .bold, design: .rounded))
//                .foregroundStyle(.white)
//            
//            if isSelected {
//                Text(subtitle)
//                    .font(.system(size: 12, weight: .regular, design: .rounded))
//                    .foregroundStyle(.white.opacity(0.6))
//                    .transition(.opacity.combined(with: .move(edge: .top)))
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(16)
//        .background(
//            RoundedRectangle(cornerRadius: 18, style: .continuous)
//                .fill(
//                    isSelected
//                    ? accentColor.opacity(0.12)
//                    : Color.white.opacity(0.06)
//                )
//                .overlay(
//                    RoundedRectangle(cornerRadius: 18, style: .continuous)
//                        .stroke(
//                            isSelected ? accentColor.opacity(0.5) : Color.white.opacity(0.08),
//                            lineWidth: 1
//                        )
//                )
//        )
//        .scaleEffect(isSelected ? 1.03 : 1.0)
//        .shadow(color: isSelected ? accentColor.opacity(0.3) : .clear, radius: 12, y: 4)
//    }
//}
//
//// MARK: - Page 4: AI Interactive Demo (Foundation Models)
//
///// This page lets the user ask a real question against a synthetic dataset
///// using Apple's LanguageModelSession — entirely on-device.
//struct AIInteractivePage: View {
//    let next: () -> Void
//    
//    @State private var appeared = false
//    @State private var userInput: String = ""
//    @State private var response: String = ""
//    @State private var isLoading: Bool = false
//    @State private var hasResponded: Bool = false
//    @FocusState private var inputFocused: Bool
//    
//    // Foundation Models session
//    @State private var session: LanguageModelSession?
//    
//    private let suggestedQuestions = [
//        "How much did I spend on food this week?",
//        "Am I on track with savings?",
//        "What's my biggest expense category?",
//        "How do my bills compare to last month?"
//    ]
//    
//    // Synthetic demo data injected as context
//    private let demoContext = """
//    User's financial snapshot (demo data for onboarding):
//    - This week's spending: Groceries $94, Dining out $67, Transport $38, Entertainment $22
//    - Monthly income: $5,200
//    - Savings goal: $800/month, currently saved $410 this month (51% of goal)
//    - Top expense category this month: Food & Dining at $312 total
//    - Bills this month: Rent $1,400, Utilities $110, Subscriptions $45
//    - Last month's bills total: $1,490
//    - Last month food spending: $280
//    - Current month food spending: $312 (increase of $32)
//    Answer questions naturally, helpfully, and concisely as a private financial assistant.
//    Be warm, specific, and actionable. Keep responses to 2–3 sentences max.
//    """
//    
//    var body: some View {
//        PageShell {
//            VStack(spacing: 24) {
//                
//                // Header
//                VStack(spacing: 10) {
//                    ZStack {
//                        Circle()
//                            .fill(
//                                RadialGradient(
//                                    colors: [.purple.opacity(0.3), .clear],
//                                    center: .center, startRadius: 10, endRadius: 60
//                                )
//                            )
//                            .frame(width: 120, height: 120)
//                            .blur(radius: 15)
//                        
//                        Image(systemName: "brain.filled.head.profile")
//                            .font(.system(size: 56))
//                            .foregroundStyle(
//                                LinearGradient(
//                                    colors: [.purple, .blue],
//                                    startPoint: .top, endPoint: .bottom
//                                )
//                            )
//                            .symbolEffect(.variableColor.iterative, options: .repeating)
//                    }
//                    
//                    Text("Ask Your\nFinancial Assistant")
//                        .font(.system(size: 30, weight: .bold, design: .rounded))
//                        .foregroundStyle(.white)
//                        .multilineTextAlignment(.center)
//                    
//                    Text("Try it now — powered by Apple Intelligence,\nprocessed entirely on your device.")
//                        .font(.system(size: 14, weight: .regular, design: .rounded))
//                        .foregroundStyle(.white.opacity(0.5))
//                        .multilineTextAlignment(.center)
//                }
//                .opacity(appeared ? 1 : 0)
//                .scaleEffect(appeared ? 1 : 0.9)
//                
//                // Suggested questions
//                if !hasResponded {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Try asking:")
//                            .font(.system(size: 12, weight: .semibold, design: .rounded))
//                            .foregroundStyle(.white.opacity(0.4))
//                            .textCase(.uppercase)
//                            .tracking(1)
//                        
//                        ForEach(suggestedQuestions, id: \.self) { q in
//                            Button {
//                                userInput = q
//                                sendQuestion()
//                            } label: {
//                                HStack {
//                                    Text(q)
//                                        .font(.system(size: 14, weight: .regular, design: .rounded))
//                                        .foregroundStyle(.white.opacity(0.8))
//                                        .multilineTextAlignment(.leading)
//                                    Spacer()
//                                    Image(systemName: "arrow.up.circle.fill")
//                                        .font(.system(size: 18))
//                                        .foregroundStyle(.purple.opacity(0.7))
//                                }
//                                .padding(.horizontal, 14)
//                                .padding(.vertical, 11)
//                                .background(
//                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                        .fill(.white.opacity(0.06))
//                                        .overlay(
//                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                                .stroke(.white.opacity(0.08), lineWidth: 1)
//                                        )
//                                )
//                            }
//                        }
//                    }
//                    .opacity(appeared ? 1 : 0)
//                    .transition(.opacity.combined(with: .move(edge: .bottom)))
//                }
//                
//                // Response bubble
//                if hasResponded || isLoading {
//                    ChatBubble(
//                        userMessage: userInput,
//                        aiResponse: response,
//                        isLoading: isLoading
//                    )
//                    .transition(.asymmetric(
//                        insertion: .move(edge: .bottom).combined(with: .opacity),
//                        removal: .opacity
//                    ))
//                }
//                
//                // Custom input field
//                HStack(spacing: 10) {
//                    TextField("Ask a question about your finances…", text: $userInput, axis: .vertical)
//                        .font(.system(size: 15, weight: .regular, design: .rounded))
//                        .foregroundStyle(.white)
//                        .lineLimit(1...3)
//                        .focused($inputFocused)
//                        .submitLabel(.send)
//                        .onSubmit { sendQuestion() }
//                    
//                    Button {
//                        sendQuestion()
//                    } label: {
//                        Image(systemName: isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
//                            .font(.system(size: 28))
//                            .foregroundStyle(userInput.isEmpty ? .white.opacity(0.25) : .purple)
//                    }
//                    .disabled(userInput.isEmpty || isLoading)
//                    .animation(.spring(response: 0.3), value: userInput.isEmpty)
//                }
//                .padding(.horizontal, 14)
//                .padding(.vertical, 10)
//                .background(
//                    RoundedRectangle(cornerRadius: 16, style: .continuous)
//                        .fill(.white.opacity(0.07))
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 16, style: .continuous)
//                                .stroke(inputFocused ? .purple.opacity(0.5) : .white.opacity(0.1), lineWidth: 1.2)
//                        )
//                )
//                .animation(.easeInOut(duration: 0.2), value: inputFocused)
//                .opacity(appeared ? 1 : 0)
//                
//                Button(hasResponded ? "Continue" : "Skip for now", action: next)
//                    .buttonStyle(PrimaryButtonStyle())
//                    .opacity(appeared ? 1 : 0)
//            }
//        }
//        .onAppear {
//            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
//                appeared = true
//            }
//            initSession()
//        }
//    }
//    
//    // MARK: Foundation Models Integration
//    
//    private func initSession() {
//        // Initialise an on-device LanguageModelSession with a financial assistant persona
//        let instructions = Instructions(demoContext)
//        session = LanguageModelSession(instructions: instructions)
//    }
//    
//    private func sendQuestion() {
//        guard !userInput.isEmpty, !isLoading else { return }
//        let question = userInput
//        inputFocused = false
//        
//        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
//            isLoading = true
//            hasResponded = true
//            response = ""
//        }
//        
//        Task {
//            do {
//                guard let session = session else { return }
//                
//                // Stream the response token-by-token for a live typing effect
//                let stream = session.streamResponse(to: Prompt(question))
//                
//                for try await partial in stream {
//                    await MainActor.run {
//                        withAnimation(.easeIn(duration: 0.05)) {
//                            response = partial.content
//                        }
//                    }
//                }
//                
//                await MainActor.run {
//                    withAnimation(.spring(response: 0.4)) {
//                        isLoading = false
//                    }
//                }
//            } catch {
//                await MainActor.run {
//                    response = "I wasn't able to process that right now. In the real app, all your questions are answered privately on your device."
//                    isLoading = false
//                }
//            }
//        }
//    }
//}
//
//struct ChatBubble: View {
//    let userMessage: String
//    let aiResponse: String
//    let isLoading: Bool
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // User message
//            HStack {
//                Spacer()
//                Text(userMessage)
//                    .font(.system(size: 14, weight: .regular, design: .rounded))
//                    .foregroundStyle(.white.opacity(0.9))
//                    .padding(.horizontal, 14)
//                    .padding(.vertical, 10)
//                    .background(
//                        Capsule()
//                            .fill(
//                                LinearGradient(
//                                    colors: [.purple.opacity(0.5), .blue.opacity(0.4)],
//                                    startPoint: .topLeading,
//                                    endPoint: .bottomTrailing
//                                )
//                            )
//                    )
//            }
//            
//            // AI response
//            HStack(alignment: .top, spacing: 10) {
//                ZStack {
//                    Circle()
//                        .fill(.white.opacity(0.08))
//                        .frame(width: 30, height: 30)
//                    Image(systemName: "brain.filled.head.profile")
//                        .font(.system(size: 14))
//                        .foregroundStyle(.purple)
//                }
//                
//                if isLoading && aiResponse.isEmpty {
//                    TypingIndicator()
//                } else {
//                    Text(aiResponse.isEmpty ? "" : aiResponse)
//                        .font(.system(size: 14, weight: .regular, design: .rounded))
//                        .foregroundStyle(.white.opacity(0.85))
//                        .padding(.horizontal, 14)
//                        .padding(.vertical, 10)
//                        .background(
//                            RoundedRectangle(cornerRadius: 14, style: .continuous)
//                                .fill(.white.opacity(0.07))
//                        )
//                }
//                
//                Spacer()
//            }
//        }
//        .padding(16)
//        .background(
//            RoundedRectangle(cornerRadius: 20, style: .continuous)
//                .fill(.white.opacity(0.04))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 20, style: .continuous)
//                        .stroke(.white.opacity(0.07), lineWidth: 1)
//                )
//        )
//    }
//}
//
//struct TypingIndicator: View {
//    @State private var phase: CGFloat = 0
//    
//    var body: some View {
//        HStack(spacing: 5) {
//            ForEach(0..<3) { i in
//                Circle()
//                    .fill(.white.opacity(0.5))
//                    .frame(width: 7, height: 7)
//                    .scaleEffect(sin(phase + CGFloat(i) * .pi / 1.5) * 0.4 + 0.7)
//            }
//        }
//        .padding(.horizontal, 14)
//        .padding(.vertical, 12)
//        .background(
//            RoundedRectangle(cornerRadius: 14, style: .continuous)
//                .fill(.white.opacity(0.07))
//        )
//        .onAppear {
//            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
//                phase = .pi * 2
//            }
//        }
//    }
//}
//
//// MARK: - Page 5: Insight Builder (Interactive)
//
///// User taps spending categories to "build" a personalised insight —
///// Foundation Models then generates a tailored tip on-device.
//struct InsightDemoPage: View {
//    let next: () -> Void
//    
//    @State private var appeared = false
//    @State private var selectedCategories: Set<String> = []
//    @State private var generatedInsight: String = ""
//    @State private var isGenerating: Bool = false
//    @State private var session: LanguageModelSession?
//    
//    private let categories: [(String, String, Double)] = [
//        ("Dining Out", "fork.knife", 210),
//        ("Groceries", "cart.fill", 180),
//        ("Transport", "car.fill", 95),
//        ("Subscriptions", "play.rectangle.fill", 65),
//        ("Entertainment", "ticket.fill", 40),
//        ("Health & Fitness", "heart.fill", 55)
//    ]
//    
//    var body: some View {
//        PageShell {
//            VStack(spacing: 24) {
//                
//                VStack(spacing: 10) {
//                    Text("Tap what you\nspend on most")
//                        .font(.system(size: 32, weight: .bold, design: .rounded))
//                        .foregroundStyle(.white)
//                        .multilineTextAlignment(.center)
//                    
//                    Text("Get a personalised insight powered by Apple Intelligence")
//                        .font(.system(size: 14, weight: .regular, design: .rounded))
//                        .foregroundStyle(.white.opacity(0.5))
//                        .multilineTextAlignment(.center)
//                }
//                .opacity(appeared ? 1 : 0)
//                
//                // Spending chips
//                FlowLayout(spacing: 10) {
//                    ForEach(categories, id: \.0) { cat in
//                        SpendingChip(
//                            name: cat.0,
//                            icon: cat.1,
//                            amount: cat.2,
//                            isSelected: selectedCategories.contains(cat.0)
//                        )
//                        .onTapGesture {
//                            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
//                                if selectedCategories.contains(cat.0) {
//                                    selectedCategories.remove(cat.0)
//                                } else {
//                                    selectedCategories.insert(cat.0)
//                                }
//                            }
//                            if selectedCategories.count >= 2 {
//                                generateInsight()
//                            }
//                        }
//                    }
//                }
//                .opacity(appeared ? 1 : 0)
//                
//                // Generated insight card
//                if !generatedInsight.isEmpty || isGenerating {
//                    InsightResultCard(text: generatedInsight, isLoading: isGenerating)
//                        .transition(.asymmetric(
//                            insertion: .move(edge: .bottom).combined(with: .opacity),
//                            removal: .opacity
//                        ))
//                } else if selectedCategories.count < 2 {
//                    HStack(spacing: 6) {
//                        Image(systemName: "hand.tap.fill")
//                            .font(.system(size: 13))
//                        Text("Select at least 2 categories")
//                            .font(.system(size: 13, weight: .regular, design: .rounded))
//                    }
//                    .foregroundStyle(.white.opacity(0.3))
//                    .transition(.opacity)
//                }
//                
//                Spacer(minLength: 8)
//                
//                Button("Continue", action: next)
//                    .buttonStyle(PrimaryButtonStyle())
//                    .opacity(appeared ? 1 : 0)
//            }
//        }
//        .onAppear {
//            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
//                appeared = true
//            }
//            initSession()
//        }
//    }
//    
//    private func initSession() {
//        let instructions = Instructions("""
//        You are a friendly, private on-device financial coach.
//        The user has identified their main spending categories.
//        Generate one short, specific, actionable insight (2 sentences max) about
//        how they could optimise their spending. Be warm, personal, and practical.
//        Focus on patterns and concrete savings opportunities.
//        """)
//        session = LanguageModelSession(instructions: instructions)
//    }
//    
//    private func generateInsight() {
//        guard !isGenerating, selectedCategories.count >= 2 else { return }
//        isGenerating = true
//        generatedInsight = ""
//        
//        let cats = selectedCategories.sorted().joined(separator: ", ")
//        let prompt = "My top spending categories are: \(cats). Give me a personalised financial tip."
//        
//        Task {
//            do {
//                guard let session = session else { return }
//                let stream = session.streamResponse(to: Prompt(prompt))
//                
//                for try await partial in stream {
//                    await MainActor.run {
//                        generatedInsight = partial.content
//                    }
//                }
//                
//                await MainActor.run {
//                    withAnimation { isGenerating = false }
//                }
//            } catch {
//                await MainActor.run {
//                    generatedInsight = "Great choices! Tracking these categories will help you spot patterns and opportunities to save over time."
//                    isGenerating = false
//                }
//            }
//        }
//    }
//}
//
//struct SpendingChip: View {
//    let name: String
//    let icon: String
//    let amount: Double
//    let isSelected: Bool
//    
//    var body: some View {
//        HStack(spacing: 7) {
//            Image(systemName: icon)
//                .font(.system(size: 13, weight: .medium))
//                .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
//            Text(name)
//                .font(.system(size: 14, weight: .medium, design: .rounded))
//                .foregroundStyle(isSelected ? .black : .white.opacity(0.85))
//        }
//        .padding(.horizontal, 14)
//        .padding(.vertical, 9)
//        .background(
//            Capsule()
//                .fill(isSelected ? .white : .white.opacity(0.08))
//                .shadow(color: isSelected ? .white.opacity(0.2) : .clear, radius: 8)
//        )
//        .scaleEffect(isSelected ? 1.06 : 1.0)
//    }
//}
//
//struct InsightResultCard: View {
//    let text: String
//    let isLoading: Bool
//    
//    var body: some View {
//        HStack(alignment: .top, spacing: 12) {
//            ZStack {
//                Circle()
//                    .fill(
//                        LinearGradient(
//                            colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
//                            startPoint: .topLeading, endPoint: .bottomTrailing
//                        )
//                    )
//                    .frame(width: 36, height: 36)
//                Image(systemName: "sparkles")
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundStyle(.yellow)
//                    .symbolEffect(.variableColor.iterative, options: isLoading ? .repeating : .default)
//            }
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Your Insight")
//                    .font(.system(size: 11, weight: .bold, design: .rounded))
//                    .foregroundStyle(.white.opacity(0.4))
//                    .textCase(.uppercase)
//                    .tracking(0.8)
//                
//                if isLoading && text.isEmpty {
//                    TypingIndicator()
//                } else {
//                    Text(text)
//                        .font(.system(size: 15, weight: .regular, design: .rounded))
//                        .foregroundStyle(.white.opacity(0.9))
//                        .lineSpacing(3)
//                }
//            }
//        }
//        .padding(18)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(
//            RoundedRectangle(cornerRadius: 20, style: .continuous)
//                .fill(
//                    LinearGradient(
//                        colors: [.yellow.opacity(0.08), .orange.opacity(0.06)],
//                        startPoint: .topLeading, endPoint: .bottomTrailing
//                    )
//                )
//                .overlay(
//                    RoundedRectangle(cornerRadius: 20, style: .continuous)
//                        .stroke(.yellow.opacity(0.2), lineWidth: 1)
//                )
//        )
//    }
//}
//
//// MARK: - FlowLayout (chip wrapping)
//
//struct FlowLayout: Layout {
//    var spacing: CGFloat = 8
//    
//    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
//        let rows = computeRows(proposal: proposal, subviews: subviews)
//        let height = rows.map { $0.map { $0.height }.max() ?? 0 }.reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * spacing
//        return CGSize(width: proposal.width ?? 0, height: height)
//    }
//    
//    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
//        let rows = computeRows(proposal: proposal, subviews: subviews)
//        var y = bounds.minY
//        for row in rows {
//            var x = bounds.minX
//            let rowHeight = row.map { $0.height }.max() ?? 0
//            for item in row {
//                item.view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
//                x += item.width + spacing
//            }
//            y += rowHeight + spacing
//        }
//    }
//    
//    private struct ItemInfo { let view: LayoutSubview; let width: CGFloat; let height: CGFloat }
//    
//    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[ItemInfo]] {
//        let maxWidth = proposal.width ?? 0
//        var rows: [[ItemInfo]] = []
//        var currentRow: [ItemInfo] = []
//        var currentWidth: CGFloat = 0
//        
//        for subview in subviews {
//            let size = subview.sizeThatFits(.unspecified)
//            let item = ItemInfo(view: subview, width: size.width, height: size.height)
//            if currentRow.isEmpty {
//                currentRow.append(item)
//                currentWidth = size.width
//            } else if currentWidth + spacing + size.width <= maxWidth {
//                currentRow.append(item)
//                currentWidth += spacing + size.width
//            } else {
//                rows.append(currentRow)
//                currentRow = [item]
//                currentWidth = size.width
//            }
//        }
//        if !currentRow.isEmpty { rows.append(currentRow) }
//        return rows
//    }
//}
//
//// MARK: - Page 6: Final
//
//struct FinalPage: View {
//    let done: () -> Void
//    @State private var appeared = false
//    @State private var checkScale: CGFloat = 0.3
//    
//    var body: some View {
//        PageShell {
//            VStack(spacing: 28) {
//                Spacer(minLength: 40)
//                
//                // Animated checkmark
//                ZStack {
//                    Circle()
//                        .fill(
//                            RadialGradient(
//                                colors: [.green.opacity(0.2), .clear],
//                                center: .center,
//                                startRadius: 30,
//                                endRadius: 90
//                            )
//                        )
//                        .frame(width: 180, height: 180)
//                        .blur(radius: 20)
//                    
//                    Circle()
//                        .fill(.green.opacity(0.12))
//                        .frame(width: 120, height: 120)
//                    
//                    Image(systemName: "checkmark.seal.fill")
//                        .font(.system(size: 72))
//                        .foregroundStyle(
//                            LinearGradient(
//                                colors: [.green, .mint],
//                                startPoint: .top,
//                                endPoint: .bottom
//                            )
//                        )
//                        .symbolEffect(.bounce, options: .speed(0.6))
//                        .scaleEffect(checkScale)
//                }
//                
//                VStack(spacing: 14) {
//                    Text("You're all set.")
//                        .font(.system(size: 40, weight: .bold, design: .rounded))
//                        .foregroundStyle(.white)
//                        .opacity(appeared ? 1 : 0)
//                        .offset(y: appeared ? 0 : 20)
//                    
//                    Text("Your private financial assistant is ready.\nEverything stays on your device — always.")
//                        .font(.system(size: 16, weight: .regular, design: .rounded))
//                        .multilineTextAlignment(.center)
//                        .foregroundStyle(.white.opacity(0.5))
//                        .opacity(appeared ? 1 : 0)
//                        .offset(y: appeared ? 0 : 15)
//                }
//                
//                // Mini recap
//                VStack(spacing: 0) {
//                    RecapRow(icon: "lock.shield.fill", color: .cyan, text: "100% private, on-device")
//                    Divider().background(.white.opacity(0.08))
//                    RecapRow(icon: "brain.filled.head.profile", color: .purple, text: "AI financial intelligence")
//                    Divider().background(.white.opacity(0.08))
//                    RecapRow(icon: "chart.line.uptrend.xyaxis", color: .blue, text: "Smart spending insights")
//                }
//                .background(
//                    RoundedRectangle(cornerRadius: 18, style: .continuous)
//                        .fill(.white.opacity(0.05))
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 18, style: .continuous)
//                                .stroke(.white.opacity(0.08), lineWidth: 1)
//                        )
//                )
//                .opacity(appeared ? 1 : 0)
//                
//                Spacer(minLength: 8)
//                
//                Button {
//                    done()
//                } label: {
//                    Text("Start Using App")
//                        .frame(maxWidth: .infinity)
//                }
//                .buttonStyle(PrimaryButtonStyle())
//                .opacity(appeared ? 1 : 0)
//            }
//        }
//        .onAppear {
//            withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.15)) {
//                checkScale = 1.0
//            }
//            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.25)) {
//                appeared = true
//            }
//        }
//    }
//}
//
//struct RecapRow: View {
//    let icon: String
//    let color: Color
//    let text: String
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            Image(systemName: icon)
//                .font(.system(size: 16, weight: .medium))
//                .foregroundStyle(color)
//                .frame(width: 24)
//            Text(text)
//                .font(.system(size: 15, weight: .regular, design: .rounded))
//                .foregroundStyle(.white.opacity(0.8))
//            Spacer()
//            Image(systemName: "checkmark")
//                .font(.system(size: 12, weight: .semibold))
//                .foregroundStyle(.green.opacity(0.7))
//        }
//        .padding(.horizontal, 18)
//        .padding(.vertical, 14)
//    }
//}
//
//// MARK: - Preview
//
//#Preview {
//    OnboardingContainerView()
//}








import SwiftUI
import StoreKit

// MARK: - Onboarding Coordinator

struct OnboardingFlow: View {
    @Environment(SubscriptionController.self) var subscriptionController
    @State private var currentPage = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private let pages: [OnboardingPage2] = [
        OnboardingPage2(
            systemImage: "dollarsign.circle.fill",
            imageColor: .green,
            title: "Your Money,\nYour Rules",
            subtitle: "A smarter way to manage every dollar — no bank connections, no subscriptions, no nonsense.",
            backgroundSymbol: "dollarsign"
        ),
        OnboardingPage2(
            systemImage: "mic.fill",
            imageColor: .green,
            title: "Add Expenses\nin Seconds",
            subtitle: "Speak or type to log spending on the spot. Organize into custom categories and get budget alerts before you overspend.",
            backgroundSymbol: "waveform"
        ),
        OnboardingPage2(
            systemImage: "creditcard.fill",
            imageColor: .green,
            title: "Apple Card\nNatively Supported",
            subtitle: "Automatically sync Apple Card and Apple Cash transactions. Everything else stays manual — because your data is yours alone.",
            backgroundSymbol: "lock.shield"
        ),
        OnboardingPage2(
            systemImage: "chart.bar.xaxis",
            imageColor: .green,
            title: "See the\nBig Picture",
            subtitle: "Visual breakdowns, recurring bills, income tracking, and insights — all in one place, all offline.",
            backgroundSymbol: "chart.pie"
        )
    ]

    var body: some View {
        ZStack {
            if currentPage < pages.count {
                OnboardingPageView(
                    page: pages[currentPage],
                    pageIndex: currentPage,
                    pageCount: pages.count,
                    onNext: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                            currentPage += 1
                        }
                    }
                )
                .id(currentPage)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
            } else {
                OnboardingPaywallView(onComplete: {
                    hasSeenOnboarding = true
                })
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: currentPage)
    }
}

// MARK: - Page Model

struct OnboardingPage2 {
    let systemImage: String
    let imageColor: Color
    let title: String
    let subtitle: String
    let backgroundSymbol: String
}

// MARK: - Single Onboarding Page

struct OnboardingPageView: View {
    let page: OnboardingPage2
    let pageIndex: Int
    let pageCount: Int
    let onNext: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            // Decorative large background symbol
            Image(systemName: page.backgroundSymbol)
                .font(.system(size: 320, weight: .ultraLight))
                .foregroundStyle(Color.green.opacity(0.06))
                .rotationEffect(.degrees(-15))
                .offset(x: 80, y: -60)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Color.green.opacity(0.18))
                        .frame(width: 90, height: 90)

                    Image(systemName: page.systemImage)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Color.green)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.1), value: appeared)

                Spacer().frame(height: 40)

                // Title
                Text(page.title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                    .offset(y: appeared ? 0 : 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.2), value: appeared)

                Spacer().frame(height: 20)

                // Subtitle
                Text(page.subtitle)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 36)
                    .offset(y: appeared ? 0 : 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.28), value: appeared)

                Spacer()

                // Page dots
                PageIndicator(currentPage: pageIndex, totalPages: pageCount + 1) // +1 for paywall
                    .padding(.bottom, 32)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.35), value: appeared)

                // CTA Button
                Button(action: onNext) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.38), value: appeared)

                Spacer().frame(height: 52)
            }
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }
}

// MARK: - Page Indicator

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.green : Color.green.opacity(0.25))
                    .frame(width: index == currentPage ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentPage)
            }
        }
    }
}

// MARK: - Onboarding Paywall (integrated, conversion-optimized)

struct OnboardingPaywallView: View {
    @Environment(SubscriptionController.self) var subscriptionController
    @State private var selectedProduct: Product?
    @State private var appeared = false
    @State private var isPurchasing = false
    let onComplete: () -> Void

    private let features: [(symbol: String, title: String, detail: String)] = [
        ("mic.fill",        "Voice Expense Entry",    "Log spending hands-free, anytime"),
        ("creditcard.fill", "Apple Card Sync",        "Auto-import without sharing credentials"),
        ("chart.bar.xaxis", "Visual Insights",        "Understand your habits at a glance"),
        ("calendar",        "Bill Management",        "Never miss a recurring payment"),
        ("lock.shield",     "100% Private & Offline", "No accounts, no ads, no tracking")
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            // Background decoration
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 300, weight: .ultraLight))
                .foregroundStyle(Color.green.opacity(0.05))
                .rotationEffect(.degrees(20))
                .offset(x: 90, y: -140)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // MARK: Hero
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.12))
                                .frame(width: 100, height: 100)
                            Circle()
                                .fill(Color.green.opacity(0.18))
                                .frame(width: 74, height: 74)
                            Image(systemName: "sparkles")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(Color.green)
                        }
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.05), value: appeared)

                        Text("Unlock\nSimpler Budget")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .offset(y: appeared ? 0 : 16)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)

                        Text("One purchase. Everything. Forever.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .offset(y: appeared ? 0 : 12)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
                    }
                    .padding(.top, 48)
                    .padding(.bottom, 32)

                    // MARK: Feature List
                    VStack(spacing: 0) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            FeatureRow(symbol: feature.symbol, title: feature.title, detail: feature.detail)
                                .offset(y: appeared ? 0 : 20)
                                .opacity(appeared ? 1 : 0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                        .delay(0.25 + Double(index) * 0.07),
                                    value: appeared
                                )

                            if index < features.count - 1 {
                                Divider()
                                    .padding(.leading, 52)
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.22), value: appeared)

                    Spacer().frame(height: 28)

                    // MARK: Product Cards
                    if subscriptionController.products.isEmpty {
                        ProgressView()
                            .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(
                                subscriptionController.products.sorted { a, _ in a.id.contains("lifetime") },
                                id: \.id
                            ) { product in
                                PaywallProductCard(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    onSelect: { selectedProduct = product }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .offset(y: appeared ? 0 : 16)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.55), value: appeared)
                    }

                    Spacer().frame(height: 20)

                    // MARK: Free tier note
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Try free with limited features. Upgrade anytime.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 28)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.6), value: appeared)

                    Spacer().frame(height: 120) // space for pinned button
                }
            }

            // MARK: Pinned Bottom CTA
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 12) {
                    // Purchase button
                    Button {
                        guard let product = selectedProduct else { return }
                        isPurchasing = true
                        Task {
                            await subscriptionController.purchase(product)
                            isPurchasing = false
                            if subscriptionController.isSubscribed {
                                onComplete()
                            }
                        }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 17)
                            } else {
                                Text(ctaLabel)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 17)
                            }
                        }
                        .background(selectedProduct == nil ? Color.gray.opacity(0.5) : Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(selectedProduct == nil || isPurchasing)
                    .animation(.easeInOut(duration: 0.2), value: selectedProduct?.id)

                    // Secondary actions
                    HStack(spacing: 24) {
                        Button("Continue Free") {
                            onComplete()
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                        Button("Restore") {
                            Task {
                                await subscriptionController.restorePurchases()
                                if subscriptionController.isSubscribed { onComplete() }
                            }
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    }

                    // Legal links
                    HStack(spacing: 16) {
                        Link("Privacy Policy",
                             destination: URL(string: "https://github.com/crwells86/Privacy-Policy")!)
                        Link("Terms of Use",
                             destination: URL(string: "https://github.com/crwells86/Terms-of-Use")!)
                    }
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Color(.tertiaryLabel))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 36)
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(cornerRadius: 0)
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            appeared = true
            selectedProduct = subscriptionController.products.first(where: {
                $0.id.contains("lifetime")
            }) ?? subscriptionController.products.first
        }
    }

    private var ctaLabel: String {
        guard let product = selectedProduct else { return "Select a Plan" }
        if product.id.contains("lifetime") {
            return "Get Lifetime Access — \(product.displayPrice)"
        } else {
            return "Subscribe — \(product.displayPrice)/yr"
        }
    }
}

// MARK: - Feature Row (Paywall)

private struct FeatureRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.green)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Product Card (Paywall)

private struct PaywallProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    private var isLifetime: Bool { product.id.contains("lifetime") }

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 14) {
                    // Radio
                    ZStack {
                        Circle()
                            .strokeBorder(isSelected ? Color.green : Color(.systemGray3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 14, height: 14)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(product.displayName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Text(isLifetime ? "Pay once — own it forever" : "Billed annually")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(product.displayPrice)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? Color.green : .primary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? Color.green.opacity(0.1) : Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isSelected ? Color.green : Color.clear, lineWidth: 2)
                )

                // Badge
                if isLifetime {
                    Text("BEST VALUE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.green)
                        .clipShape(Capsule())
                        .offset(x: -12, y: -12)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Entry Point Helper
// Wrap your existing ContentView with this to gate on onboarding

struct OnboardingGate<Content: View>: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        if hasSeenOnboarding {
            content()
        } else {
            OnboardingFlow()
        }
    }
}


#Preview {
    OnboardingFlow()
        .environment(SubscriptionController())
}

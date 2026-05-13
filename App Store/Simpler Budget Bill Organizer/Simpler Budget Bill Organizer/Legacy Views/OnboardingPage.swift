//import SwiftUI
//
//struct OnboardingPage: View {
//    let image: String
//    let title: String
//    let description: String
//    
//    var body: some View {
//        VStack(spacing: 32) {
//            Image(systemName: image)
//                .font(.system(size: 80))
//                .foregroundColor(.green)
//            
//            Text(title)
//                .font(.title)
//                .bold()
//                .multilineTextAlignment(.center)
//            
//            Text(description)
//                .font(.body)
//                .multilineTextAlignment(.center)
//                .foregroundColor(.secondary)
//                .padding(.horizontal)
//        }
//        .padding()
//    }
//}

import SwiftUI

struct OnboardingPage: View {
    let image: String
    let title: String
    let description: String
    let accentColor: Color
    let index: Int

    @State private var appeared = false
    @State private var iconPulse = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Ambient gradient blob behind icon
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.25), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 30)
                    .offset(y: -geo.size.height * 0.08)
                    .scaleEffect(iconPulse ? 1.12 : 1.0)
                    .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: iconPulse)

                VStack(spacing: 0) {
                    Spacer()

                    // Icon container with glass effect
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [accentColor.opacity(0.8), accentColor.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: accentColor.opacity(0.3), radius: 20, y: 8)

                        Image(systemName: image)
                            .font(.system(size: 46, weight: .medium, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.bounce, value: appeared)
                    }
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1), value: appeared)

                    Spacer().frame(height: 40)

                    // Title
                    Text(title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.22), value: appeared)

                    Spacer().frame(height: 16)

                    // Description
                    Text(description)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .offset(y: appeared ? 0 : 16)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.32), value: appeared)

                    Spacer()
                    Spacer()
                }
            }
        }
        .onAppear {
            appeared = true
            iconPulse = true
        }
        .onDisappear {
            appeared = false
        }
    }
}

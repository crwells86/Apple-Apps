import SwiftUI

struct WhatsNewSheet: ViewModifier {
    @AppStorage("lastSeenVersion") private var lastSeenVersion: String = ""
    @State private var isPresented: Bool = false
    
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if lastSeenVersion != currentVersion {
                    isPresented = true
                }
            }
            .sheet(isPresented: $isPresented, onDismiss: {
                lastSeenVersion = currentVersion
            }) {
                WhatsNewView(version: currentVersion)
            }
    }
}

extension View {
    func whatsNewSheet() -> some View {
        self.modifier(WhatsNewSheet())
    }
}

struct WhatsNewItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

struct WhatsNewView: View {
    let version: String
    
    private let features: [WhatsNewItem] = [
        .init(
            icon: "textformat",
            title: "New App Name",
            subtitle: "I have updated the app’s name to avoid confusion with another app that had a similar name and developer first name."
        ),
        
        .init(
            icon: "wrench.and.screwdriver",
            title: "Improvements",
            subtitle: "Minor fixes and performance enhancements for a smoother experience."
        ),
        
        .init(
            icon: "creditcard",
            title: "Apple Card & Apple Cash Only",
            subtitle: "Automatic imports are available exclusively for Apple Card and Apple Cash, services provided by Apple and not available in all countries or regions. No other credit cards, debit cards, or bank accounts can be connected."
        )
    ]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What's New in \nversion \(version)")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 20) {
                ForEach(features) { item in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: item.icon)
                            .foregroundColor(.accentColor)
                            .font(.title3)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
            
            Button {
                if let url = URL(string: "https://apps.apple.com/app/id6745808332?action=write-review") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Rate on the App Store")
                    .font(.footnote)
                    .foregroundStyle(.tint)
                    .padding(.top, 8)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(.background)
    }
}

#Preview {
    WhatsNewView(version: "0.5.1")
}



import SwiftUI

// MARK: - WhatsNewView

struct WhatsNewAIView: View {
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                Text("What's New")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your finance assistant is here, and it's entirely on your device. This is a \(Text("Beta").fontWeight(.black).foregroundStyle(.green)) — your feedback shapes what comes next.")
                    .font(.subheadline)
                    .lineSpacing(4)
                    .padding(.bottom, 28)
                
                FeatureRow(
                    icon: "message.fill",
                    title: "Just talk to it",
                    description: "Log bills, expenses, and income in plain language — \"water bill, $85, every other month on the 19th\" and it's done."
                )

                FeatureRow(
                    icon: "calendar.badge.clock",
                    title: "Smart bill scheduling",
                    description: "Complex recurrence like \"every 3rd Thursday\" or \"the 1st of every other month\" is understood and set automatically."
                )

                FeatureRow(
                    icon: "bell.badge.fill",
                    title: "Reminders on your terms",
                    description: "After adding a bill, just say yes to a reminder. No settings screen needed."
                )

                FeatureRow(
                    icon: "chart.bar.fill",
                    title: "Ask anything about your money",
                    description: "\"How much did I spend today?\" and \"What do I need to earn this week?\" get real answers from your actual data."
                )

                FeatureRow(
                    icon: "lock.fill",
                    title: "Completely private, fully on-device",
                    description: "Powered by Apple Intelligence — no servers, no accounts, nothing leaves your device.",
                    showDivider: false
                )
                
                // ── Requirements card ─────────────────────────────────────────
                RequirementsCard()
                    .padding(.top, 28)

                // ── Optional dismiss button ────────────────────────────────────
                if let onDismiss {
                    Button(action: onDismiss) {
                        Text("Continue")
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.primary)
                            .foregroundStyle(Color(uiColor: .systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.top, 24)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
    }
}

// MARK: - FeatureRow

private struct FeatureRow: View {
    let icon: String
    let title: String
    var isNew: Bool = false
    let description: String
    var showDivider: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {

                // Icon tile
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.primary)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 6) {
                        Text(title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)

                        if isNew {
                            Text("New")
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.12))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, 22)

            if showDivider {
                Divider()
                    .padding(.bottom, 22)
            }
        }
    }
}

// MARK: - RequirementsCard

private struct RequirementsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Requirements")
                .font(.caption)
                .fontWeight(.medium)
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            RequirementRow(
                icon: "iphone",
                text: "Requires a device capable of running Apple Intelligence"
            )
            RequirementRow(
                icon: "apple.logo",
                text: "iOS 26 or later"
            )
            RequirementRow(
                icon: "sparkles",
                text: "Apple Intelligence must be enabled in Settings"
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - RequirementRow

private struct RequirementRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    WhatsNewAIView(onDismiss: {})
}

#Preview("Sheet") {
    Color(uiColor: .systemGroupedBackground)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            WhatsNewAIView(onDismiss: {})
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
}

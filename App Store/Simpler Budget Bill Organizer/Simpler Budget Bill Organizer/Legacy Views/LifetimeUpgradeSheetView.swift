import SwiftUI
import StoreKit

// MARK: - Lifetime Upgrade Sheet View

struct LifetimeUpgradeSheetView: View {
    @Environment(SubscriptionController.self) var subscriptionController
    @Binding var isPresented: Bool

    @AppStorage("hasSeenLifetimeOffer") private var hasSeenLifetimeOffer = false
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false

    @State private var lifetimeProduct: Product?
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showCancellationGuide = false
    @State private var purchaseSucceeded = false
    @State private var animateIn = false

    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            if showCancellationGuide {
                CancellationGuideView {
                    hasSeenLifetimeOffer = true
                    isPresented = false
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
            } else {
                mainOfferContent
                    .transition(.opacity)
            }
        }
        .interactiveDismissDisabled(true) // Only dismissible via the button
        .task {
            lifetimeProduct = subscriptionController.products.first {
                $0.id == "com.Simpler.Budget.lifetime"
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateIn = true
            }
        }
    }

    // MARK: - Main Offer Content

    private var mainOfferContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Value props
                VStack(spacing: 12) {
                    benefitRow(
                        icon: "infinity",
                        title: "Pay Once, Own Forever",
                        description: "No renewal reminders, no price hikes, no surprises. Just Simpler Budget, always."
                    )
                    benefitRow(
                        icon: "bell.slash.fill",
                        title: "Zero Subscription Anxiety",
                        description: "One less recurring charge to think about — and that's kind of the whole point of this app."
                    )
                    benefitRow(
                        icon: "checkmark.shield.fill",
                        title: "All Future Features Included",
                        description: "Lifetime access means exactly that. Every update, every new tool, forever."
                    )
                    benefitRow(
                        icon: "arrow.down.circle.fill",
                        title: "Cancel Your Subscription Today",
                        description: "We'll walk you through it. Takes about 30 seconds."
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.25), value: animateIn)

                // Pricing card
                pricingCard
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.4), value: animateIn)

                // Purchase button
                purchaseButton
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.5), value: animateIn)

                if let error = purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 12)
                }

                // Dismiss link
                Button {
                    hasSeenLifetimeOffer = true
                    isPresented = false
                } label: {
                    Text("Maybe later")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
                .padding(.top, 16)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(0.6), value: animateIn)

                Spacer(minLength: 40)
            }
        }
        .overlay(alignment: .topTrailing) {
            dismissButton
                .padding(.top, 16)
                .padding(.trailing, 20)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.2), Color.mint.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 56)

            Text("Own It Outright")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Your subscription renews soon — upgrade to lifetime\naccess and never think about it again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 32)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -10)
        .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.1), value: animateIn)
    }

    // MARK: - Benefit Row

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    // MARK: - Pricing Card

    private var pricingCard: some View {
        VStack(spacing: 6) {
            if let product = lifetimeProduct {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("one‑time")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 6)
                }
            } else {
                Text("Loading…")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            Text("vs. paying every year, forever")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.08), Color.mint.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            guard let product = lifetimeProduct else { return }
            Task { await handlePurchase(product) }
        } label: {
            ZStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(lifetimeProduct != nil ? "Upgrade to Lifetime — \(lifetimeProduct!.displayPrice)" : "Upgrade to Lifetime")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: isPurchasing
                        ? [Color.green.opacity(0.6), Color.mint.opacity(0.6)]
                        : [Color.green, Color.mint],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .disabled(isPurchasing || lifetimeProduct == nil)
        .buttonStyle(.plain)
    }

    // MARK: - Dismiss Button (top-right corner only)

    private var dismissButton: some View {
        Button {
            hasSeenLifetimeOffer = true
            isPresented = false
        } label: {
            ZStack {
                Circle()
                    .fill(Color(UIColor.tertiarySystemBackground))
                    .frame(width: 34, height: 34)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Logic

    private func handlePurchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await subscriptionController.checkSubscription()
                    purchaseSucceeded = true
                    isPurchasing = false
                    hasSeenLifetimeOffer = true

                    // Prompt for App Store review
                    await requestReviewAfterPurchase()

                    // Show cancellation guide with animation
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        showCancellationGuide = true
                    }

                case .unverified(_, let error):
                    purchaseError = "Verification failed: \(error.localizedDescription)"
                    isPurchasing = false
                }
            case .userCancelled:
                isPurchasing = false
            case .pending:
                purchaseError = "Purchase is pending approval."
                isPurchasing = false
            @unknown default:
                isPurchasing = false
            }
        } catch {
            purchaseError = "Purchase failed. Please try again."
            isPurchasing = false
        }
    }

    @MainActor
    private func requestReviewAfterPurchase() async {
        guard !hasRequestedReview else { return }
        try? await Task.sleep(for: .seconds(1))
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: scene)
            hasRequestedReview = true
        }
    }
}

#Preview("Lifetime Upgrade Offer") {
    let controller = SubscriptionController()

    return LifetimeUpgradeSheetView(isPresented: .constant(true))
        .environment(controller)
}

#Preview("Cancellation Guide") {
    CancellationGuideView {
        print("Done tapped")
    }
}

// MARK: - Cancellation Guide View

struct CancellationGuideView: View {
    var onDone: () -> Void

    @State private var currentStep = 0
    @State private var animateIn = false

    private let steps: [(icon: String, title: String, detail: String)] = [
        (
            icon: "iphone",
            title: "Open Settings",
            detail: "Go to the Settings app on your iPhone — the grey icon with gears."
        ),
        (
            icon: "person.circle.fill",
            title: "Tap Your Name",
            detail: "At the very top of Settings, tap your Apple ID name."
        ),
        (
            icon: "bag.fill",
            title: "Subscriptions",
            detail: "Tap Subscriptions to see all your active and expired subscriptions."
        ),
        (
            icon: "dollarsign.circle.fill",
            title: "Find Simpler Budget",
            detail: "Locate Simpler Budget in the list and tap on it."
        ),
        (
            icon: "xmark.circle.fill",
            title: "Cancel Subscription",
            detail: "Tap Cancel Subscription at the bottom. You keep access until the period ends."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.green)
                }
                .padding(.top, 56)

                Text("You're a Lifetime Member!")
                    .font(.system(size: 26, weight: .bold, design: .rounded))

                Text("Cancel your old subscription so you\naren't charged again — it only takes a moment.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 36)
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : -10)
            .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.05), value: animateIn)

            // Step cards
            VStack(spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    stepCard(index: index, icon: step.icon, title: step.title, detail: step.detail)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 16)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.85)
                                .delay(0.15 + Double(index) * 0.07),
                            value: animateIn
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)

            // Done button
            Button(action: onDone) {
                Text("Done — Got It!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .opacity(animateIn ? 1 : 0)
            .animation(.easeIn(duration: 0.4).delay(0.6), value: animateIn)

            Spacer(minLength: 40)
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }

    private func stepCard(index: Int, icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Step number bubble
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Presentation Modifier

/// Call this in ContentView to automatically present the offer when
/// fewer than 7 days remain in the user's subscription and they haven't
/// yet seen or dismissed it.
struct LifetimeOfferModifier: ViewModifier {
    @Environment(SubscriptionController.self) var subscriptionController
    @AppStorage("hasSeenLifetimeOffer") private var hasSeenLifetimeOffer = false
    @State private var showLifetimeOffer = false

    func body(content: Content) -> some View {
        content
            .task {
                guard !hasSeenLifetimeOffer else { return }
                guard !isLifetimeOwner else { return }
                if await subscriptionExpiresWithinOneWeek() {
                    showLifetimeOffer = true
                }
            }
            .fullScreenCover(isPresented: $showLifetimeOffer) {
                LifetimeUpgradeSheetView(isPresented: $showLifetimeOffer)
                    .environment(subscriptionController)
            }
    }

    /// Returns true if the user already owns the lifetime product.
    private var isLifetimeOwner: Bool {
        // We check this via a quick scan of currentEntitlements below in the async path.
        // Returning false here is safe; the async check gates the actual presentation.
        false
    }

    private func subscriptionExpiresWithinOneWeek() async -> Bool {
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                // Skip the lifetime product — no expiry
                if transaction.productID == "com.Simpler.Budget.lifetime" {
                    return false
                }
                if let expiry = transaction.expirationDate {
                    let daysLeft = Calendar.current.dateComponents(
                        [.day], from: Date(), to: expiry
                    ).day ?? 0
                    return daysLeft <= 7
                }
            }
        }
        return false
    }
}

extension View {
    /// Attach to the root view (TabView in ContentView) to automatically
    /// show the lifetime upgrade offer when the subscription is about to expire.
    func lifetimeOfferSheet() -> some View {
        modifier(LifetimeOfferModifier())
    }
}

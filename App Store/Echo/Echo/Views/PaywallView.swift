import SwiftUI
import StoreKit
import Observation

// MARK: - PaywallView (Weekly + Lifetime)
struct PaywallView: View {
    @State private var store = StoreController()
    
    // Base config you can theme; prices are injected dynamically once products load.
    var baseConfig: PaywallConfig
    
    // Selection state
    @State private var selectedPlan: SelectedPlan = .weekly
    
    // Convenient default init with minimal args — the rest are defaulted in PaywallConfig
    init(config: PaywallConfig = PaywallConfig(
        imageName: "appIcon",
        headline: "Turn Any Conversation into Clear, Actionable Notes",
        features: [
            .init(iconName: "sparkles", text: "Unlimited Real-Time Transcriptions"),
            .init(iconName: "checklist", text: "AI Generated Summaries, Action Plans & Emails"),
//            .init(iconName: "magnifyingglass", text: "Searchable Transcripts – Never Lose a Detail"),
            .init(iconName: "questionmark.bubble", text: "Ask AI Anything About Your Notes"),
            .init(iconName: "lock.shield", text: "100% Private – Works Fully On-Device")
        ],
        lifetimePlan: .init(title: "Lifetime Access", badgeText: "Best Value"),
        weeklyPlan: .init(title: "Weekly Access", badgeText: "Most Popular"),
        ctaText: "Start Taking Smarter Notes",
        restoreText: "Restore",
        footerText: "Terms of Use & Privacy Policy"
    )) {
        self.baseConfig = config
    }
    
    
    private var config: PaywallConfig {
        var cfg = baseConfig
        
        if let weeklyName = store.displayName(for: StoreController.weeklyID) {
            cfg.weeklyPlan.title = weeklyName
        }
        if let weeklyText = store.priceText(for: StoreController.weeklyID) {
            cfg.weeklyPlan.priceText = weeklyText
        }
        
        if let lifetimeName = store.displayName(for: StoreController.lifetimeID) {
            cfg.lifetimePlan.title = lifetimeName
        }
        if let lifetimeText = store.priceText(for: StoreController.lifetimeID) {
            cfg.lifetimePlan.priceText = lifetimeText
        }
        
        return cfg
    }
    
    var body: some View {
        ScrollView {
            ZStack {
                WaveView(height: 66)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: -4)
                
                ZStack {
                    Circle()
                        .fill(.clear)
                    
                    Image(systemName: "mic.fill")
                        .font(.title)
                        .foregroundStyle(.primary)
                }
                .glassEffect(.clear, in: Circle())
                .frame(width: 66, height: 66)
                .offset(y: 12)
            }
            .padding(.bottom, 12)
            
            // Headline + features
            VStack(spacing: 8) {
                Text(config.headline)
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.top)
                
                Text("AI-powered, private, and 100% on your device.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(config.features) { feature in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: feature.iconName)
                                .font(.system(size: 18))
                                .frame(width: 26)
                                .foregroundStyle(config.accentColor)
                            
                            Text(feature.text)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                    }
                }
                .padding()
            }
            .padding(.horizontal)
            
            // Plans list
            VStack(spacing: 12) {
                planRow(
                    plan: config.lifetimePlan,
                    isSelected: selectedPlan == .lifetime,
                    isHighlighted: false,
                    accent: config.accentColor,
                    badgeColor: config.badgeColor,
                    cardBackground: config.cardBackground
                ) {
                    selectedPlan = .lifetime
                }
                
                planRow(
                    plan: config.weeklyPlan,
                    isSelected: selectedPlan == .weekly,
                    isHighlighted: true,
                    accent: config.accentColor,
                    badgeColor: config.badgeColor,
                    cardBackground: config.cardBackground
                ) {
                    selectedPlan = .weekly
                }
            }
            .padding()
            
            // CTA
            Button {
                Task {
                    switch selectedPlan {
                    case .lifetime:
                        if let p = store.products.first(where: { $0.id == StoreController.lifetimeID }) {
                            await store.purchase(p)
                        }
                    case .weekly:
                        if let p = store.products.first(where: { $0.id == StoreController.weeklyID }) {
                            await store.purchase(p)
                        }
                    }
                }
            } label: {
                Text(config.ctaText)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
            }
            .foregroundStyle(.primary)
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding()
            
            Spacer(minLength: 8)
            
            // Footer
            HStack(spacing: 12) {
                Button(config.restoreText) {
                    Task { await store.restorePurchases() }
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                
                
                Spacer()
                HStack(spacing: 24) {
                    Link("Privacy Policy", destination: URL(string: "https://www.olyevolutions.com/privacy-policy")!)
                    Link("Terms of Use", destination: URL(string: "https://www.olyevolutions.com/terms-of-use")!)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .padding(.top, 8)
        .padding(.vertical, 12)
        .onAppear {
            Task {
                await store.fetchProducts()
                await store.checkSubscription()
            }
        }
    }
    
    // MARK: - Plan row UI
    @ViewBuilder
    private func planRow(
        plan: PaywallConfig.PlanConfig,
        isSelected: Bool,
        isHighlighted: Bool,
        accent: Color,
        badgeColor: Color,
        cardBackground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        if let old = plan.oldPrice {
                            Text(old)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .strikethrough()
                        }
                        Text(plan.priceText.isEmpty ? "Loading…" : plan.priceText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isHighlighted ? accent : .primary)
                    }
                }
                
                Spacer()
                
                if let badge = plan.badgeText {
                    Text(badge)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 10).fill(badgeColor))
                        .foregroundColor(.white)
                        .fixedSize()
                }
                
                // radio/check indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? accent : Color.secondary.opacity(0.5),
                                lineWidth: isSelected ? 6 : 1)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.leading, 8)
            }
            .padding()
            .background {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 12).stroke(accent, lineWidth: 2)
                } else {
                    cardBackground
                }
            }
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PaywallConfig (with full defaults so you can omit args)
public struct PaywallConfig {
    public struct Feature: Identifiable {
        public let id = UUID()
        public var iconName: String
        public var text: String
        
        public init(iconName: String, text: String) {
            self.iconName = iconName
            self.text = text
        }
    }
    
    public struct PlanConfig {
        public var title: String
        public var oldPrice: String?
        public var priceText: String
        public var badgeText: String?
        
        public init(title: String,
                    oldPrice: String? = nil,
                    priceText: String = "",
                    badgeText: String? = nil) {
            self.title = title
            self.oldPrice = oldPrice
            self.priceText = priceText
            self.badgeText = badgeText
        }
    }
    
    public var imageName: String
    public var headline: String
    public var features: [Feature]
    
    public var lifetimePlan: PlanConfig
    public var weeklyPlan: PlanConfig
    
    public var ctaText: String
    public var restoreText: String
    public var footerText: String
    
    public var accentColor: Color
    public var badgeColor: Color
    public var cardBackground: Color
    public var background: Color
    
    // ✅ Defaulted init so you can pass only what you want
    public init(
        imageName: String = "",
        headline: String = "Unlock",
        features: [Feature] = [],
        lifetimePlan: PlanConfig = .init(title: "Lifetime Access"),
        weeklyPlan: PlanConfig = .init(title: "Weekly Plan"),
        ctaText: String = "Continue",
        restoreText: String = "Restore",
        footerText: String = "Terms of Use & Privacy Policy",
        accentColor: Color = .blue,
        badgeColor: Color = .red,
        cardBackground: Color = Color(UIColor.secondarySystemBackground),
        background: Color = Color(UIColor.systemBackground)
    ) {
        self.imageName = imageName
        self.headline = headline
        self.features = features
        self.lifetimePlan = lifetimePlan
        self.weeklyPlan = weeklyPlan
        self.ctaText = ctaText
        self.restoreText = restoreText
        self.footerText = footerText
        self.accentColor = accentColor
        self.badgeColor = badgeColor
        self.cardBackground = cardBackground
        self.background = background
    }
}

// MARK: - Supporting types
private enum SelectedPlan {
    case lifetime, weekly
}

// MARK: - StoreController
@Observable @MainActor class StoreController {
    static let weeklyID = "product.id.echoAI.weekly"
    static let lifetimeID = "product.id.echoAI.lifetimeAccess"
    
    var isSubscribed: Bool = false
    var products: [Product] = []
    
    private let productIDs = [
        StoreController.weeklyID,
        StoreController.lifetimeID
    ]
    
    init() {
        Task {
            await fetchProducts()
            await checkSubscription()
            listenForTransactionUpdates()
        }
    }
    
    // Fetch products
    func fetchProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Error fetching products: \(error)")
        }
    }
    
    // Purchase
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await checkSubscription()
                case .unverified(_, let error):
                    print("Unverified purchase: \(error.localizedDescription)")
                }
            case .userCancelled:
                print("User cancelled the purchase.")
            case .pending:
                print("Purchase is pending.")
            @unknown default:
                print("Unknown purchase result.")
            }
        } catch {
            print("Purchase failed: \(error.localizedDescription)")
        }
    }
    
    // Entitlements check (covers auto-renewing subs and non-consumables)
    func checkSubscription() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               productIDs.contains(transaction.productID) {
                isSubscribed = true
                return
            }
        }
        isSubscribed = false
    }
    
    // Sync + Restore
    func sync() async {
        do {
            try await AppStore.sync()
        } catch {
            print("App Store sync failed: \(error.localizedDescription)")
        }
    }
    
    func restorePurchases() async {
        await sync()
        await checkSubscription()
    }
    
    private func listenForTransactionUpdates() {
        Task {
            for await verificationResult in Transaction.updates {
                switch verificationResult {
                case .verified(let transaction):
                    await transaction.finish()
                    await checkSubscription()
                case .unverified(_, let error):
                    print("Unverified transaction update: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Price helpers (localized)
    func displayName(for productID: String) -> String? {
        products.first(where: { $0.id == productID })?.displayName
    }
    
    
    func priceText(for productID: String) -> String? {
        guard let product = products.first(where: { $0.id == productID }) else { return nil }
        
        if let sub = product.subscription {
            let p = sub.subscriptionPeriod
            let period = periodText(unit: p.unit, value: p.value)
            return "\(product.displayPrice) / \(period)"
        } else {
            // Non-consumable (lifetime)
            return product.displayPrice
        }
    }
    
    private func periodText(unit: Product.SubscriptionPeriod.Unit, value: Int) -> String {
        let base: String
        switch unit {
        case .day: base = "day"
        case .week: base = "week"
        case .month: base = "month"
        case .year: base = "year"
        @unknown default: base = "period"
        }
        return value == 1 ? base : "\(value) \(base)s"
    }
}

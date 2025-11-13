import SwiftUI
import StoreKit

@Observable
@MainActor
final class IAPController {
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs = Set<String>()
    
    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    private var updateListenerTask: Task<Void, Error>?
    
    private let productIDs = [
        "com.olyevolutions.BibleChat.weekly",
        "com.olyevolutions.BibleChat.yearly",
        //        "com.olyevolutions.BibleChat.lifetime"
    ]
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed")
                }
            }
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
    
    func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify transaction")
            }
        }
        
        self.purchasedProductIDs = purchasedIDs
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}

// MARK: - Onboarding Models
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case features = 1
    //    case personalize = 2
    case paywall = 2
    
    var title: String {
        switch self {
        case .welcome: return "Welcome to Holy Bible Chat"
        case .features: return "Your Spiritual Journey"
            //        case .personalize: return "Personalize Your Experience"
        case .paywall: return "Start Now"
        }
    }
}

// MARK: - App Storage Keys
//enum AppStorageKeys {
//    static let hasCompletedOnboarding = "hasCompletedOnboarding"
//}

// MARK: - Main Onboarding View

// MARK: - Paywall View
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    
    let storeManager: IAPController
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Unlock Premium")
                        .font(.system(size: 32, weight: .bold))
                }
                .padding(.top, 40)
                
                // Premium features
                VStack(spacing: 20) {
                    PremiumFeature(icon: "message.badge.filled.fill", text: "Unlimited Bible Chat")
                    PremiumFeature(icon: "photo.fill.on.rectangle.fill", text: "Custom Backgrounds — personalize your Bible experience")
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                
                // Pricing options
                if storeManager.products.isEmpty {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(.vertical, 40)
                } else {
                    VStack(spacing: 12) {
                        ForEach(storeManager.products, id: \.id) { product in
                            PricingCard(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                onSelect: { selectedProduct = product }
                            )
                        }
                    }
                }
                
                // CTA Button
                Button {
                    if let product = selectedProduct ?? storeManager.products.first {
                        Task {
                            await purchaseProduct(product)
                        }
                    }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Start Now")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(16)
                }
                .disabled(isPurchasing || storeManager.products.isEmpty)
                
                HStack {
                    Button {
                        dismiss()
                        hasCompletedOnboarding = true
                    } label: {
                        Text("Not Now")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    
                    // Restore purchases
                    Button {
                        Task {
                            await restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Terms
                VStack(spacing: 8) {
                    Text("Cancel anytime. Auto-renews unless cancelled.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 16) {
                        Link("Terms of Service", destination: URL(string: "https://www.olyevolutions.com/terms-of-use")!)
                        Text("•")
                        Link("Privacy Policy", destination: URL(string: "https://www.olyevolutions.com/privacy-policy")!)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 32)
            }
            .padding(.horizontal)
            .background(ignoresSafeAreaEdges: .vertical)
        }
        .onAppear {
            if selectedProduct == nil {
                selectedProduct = storeManager.products.first
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func getPeriod() -> String {
        guard let product = selectedProduct else { return "period" }
        if product.id.contains("monthly") {
            return "month"
        } else if product.id.contains("yearly") {
            return "year"
        }
        return "period"
    }
    
    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        
        do {
            try await storeManager.purchase(product)
            hasCompletedOnboarding = true
            dismiss()
        } catch {
            errorMessage = "Purchase failed. Please try again."
            showError = true
        }
        
        isPurchasing = false
    }
    
    private func restorePurchases() async {
        isPurchasing = true
        
        await storeManager.restorePurchases()
        
        if storeManager.hasActiveSubscription {
            hasCompletedOnboarding = true
            dismiss()
        } else {
            errorMessage = "No previous purchases found."
            showError = true
        }
        
        isPurchasing = false
    }
}

struct PremiumFeature: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            
            Text(text)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    var badge: String? {
        if product.id.contains("yearly") {
            return "BEST VALUE"
        } else if product.id.contains("lifetime") {
            return "ONE-TIME"
        }
        return nil
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(uiColor: .secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}


struct AccessGate {
    @AppStorage("free_devotionals_used") private var freeDevotionalsUsed = 0
    @AppStorage("free_chat_messages_used") private var freeChatMessagesUsed = 0
    @AppStorage("free_bookmarks_used") private var freeBookmarksUsed = 0
    
    let storeManager: IAPController
    let presentPaywall: () -> Void
    
    public func canGenerateDevotional() -> Bool {
        if storeManager.hasActiveSubscription { return true }
        if freeDevotionalsUsed < 7 {
            freeDevotionalsUsed += 1
            return true
        } else {
            presentPaywall()
            return false
        }
    }
    
    public func canSendChatMessage() -> Bool {
        if storeManager.hasActiveSubscription { return true }
        if freeChatMessagesUsed < 7 {
            freeChatMessagesUsed += 1
            return true
        } else {
            presentPaywall()
            return false
        }
    }
    
    public func canBookmark() -> Bool {
        if storeManager.hasActiveSubscription { return true }
        // If you want to allow 0 free bookmarks:
        presentPaywall()
        return false
    }
}

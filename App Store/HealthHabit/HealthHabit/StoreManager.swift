import SwiftUI
import StoreKit
import SwiftData

// MARK: - Store Manager
@Observable
class StoreManager {
    static let shared = StoreManager()
    
    private let productID = "com.healthhabit.unlimitedgoals"
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    
    var hasUnlockedUnlimitedGoals: Bool {
        purchasedProductIDs.contains(productID)
    }
    
    private var updateListenerTask: Task<Void, Never>?
    
    init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    @MainActor
    func loadProducts() async {
        do {
            products = try await Product.products(for: [productID])
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    func checkVerified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    @MainActor
    func updatePurchasedProducts() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.revocationDate == nil {
                    purchasedProductIDs.insert(transaction.productID)
                } else {
                    purchasedProductIDs.remove(transaction.productID)
                }
            } catch {
                print("Failed to update products: \(error)")
            }
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
}

enum StoreError: Error {
    case failedVerification
}

// MARK: - Paywall View
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    private let store = StoreManager.shared
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var product: Product? {
        store.products.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "heart.gauge.open")
                            .font(.system(size: 80))
                            .foregroundStyle(.green)
                        
                        Text("Unlock Unlimited Goals")
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                        
                        Text("Go beyond 2 goals and track as many health activities as you want!")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(
                            icon: "infinity.circle.fill",
                            title: "Unlimited Goals",
                            description: "Create as many health goals as you need"
                        )
                        
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                            title: "Track Everything",
                            description: "Monitor steps, distance, workouts, and more"
                        )
                        
                        FeatureRow(
                            icon: "checkmark.seal.fill",
                            title: "One-Time Purchase",
                            description: "Pay once, own forever. No subscriptions!"
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Price Card
                    if let product = product {
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Unlimited Goals")
                                        .font(.headline)
                                    Text("One-time purchase")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(product.displayPrice)
                                    .font(.title2.bold())
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // Error message
                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Purchase buttons
                    VStack(spacing: 12) {
                        if let product = product {
                            Button {
                                Task {
                                    await purchaseProduct(product)
                                }
                            } label: {
                                Group {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Unlock for \(product.displayPrice)")
                                    }
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green)
                                .cornerRadius(16)
                            }
                            .disabled(isPurchasing)
                        } else {
                            ProgressView()
                        }
                        
                        Button {
                            Task {
                                isPurchasing = true
                                await store.restorePurchases()
                                isPurchasing = false
                                if store.hasUnlockedUnlimitedGoals {
                                    dismiss()
                                }
                            }
                        } label: {
                            Text("Restore Purchase")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .disabled(isPurchasing)
                        
                        HStack(spacing: 24) {
                            Link("Privacy Policy", destination: URL(string: "https://www.olyevolutions.com/privacy-policy")!)
                            Link("Terms of Use", destination: URL(string: "https://www.olyevolutions.com/terms-of-use")!)
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        showError = false
        
        do {
            if let transaction = try await store.purchase(product) {
                print("Purchase successful: \(transaction.productID)")
                dismiss()
            }
        } catch {
            showError = true
            errorMessage = "Purchase failed. Please try again."
            print("Purchase failed: \(error)")
        }
        
        isPurchasing = false
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Upgrade Prompt Card
struct UpgradePromptCard: View {
    @Binding var showingPaywall: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.gauge.open")
                    .font(.title)
                    .foregroundStyle(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Want More Goals?")
                        .font(.headline)
                    Text("Unlock unlimited goals with a one-time purchase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Button {
                showingPaywall = true
            } label: {
                Text("Unlock Unlimited")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.green)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Preview
#Preview("Paywall") {
    PaywallView()
}

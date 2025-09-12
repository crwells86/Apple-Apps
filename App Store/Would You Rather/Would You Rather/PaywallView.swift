import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionController.self) var subscriptionController
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header
                Text("Unlock All the Spicy Fun")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Upgrade to premium and get exclusive access to more decks, custom decks, and exciting timed challenges. Perfect for couples, friends, and party nights!")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // MARK: - Feature List
                VStack(alignment: .leading, spacing: 16) {
                    PaywallFeature(symbol: "flame.fill", text: "Unlock juicy, funny, and naughty question decks")
                    PaywallFeature(symbol: "pencil.tip", text: "Create your own custom decks")
                    PaywallFeature(symbol: "timer", text: "Add timed choices and daring challenges")
                }
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [.pink, .orange]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // MARK: - Subscription Options
                VStack(spacing: 16) {
                    ForEach(subscriptionController.products) { product in
                        Button {
                            Task {
                                await subscriptionController.purchase(product)
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .strokeBorder(product.id.contains("yearly") ? Color.clear : Color.gray, lineWidth: 1)
                                    .background(Circle().fill(product.id.contains("yearly") ? Color.pink : Color.clear))
                                    .frame(width: 20, height: 20)
                                
                                Text(product.displayName)
                                    .font(.headline)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(product.displayPrice)
                                        .font(.headline)
                                }
                            }
                            .padding()
                            .background(product.id.contains("yearly") ? Color.pink.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // MARK: - CTA Button
                Button {
                    Task {
                        if let product = subscriptionController.products.first {
                            await subscriptionController.purchase(product)
                        }
                    }
                } label: {
                    Text("Subscribe Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(12)
                }
                .padding(.top)
                
                // MARK: - Restore / Legal
                Button("Restore Purchases") {
                    Task {
                        await subscriptionController.restorePurchases()
                    }
                }
                .font(.footnote)
                .foregroundColor(.blue)
                .padding(.top)
                
                Text("Subscriptions auto-renew unless canceled at least 24 hours before the period ends. Manage or cancel anytime in your device Settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                HStack(spacing: 24) {
                    Link("Privacy Policy", destination: URL(string: "https://github.com/crwells86/Privacy-Policy")!)
                    Link("Terms of Use", destination: URL(string: "https://github.com/crwells86/Terms-of-Use")!)
                }
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top)
            }
            .padding()
        }
    }
}

// MARK: - Feature Row View
private struct PaywallFeature: View {
    let symbol: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 24)
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PaywallView()
}


import StoreKit

@Observable @MainActor class SubscriptionController {
    var isSubscribed: Bool = false
    var products: [Product] = []
    
    private let entitlementID = "Spicy+"
    private let productIDs = ["com.spicy.weekly", "com.spicy.yearly"]
    
    init() {
        Task {
            await fetchProducts()
            await checkSubscription()
            listenForTransactionUpdates()
        }
    }
    
    func fetchProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Error fetching products: \(error)")
        }
    }
    
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
    
    func checkSubscription() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               productIDs.contains(transaction.productID) {
                isSubscribed = true
                return
            }
        }
        isSubscribed = false
    }
    
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
            for await verificationResult in StoreKit.Transaction.updates {
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
}

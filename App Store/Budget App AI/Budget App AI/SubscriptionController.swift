import StoreKit

@Observable @MainActor class SubscriptionController {
    var isSubscribed: Bool = false
    var products: [Product] = []
    
    private let entitlementID = "AI Budget+"
    private let productIDs = ["com.budget.weekly", "com.budget.yearly"]
    
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
        for await result in Transaction.currentEntitlements {
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
}



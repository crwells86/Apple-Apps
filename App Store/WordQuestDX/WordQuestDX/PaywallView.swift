import SwiftUI
import StoreKit

import SwiftUI
import StoreKit

@Observable
class StoreController {
    private let productID = "product.id.wordQuestUnlimited"
    
    var product: Product?
    var purchased: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    
    init() {
        // Fetch product and update current purchase status
        Task {
            await fetchProduct()
            await updatePurchasedStatus()
        }
        
        // Continuously listen for transaction updates
        Task {
            for await result in Transaction.updates {
                await handle(transactionResult: result)
            }
        }
    }
    
    @MainActor
    func fetchProduct() async {
        do {
            isLoading = true
            let storeProducts = try await Product.products(for: [productID])
            product = storeProducts.first
        } catch {
            errorMessage = "Failed to load product."
        }
        isLoading = false
    }
    
    @MainActor
    func purchase() async {
        guard let product else { return }
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                await handle(transactionResult: verification)
                
            case .userCancelled:
                // Optional: Handle cancellation if needed
                break
                
            case .pending:
                // Optional: Handle pending transactions
                break
                
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed."
        }
    }
    
    @MainActor
    private func handle(transactionResult: VerificationResult<StoreKit.Transaction>) async {
        switch transactionResult {
        case .verified(let transaction):
            if transaction.productID == productID {
                purchased = true
            }
            // Finish the transaction
            await transaction.finish()
            
        case .unverified(_, _):
            errorMessage = "Purchase could not be verified."
        }
    }
    
    @MainActor
    func updatePurchasedStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID {
                purchased = true
                return
            }
        }
        purchased = false
    }
    
    @MainActor
    func restorePurchases() async {
        await updatePurchasedStatus()
    }
}


import SwiftUI

struct PaywallView: View {
    @Binding var isPlaying: Bool
    @Bindable var store: StoreController
    
    @State private var isExpanded: Bool = false
    @Namespace private var namespace
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.orange, .pink],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Button {
                        isPlaying = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                    }
                    .buttonStyle(.glass)
                    
                    Spacer()
                }
                
                Spacer(minLength: 20)
                
                TitleScreenView()
                
                Text("Unlock Endless Word Adventures")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Generate unlimited puzzles and hints—your world of words awaits!")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.yellow)
                        Text("Unlimited fresh puzzles")
                            .foregroundColor(.white)
                            .font(.body)
                        Spacer()
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.yellow)
                            .offset(y: 4)
                        Text("Create custom puzzles from your own prompts")
                            .foregroundColor(.white)
                            .font(.body)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.yellow)
                        Text("Unlimited helpful hints")
                            .foregroundColor(.white)
                            .font(.body)
                        Spacer()
                    }
                }
                
                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding()
                } else if let product = store.product {
                    VStack {
                        Button {
                            Task { await store.purchase() }
                        } label: {
                            Text("\(product.displayPrice) one-time purchase")
                                .font(.headline.bold())
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 12))
                                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.vertical)
                        
                        
                        Button("Restore Purchases") {
                            Task {
                                await store.restorePurchases()
                            }
                        }
                        .padding(.bottom)
                        
                        
                        HStack(spacing: 24) {
                            Link("Privacy Policy", destination: URL(string: "https://github.com/crwells86/Privacy-Policy")!)
                            Link("Terms of Use", destination: URL(string: "https://github.com/crwells86/Terms-of-Use")!)
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    }
                }
                
                if let error = store.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}


//#Preview {
//    PaywallView(store: StoreController())
//}

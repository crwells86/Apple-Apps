import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionController.self) var subscriptionController
    @State private var selectedProduct: Product?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                
                // MARK: - Header
                VStack(spacing: 12) {
                    Text("Take Control of Your Money")
                        .font(.system(size: 30, weight: .bold))
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // MARK: - Feature Card
                VStack(alignment: .leading, spacing: 16) {
                    PaywallFeature(symbol: "chart.bar.xaxis", text: "Track spending with smart categories")
                    PaywallFeature(symbol: "mic.fill", text: "Add expenses with your voice")
                    PaywallFeature(symbol: "creditcard.fill", text: "Auto-import Apple Card & Apple Cash")
                    PaywallFeature(symbol: "calendar", text: "Manage bills & recurring expenses")
                    PaywallFeature(symbol: "lock.shield", text: "Private & offline — no accounts, no ads")
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                                
                // MARK: - Product Selection
                VStack(spacing: 12) {
                    ForEach(subscriptionController.products, id: \.id) { product in
                        productCard(product)
                    }
                }
                .padding(.horizontal)
                
                // MARK: - CTA
                Button {
                    Task {
                        if let product = selectedProduct {
                            await subscriptionController.purchase(product)
                        }
                    }
                } label: {
                    Text(selectedProduct == nil
                         ? "Select a Plan"
                         : "Unlock for \(selectedProduct!.displayPrice)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedProduct == nil ? Color.gray : Color.green)
                    .cornerRadius(14)
                }
                .disabled(selectedProduct == nil)
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.2), value: selectedProduct)
                
                // MARK: - Restore
                Button("Restore Purchases") {
                    Task {
                        await subscriptionController.restorePurchases()
                    }
                }
                .font(.footnote)
                .foregroundColor(.blue)
                
                // MARK: - Footer
                VStack(spacing: 8) {
                    Text(footerText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 20) {
                        Link("Privacy", destination: URL(string: "https://github.com/crwells86/Privacy-Policy")!)
                        Link("Terms", destination: URL(string: "https://github.com/crwells86/Terms-of-Use")!)
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                .padding(.bottom)
            }
            .padding()
        }
        .onAppear {
            // Default select lifetime if available
            selectedProduct = subscriptionController.products.first(where: {
                $0.id.contains("lifetime")
            }) ?? subscriptionController.products.first
        }
    }
    
    private var footerText: String {
        guard let product = selectedProduct else {
            return "Select a plan to continue."
        }
        
        if product.id.contains("lifetime") {
            return "One-time purchase. Lifetime access. No subscriptions."
        } else {
            return "Billed yearly. Cancel anytime in Settings."
        }
    }
    
    // MARK: - Product Card
    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let isLifetime = product.id.contains("lifetime")
        
        return Button {
            selectedProduct = product
        } label: {
            ZStack(alignment: .topTrailing) {
                
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .green : .gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.headline)
                        
                        if isLifetime {
                            Text("Pay once, use forever")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if product.type == .autoRenewable {
                            Text("Billed yearly")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(product.displayPrice)
                        .font(.headline)
                }
                .padding()
                .background(isSelected ? Color.green.opacity(0.15) : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                )
                .cornerRadius(14)
                
                // Badge
                if isLifetime {
                    Text("BEST VALUE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .offset(x: -4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Row
private struct PaywallFeature: View {
    let symbol: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundColor(.green)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

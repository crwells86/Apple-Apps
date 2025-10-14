import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionController.self) var subscriptionController
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header
                Text("Unlock Lifetime Access")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("One-time purchase. Unlock all features forever.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // MARK: - Feature List
                VStack(alignment: .leading, spacing: 16) {
                    PaywallFeature(symbol: "chart.bar.xaxis", text: "Access the Summary & Income tabs")
                    PaywallFeature(symbol: "mic.fill", text: "Voice-to-Expense entry")
                    PaywallFeature(symbol: "creditcard.fill", text: "Auto-import Apple Card & Apple Cash expenses")
                    //                    PaywallFeature(symbol: "dollarsign.circle", text: "Track income and auto-budget")
                    //                    PaywallFeature(symbol: "arrow.up.doc.fill", text: "Export reports to PDF")
                    PaywallFeature(symbol: "lock.shield", text: "Private & offline – no accounts, no ads")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                if let product = subscriptionController.products.first {
                    Button {
                        Task { await subscriptionController.purchase(product) }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text(product.displayName)
                                .font(.headline)
                            Spacer()
                            Text(product.displayPrice)
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                
                // MARK: - CTA Button
                Button {
                    Task {
                        if let product = subscriptionController.products.first {
                            await subscriptionController.purchase(product)
                        }
                    }
                } label: {
                    Text("Buy Lifetime Access")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
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
                
                Text("This is a one-time purchase. You can restore your purchase on a new device.")
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
                .foregroundColor(.green)
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

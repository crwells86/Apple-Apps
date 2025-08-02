import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionController.self) var subscriptionController
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header
                Text("Upgrade to Premium")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Track hours across jobs, manage unlimited shifts, and export work summaries for clients or employers.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // MARK: - Feature List
                VStack(alignment: .leading, spacing: 16) {
                    PaywallFeature(symbol: "briefcase.fill", text: "Track time across multiple jobs")
                    PaywallFeature(symbol: "clock", text: "Log unlimited shifts with ease")
                    PaywallFeature(symbol: "square.and.arrow.up.on.square", text: "Export your hours to PDF")
                }
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
                                    .background(Circle().fill(product.id.contains("yearly") ? Color.green : Color.clear))
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
                            .background(product.id.contains("yearly") ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
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
                
                Text("Subscriptions auto-renew unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in your device Settings.")
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

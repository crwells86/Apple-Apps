import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionController.self) var sub
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Unlock Premium – Get the Most Out of Budget App AI")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
//                    Text("You're Almost There!")
//                        .font(.title)
//                        .bold()
//                        .multilineTextAlignment(.center)
//                        .padding(.top)
//                    
//                    Text("You’ve reached the free limit for tracked expenses.")
//                        .font(.headline)
//                        .foregroundColor(.green)
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal)
                    
                    Text("Subscribe to unlock **unlimited expense tracking**, full access to **Premium Stats**, and all future features — totally offline, 100% private.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                VStack(spacing: 16) {
                    ForEach(sub.products) { product in
                        Button(action: {
                            Task {
                                await sub.purchase(product)
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 6) {
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
                                        if product.id.contains("yearly") {
                                            Text("Save 73%")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green)
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                .padding()
                                .background(product.id.contains("yearly") ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Button(action: {
                    Task {
                        if let product = sub.products.first {
                            await sub.purchase(product)
                        }
                    }
                }) {
                    Text("Subscribe Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .cornerRadius(12)
                }
                
                Button("Restore Purchases") {
                    Task {
                        await sub.restorePurchases()
                    }
                }
                .font(.footnote)
                .foregroundColor(.blue)
                .padding(.top)
                
                Text("Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period.")
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

#Preview {
    PaywallView()
}

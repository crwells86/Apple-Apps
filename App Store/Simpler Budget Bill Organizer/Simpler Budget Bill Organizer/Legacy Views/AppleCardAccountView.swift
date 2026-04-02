import SwiftUI
import FinanceKit

struct AppleCardAccountView: View {
    @State private var appleCardAccount: AppleCardAccount? = nil
    @State private var isLoading: Bool = true
    @State private var error: Error? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let account = appleCardAccount {
                Text(account.displayName)
                    .font(.title2)
                    .bold()
                
                Text("Institution: \(account.institutionName)")
                Text("Credit Limit: \(formatCurrency(account.creditInformation.creditLimit))")
                Text("Next Payment Due: \(formatDate(account.creditInformation.nextPaymentDueDate))")
                Text("Minimum Payment: \(formatCurrency(account.creditInformation.minimumNextPaymentAmount))")
                Text("Overdue Amount: \(formatCurrency(account.creditInformation.overduePaymentAmount))")
            } else if isLoading {
                ProgressView("Loading Apple Card Info...")
            } else if let error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            } else {
                Text("Apple Card account not found.")
            }
        }
        .padding()
        .task {
            await loadAppleCardAccount()
        }
    }
    
    // MARK: - Data Loading
    private func loadAppleCardAccount() async {
        do {
            let status = try await FinanceStore.shared.requestAuthorization()
            print("FinanceKit authorization status: \(status)")
            
            guard status == .authorized else {
                await MainActor.run {
                    self.isLoading = false
                }
                return
            }
            
            let accounts = try await FinanceStore.shared.accounts(query: AccountQuery())
            
            for account in accounts {
                switch account {
                case .liability(let liabilityAccount):
                    if liabilityAccount.displayName == "Apple Card" {
                        let creditInfo = CreditInformation(
                            creditLimit: liabilityAccount.creditInformation.creditLimit.map {
                                CurrencyAmount(amount: $0.amount, currencyCode: $0.currencyCode)
                            },
                            nextPaymentDueDate: liabilityAccount.creditInformation.nextPaymentDueDate ?? Date(),
                            minimumNextPaymentAmount: liabilityAccount.creditInformation.minimumNextPaymentAmount.map {
                                CurrencyAmount(amount: $0.amount, currencyCode: $0.currencyCode)
                            },
                            overduePaymentAmount: liabilityAccount.creditInformation.overduePaymentAmount.map {
                                CurrencyAmount(amount: $0.amount, currencyCode: $0.currencyCode)
                            }
                        )
                        
                        await MainActor.run {
                            self.appleCardAccount = AppleCardAccount(
                                id: liabilityAccount.id,
                                displayName: liabilityAccount.displayName,
                                accountDescription: liabilityAccount.accountDescription ?? "No description",
                                institutionName: liabilityAccount.institutionName,
                                currencyCode: liabilityAccount.currencyCode,
                                creditInformation: creditInfo,
                                openingDate: liabilityAccount.openingDate
                            )
                            self.isLoading = false
                        }
                        
                        return // ✅ Exit after finding Apple Card
                    }
                default:
                    break
                }
            }
            
            // No Apple Card found
            await MainActor.run {
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Formatters
    private func formatCurrency(_ amount: CurrencyAmount?) -> String {
        guard let amount else { return "–" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = amount.currencyCode
        return formatter.string(from: amount.amount as NSDecimalNumber) ?? "\(amount.amount)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

import SwiftUI
import FoundationModels

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @State private var storeManager = IAPController()
    private let model = SystemLanguageModel.default
    
    var body: some View {
        Group {
            switch model.availability {
            case .available:
                if hasCompletedOnboarding {
                    QuoteScreen()
                } else if !hasCompletedOnboarding {
                    OnboardingView()
                }
                
            case .unavailable(.deviceNotEligible):
                FreeBibleFeedView(modelContext: modelContext)
                
            case .unavailable(.appleIntelligenceNotEnabled):
                ContentUnavailableView(
                    "Apple Intelligence Disabled",
                    systemImage: "lock.iphone",
                    description: Text("Enable Apple Intelligence in Settings to unlock Bible Chat and daily devotionals.")
                )
                
            case .unavailable(.modelNotReady):
                ContentUnavailableView(
                    "Preparing Your Daily Devotional",
                    systemImage: "book.pages",
                    description: Text("The Bible model is loading. Please try again in a moment.")
                )
                
            case .unavailable:
                ContentUnavailableView(
                    "Bible Chat Unavailable",
                    systemImage: "book.closed",
                    description: Text("We’re unable to connect to the Bible model right now. Please try again soon.")
                )
            }
            
        }
        .task {
            await storeManager.updatePurchasedProducts()
        }
    }
}

#Preview {
    RootView()
}

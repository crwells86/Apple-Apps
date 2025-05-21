import SwiftUI

struct OnboardingPage: View {
    let image: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: image)
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text(title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    OnboardingPage(image: "chart.line.uptrend.xyaxis", title: "Know What You Need", description: "Add your bills once and instantly see how much you need to earn annually, monthly, weekly, or hourly.")
}

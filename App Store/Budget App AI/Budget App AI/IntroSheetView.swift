import SwiftUI

struct IntroSheetView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Spacer()
                
                Text("Welcome to\nBudget App AI")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    Text("Try saying:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        Text("“I spent twelve dollars and ninety-nine cents at Starbucks”")
                        Text("“Fifty-five dollars and eighty-seven cents at Costco”")
                        Text("“Dropped five dollars and sixty cents on lunch”")
                        Text("“Spent twenty-two dollars and forty cents at Target”")
                        Text("“Groceries, thirty-two dollars and seventy-five cents”")
                    }
                    .font(.body)
                    .italic()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.vertical)
                
                // Feature Descriptions
                VStack(alignment: .leading, spacing: 16) {
                    Label("Track expenses with your voice", systemImage: "mic.fill")
                    Label("Automatically extract amount and vendor", systemImage: "creditcard.fill")
                    Label("See your budget and spending by timeframe", systemImage: "calendar")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Text("Get Started")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                }
            }
            .padding()
        }
    }
}

#Preview {
    IntroSheetView(onDismiss: {})
}

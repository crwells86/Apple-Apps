import SwiftUI

struct OnboardingView: View {
    @State private var inputAge = ""
    let onContinue: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack {
                Text("Welcome to ETD")
                    .font(.largeTitle)
                    .bold()
                
                Text("Estimated Time of Death")
                    .font(.title3)
                    .underline()
            }
            
            Text("Enter your age to get started")
                .font(.title3)
            
            TextField("Your age", text: $inputAge)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Button("Continue") {
                if let age = Int(inputAge), age > 0 {
                    onContinue(age)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    OnboardingView(onContinue: { _ in })
}

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text(greetings())
            .font(.largeTitle)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
    }
    
    private func greetings() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 0..<12:
            return "Good morning!"
        case 12..<18:
            return "Good afternoon!"
        default:
            return "Good evening!"
        }
    }
}

#Preview {
    ContentView()
}

import SwiftUI
import Translation

struct ContentView: View {
    private let text = "Hello, world!"
    @State private var isTranslatingShowing = false
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            Text(text)
                .translationPresentation(isPresented: $isTranslatingShowing, text: text)
            
            Button {
                isTranslatingShowing.toggle()
            } label: {
                Text("Translate")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

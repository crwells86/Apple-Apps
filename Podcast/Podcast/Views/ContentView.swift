import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            TabView {
                Tab("Home", systemImage: "house") {
                    HomeScrollView()
                }
                
                Tab("Browse", systemImage: "rectangle.grid.2x2.fill") {
                    Text("Browse")
                }
                
                Tab("Library", systemImage: "play.square.stack.fill") {
                    Text("Library")
                }
                
                Tab("Search", systemImage: "magnifyingglass") {
                    Text("Search")
                }
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
}

import SwiftUI

@main
struct WordQuestDXApp: App {
    @State private var storeController = StoreController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .statusBarHidden()
                .environment(storeController)
        }
    }
}

import SwiftUI

@main
struct Grocery_List_MakerApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    \.managedObjectContext,
                    persistenceController.container.viewContext
                )
        }
    }
}

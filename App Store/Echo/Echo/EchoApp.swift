import SwiftUI
import SwiftData

@main
struct EchoApp: App {
    @State private var storeController = StoreController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Recording.self,
            Transcription.self,
            Summary.self,
            Speaker.self,
            SpeakerSegment.self,
            Tag.self
        ])
        .environment(storeController)
    }
}

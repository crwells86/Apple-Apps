import SwiftUI
import SwiftData

@main
struct BibleChatApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .statusBarHidden()
        }
        .modelContainer(for: [
            Devotional.self,
            ChatMessage.self,
            UserProgress.self,
            BookmarkedVerse.self,
            VerseComment.self,
            UserProfile.self,
            FavoriteScripture.self
        ])
    }
}

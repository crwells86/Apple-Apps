import SwiftUI

struct PodcastScrollView: View {
    let podcasts: [Podcast]
    let episodes: [Episode]
    let controller: PodcastNetworkController
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            PodcastLazyHStack(podcasts: podcasts,
                              episodes: episodes,
                              controller: controller)
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(16, for: .scrollContent)
        .frame(height: 320)
    }
}

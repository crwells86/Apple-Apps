import SwiftUI

struct PodcastLazyHStack: View {
    let podcasts: [Podcast]
    let episodes: [Episode]
    let controller: PodcastNetworkController
    
    var body: some View {
        LazyHStack(spacing: 16) {
            ForEach(podcasts) { show in
                let episode = episodes.first(where: { $0.collectionId == show.id })
                PodcastItemView(show: show, episode: episode, controller: controller)
            }
        }
        .scrollTargetLayout()
    }
}

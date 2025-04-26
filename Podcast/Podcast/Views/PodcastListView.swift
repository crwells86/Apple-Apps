import SwiftUI

struct PodcastListView: View {
    @State private var controller = PodcastNetworkController()
    
    var body: some View {
        PodcastScrollView(podcasts: controller.availablePodcasts,
                          episodes: controller.loadedEpisodes,
                          controller: controller)
        .task {
            await controller.fetchAvailablePodcasts()
        }
    }
}

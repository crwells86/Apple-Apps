import SwiftUI

struct PodcastOverlayView: View {
    let show: Podcast
    let episode: Episode?
    let controller: PodcastNetworkController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(show.collectionName ?? "")
                .lineLimit(2)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(episode?.trackName ?? "?")
            
            EpisodeControlsView(show: show,
                                episode: episode,
                                controller: controller)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

import SwiftUI

struct PodcastItemView: View {
    let show: Podcast
    let episode: Episode?
    let controller: PodcastNetworkController
    
    var body: some View {
        if let artURL = show.artworkUrl100 {
            ThumbnailAsyncImage(url: artURL, height: 160)
                .frame(height: 320)
                .overlay(alignment: .bottom) {
                    PodcastOverlayView(show: show,
                                       episode: episode,
                                       controller: controller)
                }
                .containerRelativeFrame(.horizontal, count: 6, span: 4, spacing: 0)
        } else {
            Text(show.collectionName ?? "Unknown")
                .frame(maxWidth: .infinity, minHeight: 320)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)
        }
    }
}

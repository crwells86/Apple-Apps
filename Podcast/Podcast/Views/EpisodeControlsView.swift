import SwiftUI

struct EpisodeControlsView: View {
    let show: Podcast
    let episode: Episode?
    let controller: PodcastNetworkController
    
    var body: some View {
        HStack {
            Button {
                controller.playEpisodePreview(forPodcastId: show.id)
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    if let millis = episode?.trackTimeMillis {
                        Text(millis.podcastDurationString)
                    } else {
                        Text("…")
                    }
                }
            }
            .foregroundColor(.primary)
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color.gray.opacity(0.2), in: Capsule())
            .task(id: show.id) {
                await controller.fetchLatestEpisode(forPodcastId: show.id)
            }
            
            Spacer()
            
            Button {
                //
            } label: {
                Image(systemName: "arrowshape.down.circle.fill")
                    .font(.system(size: 14, weight: .light))
            }
            .foregroundStyle(.primary)
            
            Button {
                //
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .black))
            }
            .foregroundStyle(.primary)
        }
    }
}

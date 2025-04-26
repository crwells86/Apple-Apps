import Foundation
import AVKit

@Observable class PodcastNetworkController {
    var availablePodcasts: [Podcast] = []
    var loadedEpisodes: [Episode] = []
    var audioPlayer: AVPlayer?
    
    func fetchAvailablePodcasts() async {
        let podcastNames = [
            "NPR Short Wave",
            "NPR Throughline",
            "merriam-webster",
            "the Ezra Klein Show"
        ]
        
        var fetchedPodcasts: [Podcast] = []
        
        for podcastName in podcastNames {
            do {
                if let podcast = try await fetchTopPodcastMatchingTerm(searchTerm: podcastName) {
                    fetchedPodcasts.append(podcast)
                }
            } catch {
                print("❌ Podcast search for “\(podcastName)” failed:", error)
            }
        }
        
        availablePodcasts = fetchedPodcasts
    }
    
    private func fetchTopPodcastMatchingTerm(searchTerm: String) async throws -> Podcast? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "itunes.apple.com"
        urlComponents.path = "/search"
        urlComponents.queryItems = [
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "term", value: searchTerm)
        ]
        
        let (responseData, response) = try await URLSession.shared.data(from: urlComponents.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let searchResult = try jsonDecoder.decode(PodcastSearchResult.self, from: responseData)
        return searchResult.results.first
    }
    
    func fetchLatestEpisode(forPodcastId podcastId: Int) async {
        guard !loadedEpisodes.contains(where: { $0.collectionId == podcastId }) else { return }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "itunes.apple.com"
        urlComponents.path = "/lookup"
        urlComponents.queryItems = [
            URLQueryItem(name: "id", value: "\(podcastId)"),
            URLQueryItem(name: "entity", value: "podcastEpisode"),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        do {
            let (responseData, response) = try await URLSession.shared.data(from: urlComponents.url!)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else { return }
            
            let jsonDecoder = JSONDecoder()
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let lookupResult = try jsonDecoder.decode(EpisodeLookupResult.self, from: responseData)
            
            if let latestEpisode = lookupResult.results.first(where: { $0.previewUrl != nil }) {
                loadedEpisodes.append(latestEpisode)
            }
        } catch {
            print("🔴 Episode lookup failed:", error)
        }
    }
    
    func playEpisodePreview(forPodcastId podcastId: Int) {
        guard let matchingEpisode = loadedEpisodes.first(where: { $0.collectionId == podcastId }),
              let previewUrl = matchingEpisode.previewUrl
        else { return }
        
        audioPlayer?.pause()
        audioPlayer = AVPlayer(url: previewUrl)
        audioPlayer?.play()
    }
}

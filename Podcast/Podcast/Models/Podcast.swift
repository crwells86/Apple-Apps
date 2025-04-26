import Foundation

struct Podcast: Identifiable, Decodable {
    let trackId: Int
    let trackName: String?
    let collectionName: String?
    let artistName: String?
    let artworkUrl100: URL?
    let feedUrl: URL?
    var id: Int { trackId }
}

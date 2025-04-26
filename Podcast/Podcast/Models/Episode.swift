import Foundation

struct Episode: Identifiable, Decodable {
    let trackId: Int
    let trackName: String?
    let previewUrl: URL?
    let trackTimeMillis: Int?
    let collectionId: Int?
    var id: Int { trackId }
}

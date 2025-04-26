struct PodcastSearchResult: Decodable {
    let resultCount: Int
    let results: [Podcast]
}

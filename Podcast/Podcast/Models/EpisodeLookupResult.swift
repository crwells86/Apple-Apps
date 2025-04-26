struct EpisodeLookupResult: Decodable {
    let resultCount: Int
    let results: [Episode]
}

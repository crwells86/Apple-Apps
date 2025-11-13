struct BibleData: Codable {
    let version: String
    let testaments: [Testament]
}

struct Testament: Codable {
    let name: String
    let books: [Book]
}

struct Book: Codable {
    let name: String
    let fullName: String
    let chapters: [Chapter]
}

struct Chapter: Codable {
    let chapter: Int
    let verses: [Verse]
}

struct Verse: Codable {
    let verse: Int
    let text: String
}

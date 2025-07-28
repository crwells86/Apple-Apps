extension Character {
    var isEmoji: Bool {
        unicodeScalars.first?.properties.isEmojiPresentation == true ||
        unicodeScalars.contains(where: { $0.properties.isEmoji })
    }
}

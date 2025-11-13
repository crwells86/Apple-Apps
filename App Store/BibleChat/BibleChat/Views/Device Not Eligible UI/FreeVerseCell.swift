import SwiftUI

struct FreeVerseCell: View {
    let verse: Verse
    let book: Book
    let chapter: Chapter
    let isBookmarked: Bool
    let onBookmark: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Verse number badge
                Text("\(verse.verse)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.gradient)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 8) {
                    // Verse text
                    Text(verse.text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.primary)
                    
                    // Action buttons
                    HStack(spacing: 32) {
                        Button(action: onBookmark) {
                            Label("Save", systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.subheadline)
                                .foregroundStyle(isBookmarked ? .blue : .secondary)
                        }
                        
                        ShareLink(
                            item: "\"\(verse.text)\"\n\n\(book.name) \(chapter.chapter):\(verse.verse)"
                            //\n\nGet the app: https://apps.apple.com/us/app/holy-bible-chat/id6754623202"
                        ) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

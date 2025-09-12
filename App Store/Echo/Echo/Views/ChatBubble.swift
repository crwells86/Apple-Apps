import SwiftUI

struct ChatBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if message.isThinking {
                            ThinkingChatAI()
                } else {
                    Text(message.text)
                        .padding()
                        .background(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 16,
                                bottomLeadingRadius: !message.isUser ? 0 : 16,
                                bottomTrailingRadius: message.isUser ? 0 : 16,
                                topTrailingRadius: 16,
                                style: .continuous
                            )
                            .fill(message.isUser ? Color.accentColor : Color.secondary)
                            .glassEffect(.clear, in: UnevenRoundedRectangle(
                                topLeadingRadius: 16,
                                bottomLeadingRadius: !message.isUser ? 0 : 16,
                                bottomTrailingRadius: message.isUser ? 0 : 16,
                                topTrailingRadius: 16,
                                style: .continuous
                            ))
                        )
                    
                    Text(message.time)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(message.isUser ? .trailing : .leading, 8)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                HStack {
                    if !message.isUser && !message.isThinking {
                        Spacer()

                        Button {
                            UIPasteboard.general.string = message.text
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption)
                        }

                        ShareLink(item: message.text) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.caption)
                        }
                    }
                }
                .padding(.trailing)
                .offset(y: 4)
            }
            .padding(.bottom)
            
            if !message.isUser { Spacer() }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}

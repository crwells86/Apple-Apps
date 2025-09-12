import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    var onSend: () -> Void
    
    var body: some View {
        HStack {
            TextField("Write somethings", text: $text)
                .textFieldStyle(.roundedBorder)
            
            Button {
                onSend()
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.accentColor)
                    .padding(8)
            }
        }
        .padding(.horizontal)
    }
}

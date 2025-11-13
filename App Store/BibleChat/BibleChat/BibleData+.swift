import SwiftUI
import FoundationModels
import SwiftData



// MARK: - Controller
import SwiftUI
import SwiftData



// MARK: - Chat Sheet (Controller-driven)
struct ChatSheet: View {
    let controller: BibleController
    let verseText: String
    @State private var question = ""
    @State private var isSending = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Ask about this verse")
                .font(.headline)
                .padding(.top)
            
            TextEditor(text: $question)
                .frame(height: 120)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                .padding(.horizontal)
                .onAppear { question = verseText }
            
            Button {
                Task {
                    isSending = true
                    await controller.sendQuestion(question)
                    isSending = false
                }
            } label: {
                if isSending {
                    ProgressView()
                } else {
                    Text("Send")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .presentationDetents([.medium, .large])
    }
}

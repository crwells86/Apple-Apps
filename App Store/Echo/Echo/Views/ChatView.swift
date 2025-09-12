//import SwiftUI
//import FoundationModels
//
//struct ChatView: View {
//    @Environment(\.dismiss) private var dismiss
////    let controller: AIController
//    
//    @State private var controller = AIController(session: LanguageModelSession())
//    @Binding var recording: Recording
//    
//    @State private var inputText: String = ""
//    @FocusState private var isTextFieldFocused: Bool
//    @State private var isThinking = false
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                ScrollViewReader { proxy in
//                    ScrollView {
//                        VStack(spacing: 12) {
//                            ForEach(controller.messages) { message in
//                                ChatBubble(message: message)
//                                    .id(message.id)
//                            }
//                            
//                            if isThinking {
//                                ThinkingChatAI()
//                                    .id("thinking-bubble")
//                            }
//                            
//                            Spacer().frame(height: 8)
//                        }
//                        .padding(.vertical, 12)
//                        .padding(.horizontal, 10)
//                    }
//                    .onChange(of: controller.messages.count) {
//                        DispatchQueue.main.async {
//                            if let last = controller.messages.last {
//                                withAnimation(.easeOut) {
//                                    proxy.scrollTo(last.id, anchor: .bottom)
//                                }
//                            }
//                        }
//                    }
//                }
//                
//                Divider()
//                
//                MessageInputView(text: $inputText) {
//                    sendMessage()
//                }
//                .padding(.horizontal)
//                .padding(.vertical, 8)
//            }
//            .navigationTitle("AI Chat")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Done") { dismiss() }
//                }
//            }
//            .onTapGesture { isTextFieldFocused = false }
//        }
//    }
//    
////    private func sendMessage() {
////        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
////        guard !trimmed.isEmpty else { return }
////        inputText = ""
////        isTextFieldFocused = false
////        
////        controller.messages.append(
////            Message(text: "Thinking of a reply", isUser: false, time: "\(Date())", isThinking: true)
////        )
////        
////        Task {
////            do {
////                try await controller.chat(question: trimmed)
////                
////                // remove the "thinking" placeholder
////                if let index = controller.messages.firstIndex(where: { $0.isThinking }) {
////                    controller.messages.remove(at: index)
////                }
////                
////                // controller already added the response, no need to append
////            } catch {
////                print("chat failed:", error)
////            }
////        }
////        
////    }
//    
//    private func sendMessage() {
//        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty else { return }
//        inputText = ""
//        isTextFieldFocused = false
//        
//        // Add only the user's question as a visible chat message
//        controller.messages.append(
//            Message(text: trimmed, isUser: true, time: "\(Date())", isThinking: true)
//        )
//        
//        // Add "thinking" bubble for AI
//        controller.messages.append(
//            Message(text: "Thinking of a reply", isUser: false, time: "\(Date())", isThinking: true)
//        )
//        
//        Task {
//            do {
//                // Prepare context for AI (transcript + question)
//                let transcript = recording.transcription?.text ?? String(recording.text.characters)
//                let contextualPrompt = """
//                Context:
//                \(transcript)
//
//                Question:
//                \(trimmed)
//                """
//                
//                try await controller.chat(question: contextualPrompt)
//                
//                // Remove the "thinking" placeholder once AI responds
//                if let index = controller.messages.firstIndex(where: { $0.isThinking }) {
//                    controller.messages.remove(at: index)
//                }
//                
//                // The controller should append the AI's response as a normal message
//            } catch {
//                print("chat failed:", error)
//            }
//        }
//    }
//}


import SwiftUI
import FoundationModels

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var controller = AIController(session: LanguageModelSession())
    @Binding var recording: Recording
    
    @State private var inputText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var isThinking = false
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(controller.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isThinking {
                                ThinkingChatAI()
                                    .id("thinking-bubble")
                            }
                            
                            Spacer().frame(height: 8)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 10)
                    }
                    // 👇 Scroll when messages change OR thinking toggles
                    .onChange(of: controller.messages.count) {
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: isThinking) {
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                Divider()
                
                MessageInputView(text: $inputText) {
                    sendMessage()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .navigationTitle("AI Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onTapGesture { isTextFieldFocused = false }
            .onAppear {
                if let transcript = recording.transcription?.text {
                    controller.loadTranscript(transcript)
                }
            }
        }
    }
    
    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        inputText = ""
        isTextFieldFocused = false
        
        isThinking = true
        
        Task {
            do {
                try await controller.chat(question: trimmed)
            } catch {
                print("chat failed:", error)
            }
            
            isThinking = false
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut) {
                if isThinking {
                    proxy.scrollTo("thinking-bubble", anchor: .bottom)
                } else if let last = controller.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}


//import SwiftUI
//import FoundationModels
//
//struct ChatView: View {
//    @Environment(\.dismiss) private var dismiss
//    
//    @State private var controller = AIController(session: LanguageModelSession())
//    @Binding var recording: Recording
//    
//    @State private var inputText: String = ""
//    @FocusState private var isTextFieldFocused: Bool
//    @State private var isThinking = false
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                ScrollViewReader { proxy in
//                    ScrollView {
//                        VStack(spacing: 12) {
//                            ForEach(controller.messages) { message in
//                                ChatBubble(message: message)
//                                    .id(message.id)
//                            }
//                            
//                            if isThinking {
//                                ThinkingChatAI()
//                                    .id("thinking-bubble")
//                            }
//                            
//                            Spacer().frame(height: 8)
//                        }
//                        .padding(.vertical, 12)
//                        .padding(.horizontal, 10)
//                    }
//                    .onChange(of: controller.messages.count) {
//                        DispatchQueue.main.async {
//                            if let last = controller.messages.last {
//                                withAnimation(.easeOut) {
//                                    proxy.scrollTo(last.id, anchor: .bottom)
//                                }
//                            }
//                        }
//                    }
//                }
//                
//                Divider()
//                
//                MessageInputView(text: $inputText) {
//                    sendMessage()
//                }
//                .padding(.horizontal)
//                .padding(.vertical, 8)
//            }
//            .navigationTitle("AI Chat")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Done") { dismiss() }
//                }
//            }
//            .onTapGesture { isTextFieldFocused = false }
//            .onAppear {
//                if let transcript = recording.transcription?.text {
//                    controller.loadTranscript(transcript)
//                }
//            }
//        }
//    }
//    
//    private func sendMessage() {
//        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty else { return }
//        inputText = ""
//        isTextFieldFocused = false
//        
//        // Add only the user's question as a visible chat message
//        controller.messages.append(
//            Message(text: trimmed, isUser: true, time: "\(Date())", isThinking: true)
//        )
//        
//        // Add "thinking" bubble for AI
//        controller.messages.append(
//            Message(text: "Thinking of a reply", isUser: false, time: "\(Date())", isThinking: true)
//        )
//        
//        Task {
//            do {
//                // 👇 Just send the raw user question
//                try await controller.chat(question: trimmed)
//                
//                // Remove the "thinking" placeholder once AI responds
//                if let index = controller.messages.firstIndex(where: { $0.isThinking }) {
//                    controller.messages.remove(at: index)
//                }
//            } catch {
//                print("chat failed:", error)
//            }
//        }
//    }
//}



import SwiftUI
import Combine

struct ThinkingChatAI: View {
    @State private var currentPhraseIndex = 0
    @State private var dotCount = 0
    @State private var thinking = false
    
    private let phraseTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let dotTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    let phrases = [
        "Thinking of a reply",
        "Forming a response",
        "Composing a message"
    ]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(EllipticalGradient(colors:[.blue, .indigo], center: .center, startRadiusFraction: 0.0, endRadiusFraction: 0.5))
                .phaseAnimator([false , true]) { ai, thinking in
                    ai
                        .symbolEffect(.wiggle.byLayer, value: thinking)
                        .symbolEffect(.bounce.byLayer, value: thinking)
                        .symbolEffect(.breathe.byLayer, value: thinking)
                }
            
            Text("\(phrases[currentPhraseIndex])\(String(repeating: ".", count: dotCount))")
                .foregroundStyle(.blue)
                .font(.callout)
        }
        .padding(10)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 16,
                topTrailingRadius: 16,
                style: .continuous
            )
            .glassEffect(.clear, in: UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 16,
                topTrailingRadius: 16,
                style: .continuous
            ))
        )
        .frame(width: 270)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { thinking = true }
        .onReceive(phraseTimer) { _ in
            withAnimation(.easeInOut) {
                currentPhraseIndex = (currentPhraseIndex + 1) % phrases.count
            }
        }
        .onReceive(dotTimer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}


#Preview {
    ThinkingChatAI()
}

















// MARK: - Mock AI Controller
//class MockAIController: ObservableObject {
//    @Published var messages: [Message] = []
//
//    // Mock chat function that simulates AI responses
//    func chat(question: String) async throws {
//        // simulate thinking delay
//        try await Task.sleep(nanoseconds: 1_000_000_000)
//
//        let response: String
//        switch question.lowercased() {
//        case let q where q.contains("launch"):
//            response = "The team discussed pushing the launch back by two weeks to give Sarah time to finalize the budget."
//        case let q where q.contains("budget"):
//            response = "Sarah is responsible for finalizing the budget numbers before sending notes to the team."
//        case let q where q.contains("competitor"):
//            response = "John was asked to start pulling competitor pricing models."
//        default:
//            response = "From the meeting transcript, that detail isn't mentioned directly, but we can check the notes later."
//        }
//
//        // append AI response
//        await MainActor.run {
////            messages.append(Message(text: response, isUser: false, time: "\(Date())"))
//        }
//    }
//}

// MARK: - Main Chat View
//import SwiftUI
//
//struct MockChatView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var controller = MockAIController()
//    @State private var inputText = ""
//    @FocusState private var isTextFieldFocused: Bool
//    @State private var isThinking = false
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                ScrollViewReader { proxy in
//                    ScrollView {
//                        VStack(spacing: 12) {
//                            ForEach(controller.messages) { message in
//                                ChatBubble(message: message)
//                                    .id(message.id)
//                            }
//                            if isThinking {
//                                ThinkingChatAI()
//                                    .id("thinking-bubble")
//                            }
//                            Spacer().frame(height: 8)
//                        }
//                        .padding(.vertical, 12)
//                        .padding(.horizontal, 10)
//                    }
//                    .onChange(of: controller.messages.count) { _ in
//                        if let last = controller.messages.last {
//                            withAnimation(.easeOut) {
//                                proxy.scrollTo(last.id, anchor: .bottom)
//                            }
//                        }
//                    }
//                }
//
//                Divider()
//
//                MessageInputView(text: $inputText) {
//                    sendMessage()
//                }
//                .padding(.horizontal)
//                .padding(.vertical, 8)
//            }
//            .navigationTitle("AI Chat")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Done") { dismiss() }
//                }
//            }
//            .onTapGesture { isTextFieldFocused = false }
//        }
//        .onAppear {
//            // preload some messages for demo
//            controller.messages = [
//                Message(text: "When is the launch scheduled?", isUser: true, time: "9:41 AM", isThinking: false),
//                Message(text: "The team is considering pushing the launch back by two weeks to ensure that all preparations are thoroughly completed and everyone has enough time to finalize their respective tasks.", isUser: false, time: "9:41 AM", isThinking: false),
//                Message(text: "Why do we need to delay it?", isUser: true, time: "9:41 AM", isThinking: false),
//                Message(text: "Delaying the launch allows Sarah to finalize the budget numbers properly, and ensures that the team can review and adjust any last-minute details without rushing. This should help avoid errors or omissions.", isUser: false, time: "9:41 AM", isThinking: false),
//                Message(text: "Got it. Who is handling competitor research?", isUser: true, time: "9:41 AM", isThinking: false),
//                Message(text: "John has been tasked with pulling competitor pricing models. He will compile a report that compares pricing and features, which will help the team make informed decisions before the launch.", isUser: false, time: "9:41 AM", isThinking: false),
//                Message(text: "Thanks! Any other action items?", isUser: true, time: "9:41 AM", isThinking: false),
//                Message(text: "Once Sarah finalizes the budget, the plan is to send out detailed notes to the whole team, outlining tasks, timelines, and responsibilities. This ensures everyone is aligned and knows their next steps.", isUser: false, time: "9:41 AM", isThinking: false),
//                Message(text: "Can you draft an email I can send to colleagues summarizing this?", isUser: true, time: "9:41 AM", isThinking: false),
//                Message(text: "Subject: Update on Launch Timeline and Action Items\n\nHi Team,\n\nWe are pushing the launch back by two weeks to allow sufficient time for finalizing the budget and reviewing all preparations. Sarah will finalize the budget, and John is compiling competitor pricing models for review.\n\nOnce the budget is finalized, detailed notes outlining responsibilities and timelines will be shared with everyone.\n\nThanks for your attention and cooperation.\n\nBest,\n[Your Name]", isUser: false, time: "9:41 AM", isThinking: false)
//            ]
//
//        }
//    }
//
//    private func sendMessage() {
//        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty else { return }
//
//        controller.messages.append(
//            Message(text: trimmed, isUser: true, time: "\(Date())", isThinking: false)
//        )
//
//        inputText = ""
//        isTextFieldFocused = false
//        isThinking = true
//
//        Task {
//            do {
//                try await controller.chat(question: trimmed)
//                await MainActor.run { isThinking = false }
//            } catch {
//                print("chat failed:", error)
//                await MainActor.run { isThinking = false }
//            }
//        }
//    }
//}

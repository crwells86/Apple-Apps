import Combine
import SwiftUI

struct ThinkingAI: View {
    @State private var currentPhraseIndex = 0
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State private var thinking: Bool = false
    
    let phrases = [
        "Analyzing text…",
        "Summarizing key points…",
        "Refining ideas…"
    ]
    
    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(EllipticalGradient(colors:[.blue, .indigo], center: .center, startRadiusFraction: 0.0, endRadiusFraction: 0.5))
                .phaseAnimator([false , true]) { ai, thinking in
                    ai
                        .symbolEffect(.wiggle.byLayer, value: thinking)
                        .symbolEffect(.bounce.byLayer, value: thinking)
                        .symbolEffect(.breathe.byLayer, value: thinking)
                }
            Spacer()
            HStack(spacing: 0) {
                ForEach(Array(phrases[currentPhraseIndex].enumerated()), id: \.offset) { index, letter in
                    Text(String(letter))
                        .foregroundStyle(.blue)
                        .hueRotation(.degrees(thinking ? 220 : 0))
                        .opacity(thinking ? 0 : 1)
                        .scaleEffect(thinking ? 1.5 : 1, anchor: .bottom)
                        .animation(.easeInOut(duration: 0.5).delay(1).repeatForever(autoreverses: false).delay(Double(index) / 20), value: thinking)
                }
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 90)
        .onAppear {
            thinking = true
        }
        .onReceive(timer) { _ in
            withAnimation {
                currentPhraseIndex = (currentPhraseIndex + 1) % phrases.count
            }
        }
    }
}




//let mockMeetingSummaries: [Summary] = [
//    Summary(text: "- Launch postponed two weeks to allow budget finalization."),
//    Summary(text: "- Sarah responsible for completing updated budget numbers."),
//    Summary(text: "- Notes will be shared with the entire team after budget is done."),
//    Summary(text: "- John tasked with researching competitor pricing models this week."),
//    Summary(text: "- Slides for Thursday’s presentation due Wednesday afternoon."),
//    Summary(text: "- Follow-up meeting scheduled for next Tuesday."),
//    Summary(text: "- Room booking to be confirmed today.")
//]

import SwiftUI
import SwiftData
import FoundationModels

struct SummarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // receive the same controller instance (binding) and the selected recording (binding)
//    let controller: AIController
    
    @State private var controller = AIController(session: LanguageModelSession())
    @Binding var recording: Recording
    
    @State private var isSummarizing = false
    @State private var didStart = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if isSummarizing && (recording.summaries.isEmpty) {
                        ThinkingAI()
                            .frame(maxHeight: .infinity, alignment: .center)
                    } else if recording.summaries.isEmpty {
                        // no summaries and not currently summarizing
                        Text("No summary available.")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(recording.summaries) { summary in
                            HStack(alignment: .top, spacing: 8) {
                                Text(summary.text)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if recording.summaries.isEmpty {
                        Button("Regenerate Summary") {
                            Task { await startSummarizationIfNeeded() }
                        }
                    }
                }
            }
            .onAppear {
                if let transcript = recording.transcription?.text {
                    controller.loadTranscript(transcript)
                }
            }
            // start summarization once when the view appears (or when recording changes)
            .task(id: recording.updatedAt) {
                await startSummarizationIfNeeded()
            }
        }
    }
    
    private func startSummarizationIfNeeded() async {
        guard !isSummarizing else { return }
        // If you want to allow summarizing even while not `isDone`, you can remove this guard.
        guard recording.isDone else { return }
        if !recording.summaries.isEmpty { return }
        
        isSummarizing = true
        defer { isSummarizing = false }
        
        let transcript = recording.transcription?.text ?? String(recording.text.characters)
        
        do {
            try await controller.summarize(prompt: transcript)
            
            // If controller didn't produce anything, fallback to local summarizer
            if controller.summaries.isEmpty {
                let bullets = quickLocalSummary(transcript)
                if !bullets.isEmpty {
                    let newSummary = Summary(text: bullets.joined(separator: "\n"))
                    await MainActor.run {
                        recording.summaries = [newSummary]
                        recording.updatedAt = .now
                        try? modelContext.save()
                    }
                }
            } else {
                await MainActor.run {
                    recording.summaries = controller.summaries
                    recording.updatedAt = .now
                    try? modelContext.save()
                }
            }
        } catch {
            // LLM failed: fallback to quick local summary
            let bullets = quickLocalSummary(transcript)
            let newSummary = Summary(text: bullets.joined(separator: "\n"))
            await MainActor.run {
                recording.summaries = [newSummary]
                recording.updatedAt = .now
                try? modelContext.save()
            }
            print("Summarization failed, used local fallback: \(error)")
        }
    }
    
    
    /// Small local summarizer: pick top N sentences by keyword frequency.
    private func quickLocalSummary(_ text: String, maxBullets: Int = 6) -> [String] {
        let separators = CharacterSet(charactersIn: ".!?;\n")
        let sentences = text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !sentences.isEmpty else { return [] }
        
        // Build simple frequency of non-stop words
        let stopwords = Set(["the","and","a","to","of","in","for","on","is","are","that","it","this","with","we","you","i"])
        var freq: [String: Int] = [:]
        for s in sentences {
            for token in s.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
                let t = String(token)
                if t.count > 2 && !stopwords.contains(t) {
                    freq[t, default: 0] += 1
                }
            }
        }
        
        // Score sentences by sum of token frequencies
        let scored = sentences.map { s -> (String, Int) in
            let score = s.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).reduce(0) { acc, token in
                acc + (freq[String(token)] ?? 0)
            }
            return (s, score)
        }.sorted { $0.1 > $1.1 }
        
        let picked = scored.prefix(maxBullets).map { $0.0 }
        return picked.map { "• \($0)" }
    }
}

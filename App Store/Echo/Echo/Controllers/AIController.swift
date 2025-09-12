import Foundation
import AVFAudio
import FoundationModels

// MARK: - RAG Store (in-memory)
private final class RAGStore {
    struct Chunk: Identifiable {
        let id = UUID()
        let text: String
        let role: Role
        let timestamp: Date
        let turn: Int
        enum Role { case user, assistant, system, transcript }
    }
    
    private(set) var chunks: [Chunk] = []
    private var turnCounter: Int = 0
    
    func add(text: String, role: Chunk.Role) {
        let newTurn = (role == .user || role == .assistant) ? (turnCounter + 1) : turnCounter
        if role == .user || role == .assistant { turnCounter = newTurn }
        for piece in Self.chunk(text: text) {
            chunks.append(Chunk(text: piece, role: role, timestamp: Date(), turn: newTurn))
        }
    }
    
    // Basic paragraph/sentence chunker with overlap
    static func chunk(text: String, target: Int = 800, overlap: Int = 120) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        var result: [String] = []
        var start = trimmed.startIndex
        
        func advance(_ idx: inout String.Index, by n: Int, in s: String) {
            idx = s.index(idx, offsetBy: n, limitedBy: s.endIndex) ?? s.endIndex
        }
        
        while start < trimmed.endIndex {
            var end = start
            advance(&end, by: target, in: trimmed)
            // try to end at sentence boundary
            var sliceEnd = end
            if end < trimmed.endIndex {
                let window = trimmed[start..<end]
                if let lastDot = window.lastIndex(where: { ".!?".contains($0) }) {
                    sliceEnd = trimmed.index(after: lastDot)
                }
            }
            let chunk = String(trimmed[start..<sliceEnd])
            result.append(chunk)
            
            // move start forward with overlap
            var nextStart = sliceEnd
            advance(&nextStart, by: -overlap, in: trimmed)
            start = max(nextStart, sliceEnd)
        }
        return result.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    // Very lightweight keyword/recency scoring. Replace with embeddings when available.
    func retrieve(query: String, maxChunks: Int, tokenBudget: Int) -> [Chunk] {
        let qTokens = RAGStore.tokenize(query)
        guard !qTokens.isEmpty else {
            return Array(chunks.suffix(maxChunks)).reversed()
        }
        
        // score each chunk
        let scored = chunks.map { chunk -> (Chunk, Double) in
            let tokens = Self.tokenize(chunk.text)
            let overlap = qTokens.reduce(0) { $0 + (tokens.contains($1) ? 1 : 0) }
            // tiny recency boost (newer turn -> slightly higher)
            let recency = Double(chunk.turn)
            // normalize by chunk length (avoid giant chunks winning)
            let lengthPenalty = max(40.0, Double(tokens.count))
            let score = (Double(overlap) * 2.0 + recency * 0.05) / lengthPenalty
            return (chunk, score)
        }
            .sorted { $0.1 > $1.1 }
        
        // pick chunks until token budget is met
        var picked: [Chunk] = []
        var usedTokens = 0
        for (c, _) in scored {
            let t = Self.estimateTokens(for: c.text)
            if usedTokens + t > tokenBudget { continue }
            picked.append(c)
            usedTokens += t
            if picked.count >= maxChunks { break }
        }
        return picked
    }
    
    // Tokenization helpers
    static func tokenize(_ s: String) -> Set<String> {
        let lowered = s.lowercased()
        let tokens = lowered.split { !$0.isLetter && !$0.isNumber }
        return Set(tokens.map(String.init))
    }
    
    static func estimateTokens(for s: String) -> Int {
        // ~4 chars per token for Latin scripts; crude but practical.
        max(1, s.count / 4)
    }
}








// MARK: - Controller
@Observable
@MainActor
final class AIController {
    // Public UI state
    var bullets: [String] = []
    var messages: [Message] = []
    var summaries: [Summary] = []
    var userPrompt = ""
    var title = "New Recording"
    var summarySoFar = ""
    
    var tasks: [ActionTask] = []
    
    // Sessions & IO
    private var session: LanguageModelSession
    private var audioRecorder: AVAudioRecorder?
    
    // RAG
    private let rag = RAGStore()
    
    // Settings
    private let inputBudgetTokensPrimary = 3200   // leave headroom for output
    private let inputBudgetTokensFallback = 2200  // tighter on retry
    private let maxRetrievedChunksPrimary = 10
    private let maxRetrievedChunksFallback = 6
    private let summaryMaxCharsBeforeCompress = 1800
    
    init(session: LanguageModelSession) {
        self.session = session
    }
    
    func loadTranscript(_ transcript: String) {
        rag.add(text: transcript, role: .transcript)
    }
    
    // MARK: - Title (with RAG)
    func titleGenerator(prompt: String) async throws {
        let ragPrompt = buildTitlePrompt(
            userInput: prompt,
            tokenBudget: inputBudgetTokensPrimary,
            maxChunks: maxRetrievedChunksPrimary
        )

        let response = try await respondWithCompressionIfNeeded(ragPrompt)
        
        // Post-process: strip quotes, limit to 6 words max
        let clean = response
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .prefix(6)
            .joined(separator: " ")
        
        title = clean
    }
    
    // MARK: - RAG: Build Title Prompt
    private func buildTitlePrompt(userInput: String, tokenBudget: Int, maxChunks: Int) -> String {
        // retrieve relevant context
        let retrieved = rag.retrieve(
            query: userInput,
            maxChunks: maxChunks,
            tokenBudget: tokenBudget
        )
        
        let contextList = retrieved.map { "• \($0.text)" }.joined(separator: "\n")
        
        let summarySnippet = summarySoFar.isEmpty ? "(none)" : summarySoFar
        
        return """
        SYSTEM INSTRUCTIONS:
        - You are creating a short, clear title for a meeting, lecture, or conversation.
        - Keep it **under 6 words**.
        - Be specific and informative, not generic.
        - Avoid filler like "meeting notes", "discussion", or "summary".
        - Use plain language.
        
        SHORT SUMMARY (carry-over):
        \(summarySnippet)

        RELEVANT CONTEXT SNIPPETS (retrieved):
        \(contextList.isEmpty ? "• (no additional context retrieved)" : contextList)

        USER INPUT:
        \(userInput)

        TASK:
        - Generate exactly one short, clear title.
        - Titles should highlight the main topic, key decision, or central idea.
        """
    }


    
    // MARK: - RAG: Build Prompt
    private func buildPrompt(userInput: String, tokenBudget: Int, maxChunks: Int) -> String {
        // retrieve relevant context
        let retrieved = rag.retrieve(
            query: userInput,
            maxChunks: maxChunks,
            tokenBudget: tokenBudget
        )
        
        let contextList = retrieved.map { "• \($0.text)" }.joined(separator: "\n")
        
        let summarySnippet = summarySoFar.isEmpty
        ? "(none)"
        : summarySoFar
        
        return """
        SYSTEM INSTRUCTIONS:
        - You are assisting with note-taking and summarization for meetings, lectures, or conversations.
        - Be concise. Use plain language. Avoid repetition.
        - Focus on capturing key points, tasks, and decisions.

        SHORT SUMMARY (carry-over):
        \(summarySnippet)

        RELEVANT CONTEXT SNIPPETS (retrieved):
        \(contextList.isEmpty ? "• (no additional context retrieved)" : contextList)

        USER INPUT:
        \(userInput)

        TASK:
        - Provide a clear, structured response that summarizes or elaborates on the discussion.
        - If you use context, integrate it naturally (no quotes needed).
        """
    }
    
    // MARK: - Chat with RAG + graceful retry
    func chat(question: String) async throws {
        userPrompt = question
        messages.append(Message(text: question, isUser: true, time: timeFormatter.string(from: Date()), isThinking: false))
        rag.add(text: question, role: .user)
        
        // First attempt (roomy budget)
        let primaryPrompt = buildPrompt(userInput: question,
                                        tokenBudget: inputBudgetTokensPrimary,
                                        maxChunks: maxRetrievedChunksPrimary)
        do {
            let answer = try await respondWithCompressionIfNeeded(primaryPrompt)
            recordAssistant(answer)
        } catch let error as LanguageModelSession.GenerationError {
            if case .exceededContextWindowSize = error {
                // Reset + fallback
                self.session = LanguageModelSession()
                try await compressSummaryIfNeeded(force: true)
                
                let fallbackPrompt = buildPrompt(userInput: question,
                                                 tokenBudget: inputBudgetTokensFallback,
                                                 maxChunks: maxRetrievedChunksFallback)
                let answer = try await session.respond(to: fallbackPrompt).content
                recordAssistant(answer)
            } else {
                throw error
            }
        }
    }
    
    // MARK: - Summarization (single-shot, for large text)
    func summarize(prompt: String) async throws {
        // Store full text into RAG as transcript content.
        rag.add(text: prompt, role: .transcript)
        
        let p = """
        Provide a concise bullet-point summary (max 8 bullets) of the following content:
        \(prompt)
        """
        let response = try await session.respond(to: p)
        bullets = response.content.split(separator: "\n").map { String($0) }
        summarySoFar = bullets.joined(separator: "\n")
        try await compressSummaryIfNeeded()
        
        // 👇 persist as a Summary model
            let newSummary = Summary(text: summarySoFar)
            summaries.append(newSummary)
    }
    
    // MARK: - Incremental Summarization with RAG
    func summarizeIncrementally(newTranscript: String) async throws {
        // Add new transcript chunks to the store
        rag.add(text: newTranscript, role: .transcript)
        
        let userGoal = """
        Update the running summary with these NEW transcript details.
        Keep it concise and informative: max 8–10 bullets.
        Avoid repeating already summarized points unless necessary.
        """
        // Attempt 1
        let prompt1 = buildPromptForSummaryUpdate(goal: userGoal,
                                                  tokenBudget: inputBudgetTokensPrimary,
                                                  maxChunks: maxRetrievedChunksPrimary,
                                                  latest: newTranscript)
        do {
            let updated = try await respondWithCompressionIfNeeded(prompt1)
            applySummary(updated)
        } catch let error as LanguageModelSession.GenerationError {
            if case .exceededContextWindowSize = error {
                // Reset + tighter budget
                self.session = LanguageModelSession()
                try await compressSummaryIfNeeded(force: true)
                
                let prompt2 = buildPromptForSummaryUpdate(goal: userGoal,
                                                          tokenBudget: inputBudgetTokensFallback,
                                                          maxChunks: maxRetrievedChunksFallback,
                                                          latest: newTranscript)
                let updated = try await session.respond(to: prompt2).content
                applySummary(updated)
            } else {
                throw error
            }
        }
    }
    
    // MARK: - Finalize Summary (alias)
    func finalizeSummary(with transcript: String) async throws {
        try await summarizeIncrementally(newTranscript: transcript)
    }
    
    // MARK: - Generate Tasks Safely
    func generateTasks(prompt: String) async throws {
        try await attemptGenerateTasks(prompt: prompt)
    }

    private func attemptGenerateTasks(prompt: String) async throws {
        let ragPrompt = buildPrompt(
            userInput: "Extract 5–7 clear action items from this content. " +
                       "Keep tasks short and actionable, suitable for a checklist.",
            tokenBudget: inputBudgetTokensPrimary,
            maxChunks: maxRetrievedChunksPrimary
        )
        do {
            let response = try await session.respond(
                to: ragPrompt,
                generating: Checklist.self
            )
            tasks = response.content.tasks
            // if nothing back, consider it not-an-error — caller will fallback
            return
        } catch let error as LanguageModelSession.GenerationError {
            if case .exceededContextWindowSize = error {
                // Reset session + try tighter. Caller must handle if this still fails.
                self.session = LanguageModelSession()
                try await compressSummaryIfNeeded(force: true)

                let fallbackPrompt = buildPrompt(
                    userInput: "Extract 3–5 clear action items (concise).",
                    tokenBudget: inputBudgetTokensFallback,
                    maxChunks: maxRetrievedChunksFallback
                )
                let response = try await session.respond(to: fallbackPrompt, generating: Checklist.self)
                tasks = response.content.tasks
                return
            } else {
                throw error
            }
        }
    }

    
    // MARK: - Helpers
    
    private func recordAssistant(_ answer: String) {
        messages.append(Message(text: answer, isUser: false, time: timeFormatter.string(from: Date()), isThinking: false))
        rag.add(text: answer, role: .assistant)
        Task { [weak self] in
            try? await self?.updateSummary(with: self?.userPrompt ?? "", answer: answer)
        }
    }
    
    private func buildPromptForSummaryUpdate(goal: String,
                                             tokenBudget: Int,
                                             maxChunks: Int,
                                             latest: String) -> String {
        let retrieved = rag.retrieve(
            query: latest.isEmpty ? (summarySoFar.isEmpty ? "summary" : summarySoFar) : latest,
            maxChunks: maxChunks,
            tokenBudget: tokenBudget
        )
        let ctx = retrieved.map { "• \($0.text)" }.joined(separator: "\n")
        let current = summarySoFar.isEmpty ? "(none yet)" : summarySoFar
        
        return """
        You are a summarization controller. Your job is to maintain a short, rolling summary.
        
        CURRENT SUMMARY:
        \(current)
        
        NEW MATERIAL (recent transcript excerpts and other relevant context):
        \(ctx.isEmpty ? "• (no extra context retrieved)" : ctx)
        
        GOAL:
        \(goal)
        
        OUTPUT FORMAT:
        - Bullet list only (one item per line).
        - Max 8–10 bullets.
        """
    }
    
    private func applySummary(_ text: String) {
        // Normalize bullet formatting
        let lines = text.split(whereSeparator: \.isNewline).map { String($0) }
        let normalized = lines.map { line -> String in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") { return trimmed }
            return "• \(trimmed)"
        }
        bullets = normalized.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        summarySoFar = bullets.joined(separator: "\n")
        
        // 👇 Create a new Summary model entry each time we update
        let newSummary = Summary(text: summarySoFar)
        summaries.append(newSummary)
    }
    
    // Updates the rolling summary after each Q/A
    private func updateSummary(with question: String, answer: String) async throws {
        let mergePrompt = """
        Update the running conversation summary with this exchange.
        Keep at most 8–10 bullets total. Merge, deduplicate, compress.
        
        CURRENT SUMMARY:
        \(summarySoFar.isEmpty ? "(none yet)" : summarySoFar)
        
        NEW EXCHANGE:
        Q: \(question)
        A: \(answer)
        
        OUTPUT:
        - Bullet list only.
        - No more than 8–10 bullets.
        """
        do {
            let response = try await session.respond(to: mergePrompt)
            applySummary(response.content)
            try await compressSummaryIfNeeded()
        } catch let error as LanguageModelSession.GenerationError {
            if case .exceededContextWindowSize = error {
                self.session = LanguageModelSession()
                try await compressSummaryIfNeeded(force: true)
                let response = try await session.respond(to: mergePrompt)
                applySummary(response.content)
                try await compressSummaryIfNeeded()
            } else {
                throw error
            }
        }
    }
    
    // Wrap a respond call that may need pre/post compression
//    private func respondWithCompressionIfNeeded(_ prompt: String) async throws -> String {
//        // Pre-emptive compression if our running summary is getting big
//        try await compressSummaryIfNeeded()
//        
//        do {
//            return try await session.respond(to: prompt).content
//        } catch let error as LanguageModelSession.GenerationError {
//            if case .exceededContextWindowSize = error {
//                // reset & retry once with tighter prompt (call-site handles rebuild normally)
//                self.session = LanguageModelSession()
//                try await compressSummaryIfNeeded(force: true)
//                return try await session.respond(to: prompt).content
//            } else {
//                throw error
//            }
//        }
//    }
    private func respondWithCompressionIfNeeded(_ prompt: String) async throws -> String {
        try await compressSummaryIfNeeded()

        do {
            return try await respond(prompt)
        } catch let error as LanguageModelSession.GenerationError {
            if case .exceededContextWindowSize = error {
                self.session = LanguageModelSession()
                try await compressSummaryIfNeeded(force: true)
                return try await respond(prompt)
            } else {
                throw error
            }
        }
    }

    
    // Compress the rolling summary aggressively when needed
    private func compressSummaryIfNeeded(force: Bool = false) async throws {
        guard force || summarySoFar.count > summaryMaxCharsBeforeCompress else { return }
        
        let compressPrompt = """
        The current rolling summary is too long.
        
        CURRENT SUMMARY:
        \(summarySoFar)
        
        Rewrite it as a concise bullet list of the 6–8 most important points.
        Avoid redundancy. Keep line-per-bullet.
        """
        do {
            let response = try await session.respond(to: compressPrompt)
            applySummary(response.content)
        } catch let error as LanguageModelSession.GenerationError {
            if case .exceededContextWindowSize = error {
                // If even compression overflows, reset and compress from scratch using a minimal instruction.
                self.session = LanguageModelSession()
                let minimal = """
                Rewrite the following into 6–8 concise bullet points:
                
                \(summarySoFar.prefix(2000))
                """
                let response = try await session.respond(to: minimal)
                applySummary(response.content)
            } else {
                throw error
            }
        }
    }
    
    // MARK: - Time Formatter
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()
    
    // Helper that prefers guided-generation to force plain text reliably.
    // Falls back to the raw string call if guided generation is not available or fails.
    private func respond(_ prompt: String) async throws -> String {
        // First attempt: guided generation with schema
        do {
            let response = try await session.respond(to: prompt, generating: AssistantMessage.self)
            let t = response.content.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.trimmingCharacters(in: CharacterSet(charactersIn: "\"'`"))
        } catch {
            // Fallback: raw string respond (still cleaned)
            let raw = try await session.respond(to: prompt).content
            let cleaned = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'`"))
            return cleaned
        }
    }

}




import FoundationModels


//
@Generable(description: "A checklist of action items")
struct Checklist {
    @Guide(description: "List of actionable tasks, each as a checklist item")
    var tasks: [ActionTask]
}


@Generable(description: "A to-do action task for the user")
struct ActionTask: Identifiable {
    var id = UUID()
    
    @Guide(description: "The title or description of the task")
    var title: String
    
    @Guide(description: "Whether this task has been completed")
    var isCompleted: Bool = false
}


@Generable(description: "Single chat reply as plain text")
struct AssistantMessage {
    /// A single reply suitable for presenting in chat UI. Plain text only; no formatting tokens.
    var text: String
}

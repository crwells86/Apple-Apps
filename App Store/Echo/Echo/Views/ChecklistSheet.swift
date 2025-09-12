import SwiftUI
import SwiftData
import FoundationModels

struct ChecklistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
//    let controller: AIController
    
    @State private var controller = AIController(session: LanguageModelSession())
    @Binding var recording: Recording
//    @Bindable var controller: AIController
    
    @State private var newTaskTitle = ""
    @State private var isGenerating = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isGenerating && recording.actionItems.isEmpty {
                    // Show AI animation while generating
                    VStack {
                        Spacer()
                        ThinkingAI()
                        Spacer()
                    }
                } else {
                    // Show checklist UI
                    List {
                        Section("Action Items") {
                            ForEach($recording.actionItems) { $item in
                                HStack(alignment: .top) {
                                    Button {
                                        item.isCompleted.toggle()
                                        try? modelContext.save()
                                    } label: {
                                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(item.isCompleted ? .green : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text(item.title)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(4)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .onDelete { indices in
                                let itemsToDelete = indices.map { recording.actionItems[$0] }
                                for item in itemsToDelete {
                                    modelContext.delete(item)
                                }
                                try? modelContext.save()
                            }
                        }
                        
                        Section {
                            HStack {
                                TextField("New action item", text: $newTaskTitle)
                                Button {
                                    guard !newTaskTitle.isEmpty else { return }
                                    let newItem = TaskItem(title: newTaskTitle)
                                    recording.actionItems.append(newItem)
                                    modelContext.insert(newItem)
                                    newTaskTitle = ""
                                    try? modelContext.save()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Action Items")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if let transcript = recording.transcription?.text {
                    controller.loadTranscript(transcript)
                }
            }
        }
        // Auto-generate if empty
        .task(id: recording.updatedAt) {
            await startChecklistIfNeeded()
        }
    }
    
    private func startChecklistIfNeeded() async {
        guard recording.actionItems.isEmpty else { return }
        guard !isGenerating else { return }
        
        isGenerating = true
        defer { isGenerating = false }
        
        guard let transcript = recording.transcription?.text, !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // no transcript -> nothing to do
            return
        }
        
        // Attempt AI generation with retry & fallback
        do {
            // Try AI generation
            try await controller.generateTasks(prompt: transcript)
            
            // If AI returned nothing, fall back to heuristic extraction
            if controller.tasks.isEmpty {
                controller.tasks = quickExtractTasksFromText(transcript)
            }
        } catch {
            // If generation failed, fallback locally
            controller.tasks = quickExtractTasksFromText(transcript)
        }
        
        await MainActor.run {
            syncControllerTasksToRecording()
        }
    }
    
    /// Cheap fallback: try to extract 5 short action items from text by picking imperative-looking sentences
    private func quickExtractTasksFromText(_ text: String, maxTasks: Int = 5) -> [ActionTask] {
        // split into sentences crudely
        let separators = CharacterSet(charactersIn: ".!?;\n")
        let rawSentences = text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // prefer sentences with keywords or imperative style
        let keywords = ["please", "will", "can you", "please", "todo", "action", "follow up", "assign", "task", "responsible", "deadline"]
        var scored: [(String, Int)] = []
        for s in rawSentences {
            var score = 0
            let lower = s.lowercased()
            for k in keywords { if lower.contains(k) { score += 3 } }
            // slightly prefer shorter, directive sentences
            if s.count < 140 { score += 1 }
            // boost sentences that start with a capitalized name or verb (heuristic)
            if let first = s.split(separator: " ").first, CharacterSet.uppercaseLetters.contains(first.unicodeScalars.first!) {
                score += 1
            }
            scored.append((s, score))
        }
        
        let chosen = scored
            .sorted { $0.1 > $1.1 }
            .prefix(maxTasks)
            .map { $0.0 }
        
        return chosen.map { ActionTask(title: $0) }
    }
    
    /// Sync AIController.tasks → Recording.actionItems (persisted)
    private func syncControllerTasksToRecording() {
        // If AI didn't return any tasks, do nothing (don't delete user's persisted items).
        guard !controller.tasks.isEmpty else {
            // Nothing from AI — keep existing persisted items. Could show a retry UI instead.
            return
        }
        
        // Clear existing persisted items (we have new AI results to persist)
        for item in recording.actionItems {
            modelContext.delete(item)
        }
        recording.actionItems.removeAll()
        
        // Save AI-generated ones
        for task in controller.tasks {
            let newItem = TaskItem(title: task.title, isCompleted: task.isCompleted)
            recording.actionItems.append(newItem)
            modelContext.insert(newItem)
        }
        
        try? modelContext.save()
    }
}

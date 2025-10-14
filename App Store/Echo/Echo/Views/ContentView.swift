import SwiftUI
import AVFoundation
import FoundationModels
import SwiftData
import Speech
import Foundation
import StoreKit

var model = SystemLanguageModel.default

struct ContentView: View {
    @Environment(StoreController.self) var storeController
    @Environment(\.modelContext) private var modelContext
    
    @State private var controller: AIController? = nil
    @State private var userInput: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var audioURL: URL?
    @State private var isRecording = false
    
    @Query(sort: \Recording.createdAt, order: .reverse) private var recordings: [Recording]
    @State private var selectedRecording: Recording?
    
    @State private var isSummarizePresented = false
    @Namespace private var summarizePresentationNamespace
    
    @State private var isChatPresented = false
    @Namespace private var chatPresentationNamespace
    
    @State private var isChecklistPresented = false
    @Namespace private var checklistPresentationNamespace
    
    @State private var isPaywallShowing = false
    
    @State private var isEditingTitle = false
    @State private var titleBeingEdited: Recording?
    @State private var newTitle: String = ""
    
    @AppStorage("hasSeenOnboarding") private var isOnboardingShowing = true
    @State private var hasRequestedReview = false
    
    var body: some View {
        switch model.availability {
        case .available:
            NavigationSplitView {
                List(selection: $selectedRecording) {
                    ForEach(recordings) { recording in
                        NavigationLink(value: recording) {
                            Text(recording.title)
                        }
                        .swipeActions(edge: .leading) {
                            Button("Edit") {
                                promptEditTitle(for: recording)
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete(perform: deleteRecordings)
                    .alert("Edit Title", isPresented: $isEditingTitle, actions: {
                        TextField("Title", text: $newTitle)
                        Button("Save") {
                            if let recording = titleBeingEdited {
                                recording.title = newTitle
                                recording.updatedAt = .now
                                try? modelContext.save()
                            }
                            isEditingTitle = false
                        }
                        Button("Cancel", role: .cancel) { isEditingTitle = false }
                    }, message: {
                        Text("Enter a new title for this recording")
                    })
                }
                .navigationTitle("Recordings")
                .toolbar {
                    ToolbarItemGroup {
                        Button {
                            if recordings.count > 7 {
                                isPaywallShowing.toggle()
                            } else {
                                let new = Recording.blank()
                                modelContext.insert(new)
                                try? modelContext.save()
                                // Select the newly created recording (recordings are reverse-sorted: newest first)
                                selectedRecording = new
                                // Reset controller for the new selection
                                controller = AIController(session: LanguageModelSession())
                            }
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                        
                        Menu {
                            Button("Restore Purchases") {
                                Task {
                                    await storeController.restorePurchases()
                                }
                            }
                            
                            Button("Rate App") {
                                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    AppStore.requestReview(in: scene)
                                }
                            }
                            
                            Button("Send Feedback") {
                                if let url = URL(string: "mailto:caleb@olyevolutions.com?subject=Aı%20Note%20Taker%20Feedback") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
                .onChange(of: recordings.count) {
                    if recordings.count > 7 {
                        isPaywallShowing.toggle()
                    }
                }
                .onAppear {
                    if recordings.count > 3 && hasRequestedReview {
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            AppStore.requestReview(in: scene)
                            hasRequestedReview.toggle()
                        }
                    }
                    if controller == nil, selectedRecording != nil {
                        controller = AIController(session: LanguageModelSession())
                    }
                }
                .onChange(of: selectedRecording?.persistentModelID) {
                    if selectedRecording != nil {
                        controller = AIController(session: LanguageModelSession())
                    } else {
                        controller = nil
                    }
                }
            } detail: {
                if let selected = selectedRecording {
                    VStack(alignment: .leading, spacing: 0) {
                        TranscriptView(
                            controller: Binding(
                                get: { controller ?? AIController(session: LanguageModelSession()) },
                                set: { controller = $0 }
                            ),
                            recording: .constant(selected)
                        ) { transcript in
                            let recordingRef = selected
                            Task { @MainActor in
                                recordingRef.transcription?.text = transcript
                                recordingRef.updatedAt = .now
                                recordingRef.isDone = true
                                do {
                                    let session = LanguageModelSession()
                                    let localController = AIController(session: session)
                                    try await localController.titleGenerator(prompt: transcript)
                                    let generatedTitle = localController.title
                                    recordingRef.title = generatedTitle
                                } catch {
                                    print("Title generation failed: \(error)")
                                }
                                try? modelContext.save()
                            }
                        }
                        
                        // MARK: Controls
                        if let text = selected.transcription?.text, !text.isEmpty {
                            HStack {
                                Button {
                                    isTextFieldFocused = false
                                    isSummarizePresented = true
                                } label: {
                                    Image(systemName: "character.textbox.badge.sparkles")
                                }
                                .padding()
                                .matchedTransitionSource(id: "summarizeTransitionID",
                                                         in: summarizePresentationNamespace)
                                
                                Button {
                                    isChecklistPresented = true
                                } label: {
                                    Image(systemName: "checklist")
                                }
                                
                                Button {
                                    isChatPresented.toggle()
                                } label: {
                                    Image(systemName: "questionmark.bubble")
                                }
                                .padding()
                                .matchedTransitionSource(id: "chatTransitionID",
                                                         in: chatPresentationNamespace)
                            }
                            .glassEffect()
                            .padding(.horizontal)
                        }
                    }
                    .navigationTitle(selected.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .id(selected.persistentModelID)
                } else {
                    ContentUnavailableView {
                        Label("Select a recording", systemImage: "waveform.path.ecg")
                            .font(.title2)
                    } description: {
                        Text("""
                    Choose a recording from the list to view its transcript, play the audio, and generate a summary.
                    
                    Tap the \(Text(Image(systemName: "plus")).foregroundStyle(.blue)) button to create a new recording.
                    """)
                    }
                }
            }
            // MARK: - Sheets
            .fullScreenCover(isPresented: $isOnboardingShowing) {
                OnBoardingView(isPaywallShowing: $isPaywallShowing)
            }
            .sheet(isPresented: $isPaywallShowing) {
                PaywallView()
            }
            .sheet(isPresented: $isChatPresented) {
                if let selected = selectedRecording {
                    ChatView(recording: .constant(selected)) //controller: controller,
                        .navigationTransition(.zoom(sourceID: "chatTransitionID",
                                                    in: chatPresentationNamespace))
                }
            }
            .sheet(isPresented: $isSummarizePresented) {
                if let selected = selectedRecording {
                    SummarySheet(recording: .constant(selected)) // controller: controller,
                        .navigationTransition(.zoom(sourceID: "summarizeTransitionID", in: summarizePresentationNamespace))
                }
            }
            .sheet(isPresented: $isChecklistPresented) {
                if let selected = selectedRecording {
                    ChecklistSheet(recording: .constant(selected)) //controller: controller, 
                        .navigationTransition(.zoom(sourceID: "checklistTransitionID", in: checklistPresentationNamespace))
                }
            }
            
        case .unavailable(.deviceNotEligible):
            ContentUnavailableView {
                Label("Device Not Supported", systemImage: "exclamationmark.triangle")
            } description: {
                Text("This device doesn’t support Apple Intelligence features required for recording and transcription.")
            }
            
        case .unavailable(.appleIntelligenceNotEnabled):
            ContentUnavailableView {
                Label("Apple Intelligence Disabled", systemImage: "sparkles")
            } description: {
                Text("Turn on Apple Intelligence in Settings to enable recording summaries and AI-powered insights.")
            }
            
        case .unavailable(.modelNotReady):
            ContentUnavailableView {
                Label("Getting Things Ready", systemImage: "hourglass")
            } description: {
                Text("The transcription engine is still warming up. Please try again in a moment.")
            }
            
        case .unavailable(let other):
            ContentUnavailableView {
                Label("Unavailable", systemImage: "questionmark.circle")
            } description: {
                Text("Something unexpected is preventing recordings and transcripts from working. \(String(describing: other))")
            }
        }
    }
    
    private func promptEditTitle(for recording: Recording) {
        titleBeingEdited = recording
        newTitle = recording.title
        isEditingTitle = true
    }
    
    private func deleteRecordings(at offsets: IndexSet) {
        for index in offsets {
            let recording = recordings[index]
            modelContext.delete(recording)
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete: \(error)")
        }
    }
}

#Preview {
    ContentView()
}

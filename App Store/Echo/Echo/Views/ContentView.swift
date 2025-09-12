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
    
    @State private var controller = AIController(session: LanguageModelSession())
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
                                modelContext.insert(Recording.blank())
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
                                if let url = URL(string: "mailto:calebrwells@gmail.com?subject=Aı%20Note%20Taker%20Feedback") {
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
                }
            } detail: {
                if let _ = selectedRecording {
                    VStack(alignment: .leading, spacing: 0) {
                        if let _ = Binding($selectedRecording) {
                            if let selected = selectedRecording {
                                // Pass a stable, non-optional binding to the concrete object.
                                // Recording is a reference-type (SwiftData @Model), so .constant(selected)
                                // gives the view a stable object for the lifetime of the detail screen.
                                TranscriptView(controller: $controller, recording: .constant(selected)) { transcript in
                                    // Work with the concrete Recording instance you captured.
                                    let recordingRef = selected
                                    
                                    Task { @MainActor in
                                        recordingRef.transcription?.text = transcript
                                        recordingRef.updatedAt = .now
                                        recordingRef.isDone = true
                                        
                                        do {
                                            // Per-request ephemeral session/controller to avoid sharing any conversation state.
                                            let session = LanguageModelSession()
                                            let localController = AIController(session: session)

                                            try await localController.titleGenerator(prompt: transcript)
                                            // Read back from the **local** controller — guaranteed to be scoped to this transcript.
                                            let generatedTitle = localController.title

                                            recordingRef.title = generatedTitle
                                        } catch {
                                            print("Title generation failed: \(error)")
                                        }
                                        
                                        try? modelContext.save()
                                    }
                                }
                            }
                        }
                        else {
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
                        
                        // MARK: Controls
                        if let text = selectedRecording?.transcription?.text,
                           !text.isEmpty {
                            
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
                    .navigationTitle(controller.title)
                    .navigationBarTitleDisplayMode(.inline)
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

import SwiftUI
import AVFAudio
import SwiftData
import Combine

struct TranscriptView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var controller: AIController
    @Binding var recording: Recording
    
    @State private var isRecording = false
    @State private var isPlaying = false
    
    @State private var recorder: Recorder
    @State private var speechTranscriber: SpokenWordTranscriber
    
    @State private var downloadProgress = 0.0
    @State private var currentPlaybackTime = 0.0
    
    @State private var hasGeneratedTitle = false
    @State private var highlightedRun: Int? = nil
    
    // Track all async work
    @State private var activeTasks: [Task<Void, Never>] = []
    
    var onTranscriptFinalized: ((String) -> Void)?
    
    @GestureState private var micPressed: Bool = false
    @State private var timerPublisher = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
    init(controller: Binding<AIController>, recording: Binding<Recording>, onTranscriptFinalized: ((String) -> Void)? = nil) {
        self._controller = controller
        self._recording = recording
        let transcriber = SpokenWordTranscriber(recording: recording)
        self._speechTranscriber = State(initialValue: transcriber)
        self._recorder = State(initialValue: Recorder(transcriber: transcriber, recording: recording))
        self.onTranscriptFinalized = onTranscriptFinalized
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if !recording.isDone {
                    liveRecordingScrollView
                } else {
                    playbackScrollView
                }
            }
            .padding(.horizontal)
            .padding(.top, 6)
            
            ZStack {
                WaveView(height: 140)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: -4)
                
                VStack {
                    HStack {
                        statusText
                        Spacer()
                        if recording.isDone {
                            playerControls
                        } else {
                            FloatingMicButton(isRecording: isRecording) {
                                handleRecordingButtonTap()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 18)
                    
                    // ⚠️ Disclaimer label (only while recording)
                    if isRecording {
                        Text("Audio transcription isn’t always exact. Verify important details.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(recording.title)
        .onReceive(timerPublisher) { _ in
            if isPlaying {
                if let currentTime = recorder.playerNode?.currentTime {
                    currentPlaybackTime = currentTime
                    let attributed = recording.recordingBrokenUpByLines()
                    if let idx = runIndex(for: currentPlaybackTime, in: attributed) {
                        highlightedRun = idx
                    } else {
                        highlightedRun = nil
                    }
                }
            }
        }
        .onChange(of: isPlaying) {
            handlePlayback()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        for t in activeTasks { t.cancel() }
        activeTasks.removeAll()
        
        recorder.stopPlaying()
        isPlaying = false
        
        if isRecording {
            Task {
                _ = try? await recorder.stopRecording()
            }
        }
        isRecording = false
    }
    
    // MARK: - Status
    var statusText: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !micPressed {
                if isRecording {
                    Text("Now recording")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(recording.title).bold()
                } else if isPlaying {
                    Text("Now playing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(recording.title).bold()
                }
            }
        }
    }
    
    var playerControls: some View {
        PlayerControlsView(
            isPlaying: isPlaying,
            onPlayToggle: {
                if isRecording { isRecording = false }
                handlePlayButtonTap()
            },
            onBack: {
                currentPlaybackTime = max(0, currentPlaybackTime - 15)
                recorder.playerNode?.pause()
            },
            onForward: {
                currentPlaybackTime += 15
            },
            progress: (recording.duration > 0) ? min(1, currentPlaybackTime / recording.duration) : 0
        )
        .frame(height: 110)
        .padding(.horizontal)
        .padding(.top, 6)
    }
    
    // MARK: - Live transcript ScrollView
    @ViewBuilder
    var liveRecordingScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(speechTranscriber.finalizedTranscript + speechTranscriber.volatileTranscript)
                        .font(.title)
                        .id("live-bottom")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }
            .onChange(of: speechTranscriber.finalizedTranscript) {
                DispatchQueue.main.async {
                    withAnimation(.easeOut) {
                        proxy.scrollTo("live-bottom", anchor: .bottom)
                    }
                }
            }
            .onChange(of: speechTranscriber.volatileTranscript) {
                DispatchQueue.main.async {
                    withAnimation(.linear(duration: 0.12)) {
                        proxy.scrollTo("live-bottom", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Playback ScrollView
    func playbackScrollViewBody() -> some View {
        let attributed = recording.recordingBrokenUpByLines()
        let runs = runsWithTimeRanges(from: attributed)
        
        var paragraphs: [AttributedString] = []
        var paragraphRunIds: [[Int]] = []
        var currentParagraph = AttributedString()
        var currentParagraphRunIds: [Int] = []
        
        for run in runs {
            currentParagraph.append(run.text)
            currentParagraphRunIds.append(run.id)
            if run.text.characters.contains(where: { $0 == "\n" }) {
                paragraphs.append(currentParagraph)
                paragraphRunIds.append(currentParagraphRunIds)
                currentParagraph = AttributedString()
                currentParagraphRunIds = []
            }
        }
        if !currentParagraphRunIds.isEmpty || !currentParagraph.characters.isEmpty {
            paragraphs.append(currentParagraph)
            paragraphRunIds.append(currentParagraphRunIds)
        }
        if paragraphs.isEmpty {
            paragraphs = [AttributedString("")]
            paragraphRunIds = [[0]]
        }
        
        var runIdToParagraphIndex: [Int: Int] = [:]
        for (pIndex, ids) in paragraphRunIds.enumerated() {
            for id in ids { runIdToParagraphIndex[id] = pIndex }
        }
        
        func attributedWithHighlighting(_ paragraph: AttributedString) -> AttributedString {
            var copy = paragraph
            for run in copy.runs {
                if isPlaying,
                   let start = run.audioTimeRange?.start.seconds,
                   let end = run.audioTimeRange?.end.seconds,
                   start <= currentPlaybackTime && currentPlaybackTime < end {
                    copy[run.range].backgroundColor = Color.mint.opacity(0.22)
                } else {
                    copy[run.range].backgroundColor = nil
                }
            }
            return copy
        }
        
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(paragraphs.indices, id: \.self) { pIndex in
                        let para = attributedWithHighlighting(paragraphs[pIndex])
                        Text(para)
                            .font(.title)
                            .id("para-\(pIndex)")
                            .padding(.vertical, 2)
                    }
                    Spacer().frame(height: 36)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }
            .onAppear {
                DispatchQueue.main.async {
                    if isPlaying {
                        let attributedAll = recording.recordingBrokenUpByLines()
                        if let runId = runIndex(for: currentPlaybackTime, in: attributedAll),
                           let p = runIdToParagraphIndex[runId] {
                            proxy.scrollTo("para-\(p)", anchor: .center)
                        } else {
                            proxy.scrollTo("para-\(max(0, paragraphs.count - 1))", anchor: .bottom)
                        }
                    } else {
                        proxy.scrollTo("para-\(max(0, paragraphs.count - 1))", anchor: .bottom)
                    }
                }
            }
            .onChange(of: currentPlaybackTime) { newTime, _ in
                let attributedAll = recording.recordingBrokenUpByLines()
                if let runId = runIndex(for: newTime, in: attributedAll),
                   let paragraphIndex = runIdToParagraphIndex[runId] {
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.18)) {
                            proxy.scrollTo("para-\(paragraphIndex)", anchor: .center)
                        }
                    }
                }
            }
            .onChange(of: attributed) {
                DispatchQueue.main.async {
                    withAnimation(.easeOut) {
                        proxy.scrollTo("para-\(max(0, paragraphs.count - 1))", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    var playbackScrollView: some View {
        controller.loadTranscript(String(recording.text.characters))
        return playbackScrollViewBody()
    }
    
    // MARK: - Helpers
    func runsWithTimeRanges(from attributed: AttributedString) -> [(id: Int, text: AttributedString, start: Double?, end: Double?)] {
        var out: [(id: Int, text: AttributedString, start: Double?, end: Double?)] = []
        for (i, run) in attributed.runs.enumerated() {
            let sub = AttributedString(attributed[run.range])
            let start = run.audioTimeRange?.start.seconds
            let end = run.audioTimeRange?.end.seconds
            out.append((id: i, text: sub, start: start, end: end))
        }
        if out.isEmpty {
            out.append((id: 0, text: attributed, start: nil, end: nil))
        }
        return out
    }
    
    func runIndex(for time: Double, in attributed: AttributedString) -> Int? {
        let runs = runsWithTimeRanges(from: attributed)
        if let idx = runs.firstIndex(where: { run in
            if let s = run.start, let e = run.end {
                return (s <= time && time < e)
            }
            return false
        }) {
            return runs[idx].id
        }
        if let idx = runs.lastIndex(where: { run in
            if let s = run.start {
                return s <= time
            }
            return false
        }) {
            return runs[idx].id
        }
        return nil
    }
    
    // MARK: - Controls
    func handlePlayback() {
        let audioURL = recording.fileURL
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            print("❌ Audio file not found at \(audioURL)")
            return
        }
        
        if isPlaying {
            recorder.playRecording(from: audioURL)
        } else {
            recorder.stopPlaying()
            currentPlaybackTime = 0.0
            highlightedRun = nil
        }
    }
    
    func handleRecordingButtonTap() {
        isRecording.toggle()
        
        if !isRecording {
            let t = Task {
                do {
                    let tempURL = try await recorder.stopRecording()
                    
                    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let destinationURL = documents.appendingPathComponent("\(recording.id).wav")
                    
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    
                    recording.fileURL = destinationURL
                    recording.isDone = true
                    recording.updatedAt = .now
                    try? modelContext.save()
                    
                    print("✅ Audio saved to \(destinationURL)")
                    
                    let transcript = String(speechTranscriber.finalizedTranscript.characters)
                    Task { @MainActor in
                        onTranscriptFinalized?(transcript)
                    }
                } catch {
                    print("❌ Failed to save recording: \(error)")
                }
            }
            activeTasks.append(t)
        } else {
            hasGeneratedTitle = false
            
            let scheduled = Task {
                try? await Task.sleep(for: .seconds(300))
                await generateTitleIfNeeded()
            }
            activeTasks.append(scheduled)
            
            let startT = Task {
                do {
                    try await recorder.startRecording()
                } catch {
                    print("could not record: \(error)")
                }
            }
            activeTasks.append(startT)
        }
    }
    
    @MainActor
    private func generateTitleIfNeeded() async {
        guard !hasGeneratedTitle else { return }
        hasGeneratedTitle = true
        
        let transcript = speechTranscriber.finalizedTranscript
        do {
            try await controller.titleGenerator(prompt: String(transcript.characters))
            recording.title = controller.title
        } catch {
            print("❌ Title generation failed: \(error)")
        }
    }
    
    func handlePlayButtonTap() {
        isPlaying.toggle()
    }
}

import SwiftUI
import AVFAudio
import SwiftData
import Combine
import Foundation
import CoreText
import PDFKit

#if canImport(UIKit)
extension UIFont {
    func bold() -> UIFont { return withTraits(traits: .traitBold) }
    private func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
#endif

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
    
    // Async tasks we spawn from this view
    @State private var activeTasks: [Task<Void, Never>] = []
    
    // Optional callback when transcript finalizes
    var onTranscriptFinalized: ((String) -> Void)? = nil
    
    // Search & navigation
    @State private var searchText: String = ""
    // Each match is identified by the run id and the local range inside that run's text
    struct Match: Identifiable, Equatable { let id: String; let runId: Int; let range: Range<AttributedString.Index> }
    @State private var matches: [Match] = []
    @State private var currentMatchIndex: Int = 0
    @State private var isSearching: Bool = false
    @State private var isSearchVisible: Bool = false
    @Namespace private var searchScrollNamespace
    
    // Editing
    @State private var isEditingParagraph: Bool = false
    @State private var editingParagraphIndex: Int? = nil
    @State private var editingParagraphText: String = ""
    
    // Clips
    struct Clip: Identifiable, Hashable { let id = UUID(); var start: Double; var end: Double; var text: String }
    @State private var clips: [Clip] = []
    @State private var clipSelectionStartRunId: Int? = nil
    @State private var clipSelectionEndRunId: Int? = nil
    @State private var showingClipsSheet: Bool = false
    
    // Export
    @State private var showingExportSheet: Bool = false
    @State private var exportURL: URL? = nil
    
    @GestureState private var micPressed: Bool = false
    @State private var timerPublisher: Publishers.Autoconnect<Timer.TimerPublisher> = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
    init(controller: Binding<AIController>, recording: Binding<Recording>, onTranscriptFinalized: ((String) -> Void)? = nil) {
        self._controller = controller
        self._recording = recording
        
        // Build transcriber/recorder in simple steps to help the type-checker
        let transcriber: SpokenWordTranscriber = SpokenWordTranscriber(recording: recording)
        self._speechTranscriber = State<SpokenWordTranscriber>(initialValue: transcriber)
        
        let rec: Recorder = Recorder(transcriber: transcriber, recording: recording)
        self._recorder = State<Recorder>(initialValue: rec)
        
        self.onTranscriptFinalized = onTranscriptFinalized
    }
    
    private func setPlaybackRate(_ rate: Double) {
        // If Recorder exposes playback rate, set it here. For now, a no-op to satisfy compiler.
        // e.g., recorder.playbackRate = rate
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            VStack(alignment: .leading) {
                Group {
                    if !recording.isDone {
                        liveRecordingScrollView
                    } else {
                        // Wrap playbackScrollViewBody in ScrollViewReader with onChange for currentMatchIndex scrolling
                        ScrollViewReader { proxy in
                            playbackScrollViewBody()
                                .onChange(of: currentMatchIndex) { _, newValue in
                                    if matches.indices.contains(newValue) {
                                        let id = matches[newValue].id
                                        withAnimation(.easeInOut) {
                                            proxy.scrollTo(id, anchor: .center)
                                        }
                                    }
                                }
                        }
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
        }
        .navigationTitle(recording.title)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showingExportSheet = true } label: { Label("Export", systemImage: "square.and.arrow.up") }
                Button {
                    // Open edit UI entry point; default to first paragraph for now
                    beginEditParagraph(index: 0, text: String(recording.recordingBrokenUpByLines().characters))
                } label: {
                    Label("Edit", systemImage: "square.and.pencil")
                }
            }
        }
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
        .sheet(isPresented: $isEditingParagraph) {
            NavigationStack {
                VStack(alignment: .leading) {
                    Text("Edit Paragraph").font(.headline)
                    TextEditor(text: $editingParagraphText)
                        .frame(minHeight: 200)
                        .padding(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    Spacer()
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { isEditingParagraph = false } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { commitParagraphEdit() } }
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExporterAsyncWrapper(recording: recording) { urls in
                ExporterView(urls: urls) { showingExportSheet = false }
            }
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
    
    private func matchesForParagraph(runIds: [Int]) -> [Match] {
        let set = Set(runIds)
        return matches.filter { set.contains($0.runId) }
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
    
    private func beginEditParagraph(index: Int, text: String) {
        editingParagraphIndex = index
        editingParagraphText = text
        isEditingParagraph = true
    }
    
    private func commitParagraphEdit() {
        guard let idx = editingParagraphIndex else { isEditingParagraph = false; return }
        // Recompose paragraphs and replace the edited paragraph's text
        let attributedAll = recording.recordingBrokenUpByLines()
        let runs = runsWithTimeRanges(from: attributedAll)
        // Build paragraph boundaries similar to playbackScrollViewBody
        var paragraphs: [[Int]] = []
        var current: [Int] = []
        for r in runs { current.append(r.id); if r.text.characters.contains(where: { $0 == "\n" }) { paragraphs.append(current); current = [] } }
        if !current.isEmpty { paragraphs.append(current) }
        if idx < paragraphs.count {
            // Replace text for these runs by merging into a single attributed string without altering timing
            let ids = paragraphs[idx]
            let new = AttributedString(editingParagraphText)
            // Simple replacement: rebuild recording.text by replacing the substring range covering these runs
            var composed = AttributedString()
            for (i, r) in runs.enumerated() {
                if ids.contains(r.id) {
                    if i == ids.first { composed.append(new) }
                    continue
                } else {
                    composed.append(r.text)
                }
            }
            recording.text = composed
            recording.updatedAt = .now
            controller.loadTranscript(String(composed.characters))
            try? modelContext.save()
            NotificationCenter.default.post(name: Notification.Name("TranscriptDidUpdate"), object: recording.id)
        }
        
        isEditingParagraph = false
    }
    
    private func timecode(_ t: Double) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
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
                    controller.loadTranscript(transcript)
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

// MARK: - Async Export Wrapper View
fileprivate func exportTranscriptFiles(recording: Recording) async -> [URL] {
    var urls: [URL] = []
    
    let rawTitle = recording.title.isEmpty ? "Transcript" : recording.title
    let safeTitle = rawTitle
        .replacingOccurrences(of: "/", with: "-")
        .replacingOccurrences(of: ":", with: "-")
        .replacingOccurrences(of: "\\", with: "-")
        .replacingOccurrences(of: "?", with: "-")
        .replacingOccurrences(of: "*", with: "-")
        .replacingOccurrences(of: "\"", with: "'")
        .replacingOccurrences(of: "<", with: "(")
        .replacingOccurrences(of: ">", with: ")")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    let transcriptString = String(recording.text.characters)
    
    // 1) TXT export
    let txtURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeTitle).txt")
    try? transcriptString.write(to: txtURL, atomically: true, encoding: .utf8)
    urls.append(txtURL)
    
    // 2) PDF export via PDFKit
    let pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeTitle).pdf")
    
#if canImport(PDFKit)
    do {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 36
        let contentWidth = pageRect.width - margin * 2
        let pageBackgroundColor = CGColor(gray: 1.0, alpha: 1.0)
        
#if canImport(UIKit)
        let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let bodyFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.darkGray
        ]
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.black
        ]
#else
        let titleAttributes: [NSAttributedString.Key: Any] = [:]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [:]
        let bodyAttributes: [NSAttributedString.Key: Any] = [:]
#endif
        
        // Concise summary fallback: up to 3 bullets, otherwise a short paragraph (~200 chars)
        var summaryText: String = {
            let trimmed = transcriptString.trimmingCharacters(in: .whitespacesAndNewlines)
            let lines = trimmed
                .split(separator: "\n")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            // Try to form up to 3 bullet points from the first few non-empty lines
            let bulletCandidates = Array(lines.prefix(5))
            let bullets = bulletCandidates
                .prefix(3)
                .map { s -> String in
                    // Keep each bullet concise
                    let clipped = s.count > 120 ? String(s.prefix(117)) + "…" : s
                    return "• " + clipped
                }
            if !bullets.isEmpty {
                return bullets.joined(separator: "\n")
            }
            
            // Fallback: a single short paragraph
            let paragraph = lines.first ?? trimmed
            if paragraph.count > 200 {
                return String(paragraph.prefix(197)) + "…"
            } else {
                return paragraph
            }
        }()
        
        let titleString = NSAttributedString(string: rawTitle + "\n", attributes: titleAttributes)
        let subtitleString = NSAttributedString(string: "This document was generated from a live transcript.\n\n", attributes: subtitleAttributes)
        let summaryHeader = NSAttributedString(string: (summaryText.isEmpty ? "" : "Summary\n"), attributes: titleAttributes)
        let summaryBody = NSAttributedString(string: (summaryText.isEmpty ? "" : summaryText + "\n\n"), attributes: bodyAttributes)
        let bodyString = NSAttributedString(string: transcriptString, attributes: bodyAttributes)
        
        let full = NSMutableAttributedString()
        full.append(titleString)
        full.append(subtitleString)
        if !summaryText.isEmpty {
            full.append(summaryHeader)
            full.append(summaryBody)
        }
        full.append(bodyString)
        
        let framesetter = CTFramesetterCreateWithAttributedString(full as CFAttributedString)
        var currentRange = CFRange(location: 0, length: 0)
        
        let pdfDocument = PDFDocument()
        var pageIndex = 0
        
        while currentRange.location < full.length {
            let pageData = NSMutableData()
            UIGraphicsBeginPDFContextToData(pageData , pageRect, nil)
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
            guard let context = UIGraphicsGetCurrentContext() else {
                UIGraphicsEndPDFContext()
                break
            }
            
            context.setFillColor(pageBackgroundColor)
            context.fill(pageRect)
            
            context.saveGState()
            context.translateBy(x: 0, y: pageRect.height)
            context.scaleBy(x: 1.0, y: -1.0)
            
            let textFrameRect = CGRect(x: margin, y: margin, width: contentWidth, height: pageRect.height - margin * 2)
            let path = CGMutablePath()
            path.addRect(textFrameRect)
            let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
            CTFrameDraw(frame, context)
            
            context.restoreGState()
            
            UIGraphicsEndPDFContext()
            let pdfPageData = pageData as Data
            if let pageDoc = PDFDocument(data: pdfPageData), let page = pageDoc.page(at: 0) {
                pdfDocument.insert(page, at: pageIndex)
                pageIndex += 1
            }
            
            let visible = CTFrameGetVisibleStringRange(frame)
            currentRange.location += visible.length
        }
        
        if pdfDocument.pageCount > 0 {
            if FileManager.default.fileExists(atPath: pdfURL.path) {
                try? FileManager.default.removeItem(at: pdfURL)
            }
            if let data = pdfDocument.dataRepresentation() {
                try data.write(to: pdfURL)
                urls.append(pdfURL)
            }
        }
    } catch {
        print("❌ Failed to generate PDF with PDFKit: \(error)")
    }
#else
    // PDFKit unavailable on this platform; skip PDF.
#endif
    
    return urls
}

fileprivate struct ExporterAsyncWrapper<Content: View>: View {
    @State private var urls: [URL] = []
    let content: ([URL]) -> Content
    let recording: Recording
    
    init(recording: Recording, content: @escaping ([URL]) -> Content) {
        self.recording = recording
        self.content = content
    }
    
    var body: some View {
        Group {
            if urls.isEmpty {
                ProgressView("Preparing export…")
                    .task {
                        let result = await exportTranscriptFiles(recording: recording)
                        urls = result
                    }
            } else {
                content(urls)
            }
        }
    }
}

// MARK: - Helper Views
fileprivate struct ExporterView: View {
    let urls: [URL]
    var onDone: () -> Void
    
    var body: some View {
        NavigationStack {
            List(urls, id: \.self) { url in
                HStack {
                    Image(systemName: "doc")
                    Text(url.lastPathComponent)
                    Spacer()
                    ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                }
            }
            .navigationTitle("Export")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { onDone() } } }
        }
    }
}


import Foundation
import AVFoundation
import SwiftUI


class Recorder {
    private let audioEngine = AVAudioEngine()
    var audioFile: AVAudioFile?
    var playerNode: AVAudioPlayerNode?

    var recording: Binding<Recording>
    private let transcriber: SpokenWordTranscriber
    
    let bufferConverter = BufferConverter()

    init(transcriber: SpokenWordTranscriber, recording: Binding<Recording>) {
        self.transcriber = transcriber
        self.recording = recording
    }

//    func stopPlaying() {
//        audioEngine.stop()
//        playerNode?.stop()
//    }
//    
//    func startRecording() async throws {
//        guard await isAuthorized() else { return }
//
//#if os(iOS)
//        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .spokenAudio)
//        try AVAudioSession.sharedInstance().setActive(true)
//#endif
//
//        try await transcriber.setUpTranscriber()
//
//        // TEMP file in safe format
//        let tempURL = FileManager.default.temporaryDirectory
//            .appendingPathComponent(UUID().uuidString)
//            .appendingPathExtension("wav")
//
//        // STANDARD PCM format: 16-bit, 44100 Hz, mono
////        let format = AVAudioFormat(commonFormat: .pcmFormatInt16,
////                                   sampleRate: 44100,
////                                   channels: 1,
////                                   interleaved: true)!
//        
//        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
//                                   sampleRate: 48000,
//                                   channels: 1,
//                                   interleaved: true)!
//
//        audioFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)
//
////        let inputNode = audioEngine.inputNode
//        let inputNode = audioEngine.inputNode
//        let inputFormat = inputNode.outputFormat(forBus: 0)  // 48kHz Float32
//        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
//            guard let self else { return }
//
//            // Convert buffer to safe format before writing
//            do {
//                let safeBuffer = try self.bufferConverter.convertBuffer(buffer, to: self.safePCMFormat())
//                try self.audioFile?.write(from: safeBuffer)
//            } catch {
//                print("❌ Failed to write buffer: \(error)")
//            }
//        }
//
//        inputNode.removeTap(onBus: 0)
//
//        // Tap microphone
//        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
//            guard let self else { return }
//            do {
//                try self.audioFile?.write(from: buffer)  // now always safe PCM
//            } catch {
//                print("❌ Failed to write buffer: \(error)")
//            }
//        }
//
//        audioEngine.prepare()
//        try audioEngine.start()
//    }
//
//    func stopRecording() async throws -> URL {
//        audioEngine.inputNode.removeTap(onBus: 0)
//        audioEngine.stop()
//        try await transcriber.finishTranscribing()
//        return audioFile!.url
//    }
//
//    func playRecording(from url: URL) {
//        do {
//            let audioFile = try AVAudioFile(forReading: url)   // safe PCM now
//            playerNode = AVAudioPlayerNode()
//            guard let playerNode else { return }
//
//            audioEngine.attach(playerNode)
//            audioEngine.connect(playerNode, to: audioEngine.outputNode, format: audioFile.processingFormat)
//            playerNode.scheduleFile(audioFile, at: nil)
//            try audioEngine.start()
//            playerNode.play()
//        } catch {
//            print("❌ Failed to play audio: \(error)")
//        }
//    }
    
    func stopPlaying() {
            playerNode?.stop()
            if let p = playerNode {
                audioEngine.detach(p)
                playerNode = nil
            }
            if audioEngine.isRunning {
                audioEngine.stop()
            }
        }

        func startRecording() async throws {
            guard await isAuthorized() else { return }

        #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        #endif

            try await transcriber.setUpTranscriber()

            // Use Float32 on-disk (safer)
            let diskFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                           sampleRate: 48000,
                                           channels: 1,
                                           interleaved: false)!   // non-interleaved float

            // prepare file URL
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("wav")

            // Create audio file with diskFormat.settings
            audioFile = try AVAudioFile(forWriting: tempURL, settings: diskFormat.settings)

            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0) // ensure no leftover taps

            // Diagnostics: log that tap installed and formats
            print("📥 Installing tap. inputFormat: \(inputFormat), diskFormat: \(diskFormat)")

            inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, when in
                guard let self = self else { return }

                // quick diagnostics
                print("🔸 Tap callback: buffer.frameLength=\(buffer.frameLength)")

                guard buffer.frameLength > 0 else {
                    // nothing to write
                    return
                }

                // inside your tap, before write:
                do {
                    let converted = try self.bufferConverter.convertBuffer(buffer, to: diskFormat)
                    // diagnostics
                    print("🔸 converted.format: \(converted.format)")
                    print("🔸 audioFile.fileFormat: \(String(describing: self.audioFile?.fileFormat))")
                    print("🔸 converted.frameCapacity=\(converted.frameCapacity), frameLength=\(converted.frameLength)")

                    guard converted.frameLength > 0 else {
                        print("⚠️ converted frameLength == 0, skipping write")
                        return
                    }

                    try self.audioFile?.write(from: converted)
                } catch {
                    print("❌ Failed to convert/write buffer: \(error)")
                }

                // stream original buffer (if transcriber expects analyzer format, convert inside transcriber)
                Task {
                    do {
                        try await self.transcriber.streamAudioToTranscriber(buffer)
                    } catch {
                        // ignore transcription errors here (log if you want)
                    }
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
        }

    func stopRecording() async throws -> URL {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        try await transcriber.finishTranscribing()

        guard let file = audioFile else {
            throw NSError(domain: "Recorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "No audioFile"])
        }

        let url = file.url

        // Force deinit/close of AVAudioFile so header is finalized.
        // Setting to nil should deallocate the AVAudioFile and flush headers.
        self.audioFile = nil

        // Optionally log to verify deinit finalized frames in the file on disk
        do {
            let read = try AVAudioFile(forReading: url)
            print("🔎 file frames after finalizing writer: \(read.length)")
        } catch {
            print("⚠️ could not re-open file after finalizing: \(error)")
        }

        return url
    }


        func playRecording(from url: URL) {
            do {
                guard FileManager.default.fileExists(atPath: url.path) else {
                    print("❌ file not found at \(url)")
                    return
                }

                let audioFile = try AVAudioFile(forReading: url)
                print("Playback file size: \((try? FileManager.default.attributesOfItem(atPath: url.path)[.size]) as? NSNumber ?? 0) bytes")
                print("🔍 audioFile.length: \(audioFile.length)")
                print("🔍 fileFormat: \(audioFile.fileFormat)")
                print("🔍 processingFormat: \(audioFile.processingFormat)")

                // sanity
                guard audioFile.length > 0, audioFile.processingFormat.sampleRate > 0 else {
                    print("❌ Audio file has zero frames or invalid processing format.")
                    return
                }

                if let existing = playerNode {
                    existing.stop()
                    audioEngine.detach(existing)
                    playerNode = nil
                }

                let node = AVAudioPlayerNode()
                playerNode = node
                audioEngine.attach(node)
                audioEngine.connect(node, to: audioEngine.mainMixerNode, format: audioFile.processingFormat)

                if !audioEngine.isRunning {
                    try audioEngine.start()
                }

                node.scheduleFile(audioFile, at: nil, completionHandler: nil)
                node.play()
            } catch {
                print("❌ Failed to play audio: \(error)")
            }
        }
}







/*
class Recorder {
    private var outputContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation? = nil
    private let audioEngine: AVAudioEngine
    private let transcriber: SpokenWordTranscriber
    var playerNode: AVAudioPlayerNode?
    
    var recording: Binding<Recording>
    
    let bufferConverter = BufferConverter()

    var file: AVAudioFile?
    private let url: URL
    
    
    var audioFile: AVAudioFile?
    private var tempURL: URL!
    
    init(transcriber: SpokenWordTranscriber, recording: Binding<Recording>) {
        audioEngine = AVAudioEngine()
        self.transcriber = transcriber
        self.recording = recording
        self.url = FileManager.default.temporaryDirectory
            .appending(component: UUID().uuidString)
            .appendingPathExtension(for: .wav)
    }
    
//    func record() async throws {
//        self.recording.url.wrappedValue = url
//        guard await isAuthorized() else {
//            print("user denied mic permission")
//            return
//        }
//#if os(iOS)
//        try setUpAudioSession()
//#endif
//        try await transcriber.setUpTranscriber()
//        
//        for await input in try await audioStream() {
//            try await self.transcriber.streamAudioToTranscriber(input)
//        }
//    }
//    func startRecording() throws {
//        // 1. Set up audio session
//        #if os(iOS)
//        let audioSession = AVAudioSession.sharedInstance()
//        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
//        try audioSession.setActive(true)
//        #endif
//
//        // 2. Prepare file
//        let format = audioEngine.inputNode.outputFormat(forBus: 0)
//        file = try AVAudioFile(forWriting: url, settings: format.settings)
//
//        // 3. Install tap
//        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
//            do {
//                try self.file!.write(from: buffer)
//            } catch {
//                print("❌ Failed to write buffer: \(error)")
//            }
//        }
//
//        // 4. Start engine
//        audioEngine.prepare()
//        try audioEngine.start()
//    }
//
//    func stopRecording() {
//        audioEngine.stop()
//        audioEngine.inputNode.removeTap(onBus: 0)
//    }


    
//    func safePCMFormat() -> AVAudioFormat {
//        AVAudioFormat(commonFormat: .pcmFormatInt16,
//                      sampleRate: 44100,
//                      channels: 1,
//                      interleaved: true)!
//    }


    
    func startRecording() async throws {
        // Mic authorization
        guard await isAuthorized() else { return }
#if os(iOS)
        try setUpAudioSession()
#endif
        try await transcriber.setUpTranscriber()

        // Temp file
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        audioFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)

        // Remove previous tap if exists
        inputNode.removeTap(onBus: 0)

        // Install tap
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            do { try self.audioFile?.write(from: buffer) }
            catch { print("❌ Failed to write buffer: \(error)") }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopRecording() async throws -> URL {
        // Stop capturing
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        // Finish transcribing
        try await transcriber.finishTranscribing()

        // Suggested title
        Task {
            self.recording.title.wrappedValue = try await self.recording.wrappedValue.suggestedTitle()
                ?? self.recording.title.wrappedValue
        }

        // Return temp file URL
        return tempURL
    }

//    func playRecording(from url: URL) {
//        do {
//            let audioFile = try AVAudioFile(forReading: url)
//            playerNode = AVAudioPlayerNode()
//            guard let playerNode else { return }
//
//            audioEngine.attach(playerNode)
//            audioEngine.connect(playerNode, to: audioEngine.outputNode, format: audioFile.processingFormat)
//
////            playerNode.scheduleFile(audioFile, at: nil)
//            let buffer = try audioFile.toPCMBuffer()
//            let safeBuffer = try bufferConverter.convertBuffer(buffer, to: safePCMFormat())
//
//            playerNode.scheduleBuffer(safeBuffer, at: nil)
//
//            try audioEngine.start()
//            playerNode.play()
//        } catch {
//            print("❌ Failed to play audio: \(error)")
//        }
//    }

    func playRecording(from url: URL) {
        do {
            let audioFile = try AVAudioFile(forReading: url)  // ← THIS LINE
            playerNode = AVAudioPlayerNode()
            guard let playerNode else { return }

            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.outputNode, format: audioFile.processingFormat)

            playerNode.scheduleFile(audioFile, at: nil)
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("❌ Failed to play audio: \(error)")
        }
    }

    
    
    
    
//    func stopRecording() async throws -> URL {
//        audioEngine.stop()
//
//        // Finish transcribing
//        try await transcriber.finishTranscribing()
//
//        // Suggested title
//        Task {
//            self.recording.title.wrappedValue = try await recording.wrappedValue.suggestedTitle() ?? recording.title.wrappedValue
//        }
//
//        // Prepare permanent URL
//        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
//        let audioFile = try AVAudioFile(forWriting: tempURL,
//                                        settings: audioEngine.inputNode.outputFormat(forBus: 0).settings)
//
//        // Tap input node to write buffers
//        audioEngine.inputNode.installTap(onBus: 0,
//                                         bufferSize: 4096,
//                                         format: audioEngine.inputNode.outputFormat(forBus: 0)) { buffer, _ in
//            do {
//                try audioFile.write(from: buffer)
//            } catch {
//                print("❌ Failed to write buffer: \(error)")
//            }
//        }
//
//        audioEngine.inputNode.removeTap(onBus: 0)
//
//        return tempURL
//    }


    func playRecording() {
        let url = recording.fileURL.wrappedValue // else { return }

        do {
            let audioFile = try AVAudioFile(forReading: url)
            playerNode = AVAudioPlayerNode()
            guard let playerNode else { return }

            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.outputNode, format: audioFile.processingFormat)

            playerNode.scheduleFile(audioFile, at: nil)

            try audioEngine.start()
            playerNode.play()
        } catch {
            print("❌ Failed to play audio: \(error)")
        }
    }

    func pauseRecording() {
        audioEngine.pause()
    }
    
    func resumeRecording() throws {
        try audioEngine.start()
    }
#if os(iOS)
    func setUpAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
#endif
    
    private func audioStream() async throws -> AsyncStream<AVAudioPCMBuffer> {
        try setupAudioEngine()
        audioEngine.inputNode.installTap(onBus: 0,
                                         bufferSize: 4096,
                                         format: audioEngine.inputNode.outputFormat(forBus: 0)) { [weak self] (buffer, time) in
            guard let self else { return }
            writeBufferToDisk(buffer: buffer)
            self.outputContinuation?.yield(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return AsyncStream(AVAudioPCMBuffer.self, bufferingPolicy: .unbounded) {
            continuation in
            outputContinuation = continuation
        }
    }
    
    private func setupAudioEngine() throws {
        let inputSettings = audioEngine.inputNode.inputFormat(forBus: 0).settings
        self.file = try AVAudioFile(forWriting: url,
                                    settings: inputSettings)
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
//    func playRecording() {
//        guard let file else { return }
//        
//        playerNode = AVAudioPlayerNode()
//        guard let playerNode else { return }
//        
//        audioEngine.attach(playerNode)
//        audioEngine.connect(playerNode,
//                            to: audioEngine.outputNode,
//                            format: file.processingFormat)
//        
//        playerNode.scheduleFile(file,
//                                at: nil,
//                                completionCallbackType: .dataPlayedBack) { _ in
//        }
//        
//        do {
//            try audioEngine.start()
//            playerNode.play()
//        } catch {
//            print("error")
//        }
//    }
    

    
    func stopPlaying() {
        audioEngine.stop()
    }
}





import AVFoundation

extension AVAudioFile {
    func toPCMBuffer() throws -> AVAudioPCMBuffer {
        let format = processingFormat
        let frameCount = UInt32(length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "AVAudioFileExtension", code: -1, userInfo: nil)
        }
        try read(into: buffer)
        return buffer
    }
}

*/

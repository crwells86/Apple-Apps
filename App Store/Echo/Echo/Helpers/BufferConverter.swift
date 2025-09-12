import Foundation
import AVFoundation

//class BufferConverter {
//    enum Error: Swift.Error {
//        case failedToCreateConverter
//        case failedToCreateConversionBuffer
//        case conversionFailed(NSError?)
//    }
//    
//    private var converter: AVAudioConverter?
//    func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
//        let inputFormat = buffer.format
//        guard inputFormat != format else {
//            return buffer
//        }
//        
//        if converter == nil || converter?.outputFormat != format {
//            converter = AVAudioConverter(from: inputFormat, to: format)
//            converter?.primeMethod = .none
//        }
//        
//        guard let converter else {
//            throw Error.failedToCreateConverter
//        }
//        
//        let sampleRateRatio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
//        let scaledInputFrameLength = Double(buffer.frameLength) * sampleRateRatio
//        let frameCapacity = AVAudioFrameCount(scaledInputFrameLength.rounded(.up))
//        guard let conversionBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: frameCapacity) else {
//            throw Error.failedToCreateConversionBuffer
//        }
//        
//        var nsError: NSError?
//        var bufferProcessed = false
//        
//        let status = converter.convert(to: conversionBuffer, error: &nsError) { packetCount, inputStatusPointer in
//            defer { bufferProcessed = true }
//            inputStatusPointer.pointee = bufferProcessed ? .noDataNow : .haveData
//            return bufferProcessed ? nil : buffer
//        }
//        
//        guard status != .error else {
//            throw Error.conversionFailed(nsError)
//        }
//        
//        return conversionBuffer
//    }
//}

// --- BufferConverter (robust, ensures non-zero frameLength) ---
final class BufferConverter {
    enum Error: Swift.Error {
        case failedToCreateConverter
        case failedToCreateConversionBuffer
        case conversionFailed(NSError?)
        case zeroInputFrames
    }

    private var converter: AVAudioConverter?

    func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        guard buffer.frameLength > 0 else {
            throw Error.zeroInputFrames
        }

        let inputFormat = buffer.format
        if inputFormat == format {
            return buffer
        }

        // Create a fresh converter for these formats (safe)
        guard let conv = AVAudioConverter(from: inputFormat, to: format) else {
            throw Error.failedToCreateConverter
        }
        self.converter = conv

        // compute expected output frames (ceil to be safe)
        let sampleRateRatio = format.sampleRate / inputFormat.sampleRate
        let expectedFrames = AVAudioFrameCount(ceil(Double(buffer.frameLength) * sampleRateRatio))
        guard expectedFrames > 0 else {
            throw Error.failedToCreateConversionBuffer
        }

        guard let outBuf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: expectedFrames) else {
            throw Error.failedToCreateConversionBuffer
        }

        var nsErr: NSError?
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        let status = conv.convert(to: outBuf, error: &nsErr, withInputFrom: inputBlock)
        if status == .error {
            throw Error.conversionFailed(nsErr)
        }

        // The converter should set frameLength; if not, set a defensible value
        if outBuf.frameLength == 0 {
            outBuf.frameLength = min(outBuf.frameCapacity, AVAudioFrameCount(buffer.frameLength))
        }

        return outBuf
    }
}



extension Recorder {
    func isAuthorized() async -> Bool {
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            return true
        }
        return await AVCaptureDevice.requestAccess(for: .audio)
    }
    
//    func writeBufferToDisk(buffer: AVAudioPCMBuffer) {
//        do {
//            try self.file?.write(from: buffer)
//        } catch {
//            print("file writing error: \(error)")
//        }
//    }
    
    func safePCMFormat() -> AVAudioFormat {
        AVAudioFormat(commonFormat: .pcmFormatInt16,
                      sampleRate: 44100,
                      channels: 1,
                      interleaved: true)!
    }

    func writeBufferToDisk(buffer: AVAudioPCMBuffer) {
        do {
            let safeBuffer = try bufferConverter.convertBuffer(buffer, to: safePCMFormat())
            try audioFile?.write(from: safeBuffer)
        } catch {
            print("❌ Failed to write buffer: \(error)")
        }
    }



}


extension AVAudioPlayerNode {
    var currentTime: TimeInterval {
        guard let nodeTime: AVAudioTime = self.lastRenderTime, let playerTime: AVAudioTime = self.playerTime(forNodeTime: nodeTime) else { return 0 }
        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }
}

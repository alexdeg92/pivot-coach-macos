import ScreenCaptureKit
import AVFoundation
import Combine

@MainActor
class SystemAudioCapture: NSObject, ObservableObject {
    @Published var isCapturing = false
    @Published var audioLevel: Float = 0
    
    private var stream: SCStream?
    private var continuation: AsyncStream<AVAudioPCMBuffer>.Continuation?
    
    var audioStream: AsyncStream<AVAudioPCMBuffer> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    func startCapture() async throws {
        guard !isCapturing else { return }
        
        // Obtenir le contenu disponible
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        guard let display = content.displays.first else {
            throw CaptureError.noDisplay
        }
        
        // Filtre: capturer tout l'écran (inclut l'audio système)
        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        
        // Configuration audio
        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = true  // Ne pas capturer notre propre app
        config.sampleRate = 16000                   // 16kHz pour Whisper
        config.channelCount = 1                      // Mono
        
        // Créer le stream
        stream = SCStream(filter: filter, configuration: config, delegate: self)
        try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: .global(qos: .userInteractive))
        
        try await stream?.startCapture()
        isCapturing = true
    }
    
    func stopCapture() async {
        try? await stream?.stopCapture()
        stream = nil
        continuation?.finish()
        continuation = nil
        isCapturing = false
    }
}

// MARK: - SCStreamDelegate

extension SystemAudioCapture: SCStreamDelegate {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("❌ Stream stopped with error: \(error)")
        Task { @MainActor in
            self.isCapturing = false
        }
    }
}

// MARK: - SCStreamOutput

extension SystemAudioCapture: SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        
        // Convertir CMSampleBuffer → AVAudioPCMBuffer
        guard let pcmBuffer = sampleBuffer.toPCMBuffer() else { return }
        
        // Calculer le niveau audio
        let level = calculateRMS(pcmBuffer)
        Task { @MainActor in
            self.audioLevel = level
        }
        
        // Envoyer au stream
        continuation?.yield(pcmBuffer)
    }
    
    private func calculateRMS(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return 0 }
        
        var sum: Float = 0
        for i in 0..<frameCount {
            sum += channelData[i] * channelData[i]
        }
        
        return sqrt(sum / Float(frameCount))
    }
}

// MARK: - CMSampleBuffer Extension

extension CMSampleBuffer {
    func toPCMBuffer() -> AVAudioPCMBuffer? {
        guard let formatDesc = CMSampleBufferGetFormatDescription(self),
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) else {
            return nil
        }
        
        guard let format = AVAudioFormat(streamDescription: asbd) else { return nil }
        let frameCount = CMSampleBufferGetNumSamples(self)
        guard frameCount > 0 else { return nil }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        guard let blockBuffer = CMSampleBufferGetDataBuffer(self) else { return nil }
        
        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        let status = CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
        
        guard status == kCMBlockBufferNoErr, let data = dataPointer, let channelData = buffer.floatChannelData?[0] else {
            return nil
        }
        
        let bytesToCopy = min(length, Int(buffer.frameCapacity) * MemoryLayout<Float>.size)
        memcpy(channelData, data, bytesToCopy)
        
        return buffer
    }
}

// MARK: - Errors

enum CaptureError: Error, LocalizedError {
    case noDisplay
    case permissionDenied
    case streamFailed
    
    var errorDescription: String? {
        switch self {
        case .noDisplay: return "Aucun écran trouvé"
        case .permissionDenied: return "Permission refusée - autorise l'enregistrement d'écran dans System Settings"
        case .streamFailed: return "Échec du stream audio"
        }
    }
}

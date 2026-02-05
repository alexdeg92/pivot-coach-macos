import Foundation
import AVFoundation
import ScreenCaptureKit

@MainActor
class AudioCaptureManager: ObservableObject {
    @Published var isMicActive = false
    @Published var isSystemAudioActive = false
    @Published var audioLevel: Float = 0
    
    private var audioEngine: AVAudioEngine?
    private var micInput: AVAudioInputNode?
    private var stream: SCStream?
    private var streamOutput: AudioStreamOutput?
    
    // Audio buffer for Whisper
    var audioBuffer: [Float] = []
    private let bufferLock = NSLock()
    
    // Callback when audio chunk is ready
    var onAudioChunk: (([Float]) -> Void)?
    
    // MARK: - Microphone
    
    func requestMicPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            await startMicCapture()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            if granted {
                await startMicCapture()
            }
        default:
            print("Microphone permission denied")
        }
    }
    
    private func startMicCapture() async {
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }
        
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        // Install tap for audio processing
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try engine.start()
            isMicActive = true
            print("Microphone capture started")
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        
        // Convert to mono Float array
        var samples = [Float](repeating: 0, count: frameCount)
        for i in 0..<frameCount {
            samples[i] = channelData[i]
        }
        
        // Resample to 16kHz if needed (Whisper requirement)
        let resampledSamples = resampleTo16kHz(samples, from: buffer.format.sampleRate)
        
        // Add to buffer
        bufferLock.lock()
        audioBuffer.append(contentsOf: resampledSamples)
        
        // When we have ~3 seconds of audio, trigger callback
        if audioBuffer.count >= 16000 * 3 {
            let chunk = Array(audioBuffer.prefix(16000 * 3))
            audioBuffer.removeFirst(16000 * 2) // Keep 1s overlap
            bufferLock.unlock()
            
            onAudioChunk?(chunk)
        } else {
            bufferLock.unlock()
        }
        
        // Update audio level for UI
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(frameCount))
        DispatchQueue.main.async {
            self.audioLevel = rms
        }
    }
    
    private func resampleTo16kHz(_ samples: [Float], from sampleRate: Double) -> [Float] {
        let ratio = 16000.0 / sampleRate
        if ratio == 1.0 { return samples }
        
        let outputCount = Int(Double(samples.count) * ratio)
        var output = [Float](repeating: 0, count: outputCount)
        
        for i in 0..<outputCount {
            let srcIndex = Double(i) / ratio
            let low = Int(srcIndex)
            let high = min(low + 1, samples.count - 1)
            let frac = Float(srcIndex - Double(low))
            output[i] = samples[low] * (1 - frac) + samples[high] * frac
        }
        
        return output
    }
    
    // MARK: - System Audio (ScreenCaptureKit)
    
    func getAvailableWindows() async -> [SCWindow] {
        do {
            let content = try await SCShareableContent.current
            return content.windows.filter { $0.isOnScreen && $0.title != nil && !$0.title!.isEmpty }
        } catch {
            print("Failed to get windows: \(error)")
            return []
        }
    }
    
    func captureWindowAudio(_ window: SCWindow) async {
        do {
            let filter = SCContentFilter(desktopIndependentWindow: window)
            
            let config = SCStreamConfiguration()
            config.capturesAudio = true
            config.excludesCurrentProcessAudio = true
            config.sampleRate = 16000 // Whisper optimal
            config.channelCount = 1
            
            // We need minimal video to satisfy the API
            config.width = 2
            config.height = 2
            config.minimumFrameInterval = CMTime(value: 1, timescale: 1) // 1 fps
            
            streamOutput = AudioStreamOutput { [weak self] samples in
                self?.processSystemAudioSamples(samples)
            }
            
            stream = SCStream(filter: filter, configuration: config, delegate: nil)
            try stream?.addStreamOutput(streamOutput!, type: .audio, sampleHandlerQueue: .global())
            
            try await stream?.startCapture()
            
            await MainActor.run {
                isSystemAudioActive = true
            }
            print("System audio capture started for: \(window.title ?? "Unknown")")
            
        } catch {
            print("Failed to capture window audio: \(error)")
        }
    }
    
    private func processSystemAudioSamples(_ samples: [Float]) {
        bufferLock.lock()
        audioBuffer.append(contentsOf: samples)
        
        if audioBuffer.count >= 16000 * 3 {
            let chunk = Array(audioBuffer.prefix(16000 * 3))
            audioBuffer.removeFirst(16000 * 2)
            bufferLock.unlock()
            
            onAudioChunk?(chunk)
        } else {
            bufferLock.unlock()
        }
    }
    
    // MARK: - Cleanup
    
    func stopCapture() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        isMicActive = false
        
        Task {
            try? await stream?.stopCapture()
            stream = nil
            await MainActor.run {
                isSystemAudioActive = false
            }
        }
    }
}

// MARK: - Stream Output Handler

class AudioStreamOutput: NSObject, SCStreamOutput {
    let onAudioSamples: ([Float]) -> Void
    
    init(onAudioSamples: @escaping ([Float]) -> Void) {
        self.onAudioSamples = onAudioSamples
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        
        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
        
        guard let data = dataPointer else { return }
        
        // Convert to Float array (assuming 32-bit float PCM)
        let floatCount = length / MemoryLayout<Float>.size
        let floatBuffer = data.withMemoryRebound(to: Float.self, capacity: floatCount) { ptr in
            Array(UnsafeBufferPointer(start: ptr, count: floatCount))
        }
        
        onAudioSamples(floatBuffer)
    }
}

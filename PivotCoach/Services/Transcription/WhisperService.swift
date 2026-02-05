import WhisperKit
import AVFoundation
import Combine

@MainActor
class WhisperService: ObservableObject {
    @Published var isReady = false
    @Published var latestTranscript = ""
    @Published var fullTranscript = ""
    
    private var whisperKit: WhisperKit?
    private var audioBuffer: [Float] = []
    private let bufferLock = NSLock()
    private let sampleRate = 16000
    
    // MARK: - Initialization
    
    func initialize() async throws {
        // Télécharge le modèle si nécessaire (~150MB pour "base")
        whisperKit = try await WhisperKit(
            model: "base",  // Options: tiny, base, small, medium, large
            computeOptions: .init(
                melCompute: .cpuAndGPU,
                audioEncoderCompute: .cpuAndGPU,
                textDecoderCompute: .cpuAndGPU
            )
        )
        isReady = true
    }
    
    // MARK: - Audio Processing
    
    func processAudioStream(_ stream: AsyncStream<AVAudioPCMBuffer>) async {
        for await buffer in stream {
            appendToBuffer(buffer)
            
            // Transcrire quand on a ~1.5 secondes d'audio
            if audioBuffer.count >= Int(Double(sampleRate) * 1.5) {
                await transcribeBuffer()
            }
        }
    }
    
    private func appendToBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        
        bufferLock.lock()
        for i in 0..<frameCount {
            audioBuffer.append(channelData[i])
        }
        bufferLock.unlock()
    }
    
    private func transcribeBuffer() async {
        bufferLock.lock()
        let samples = Array(audioBuffer)
        // Sliding window: garder 0.5s d'overlap pour continuité
        let overlapSamples = sampleRate / 2
        if audioBuffer.count > overlapSamples {
            audioBuffer = Array(audioBuffer.suffix(overlapSamples))
        }
        bufferLock.unlock()
        
        guard let whisper = whisperKit, !samples.isEmpty else { return }
        
        do {
            let results = try await whisper.transcribe(
                audioArray: samples,
                decodeOptions: .init(
                    language: "fr",
                    task: .transcribe,
                    temperatureFallbackCount: 3,
                    compressionRatioThreshold: 2.4,
                    logProbThreshold: -1.0,
                    firstTokenLogProbThreshold: -1.5,
                    noSpeechThreshold: 0.6
                )
            )
            
            if let text = results.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
               !text.isEmpty,
               !isNoiseOrSilence(text) {
                latestTranscript = text
                fullTranscript += text + " "
            }
        } catch {
            print("❌ Whisper error: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func isNoiseOrSilence(_ text: String) -> Bool {
        // Filtrer les faux positifs communs de Whisper
        let noise = ["[BLANK_AUDIO]", "[MUSIC]", "[SILENCE]", "...", "…", 
                     "Sous-titres réalisés", "Merci d'avoir regardé", "♪"]
        return noise.contains { text.contains($0) } || text.count < 3
    }
    
    func reset() {
        bufferLock.lock()
        audioBuffer.removeAll()
        bufferLock.unlock()
        latestTranscript = ""
        fullTranscript = ""
    }
}

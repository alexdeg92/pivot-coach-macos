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
    private let sampleRate = 16000
    
    // Use actor for thread-safe buffer management
    private let bufferManager = AudioBufferManager()
    
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
            await bufferManager.append(buffer)
            
            // Transcrire quand on a ~1.5 secondes d'audio
            let count = await bufferManager.count
            if count >= Int(Double(sampleRate) * 1.5) {
                await transcribeBuffer()
            }
        }
    }
    
    private func transcribeBuffer() async {
        let samples = await bufferManager.getSamplesAndTrim(keepLast: sampleRate / 2)
        
        guard let whisper = whisperKit, !samples.isEmpty else { return }
        
        do {
            let results = try await whisper.transcribe(
                audioArray: samples,
                decodeOptions: .init(
                    task: .transcribe,
                    language: "fr",
                    temperatureFallbackCount: 3,
                    compressionRatioThreshold: 2.4,
                    logProbThreshold: -1.0,
                    firstTokenLogProbThreshold: -1.5,
                    noSpeechThreshold: 0.6
                )
            )
            
            if let result = results.first {
                let text = result.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if !text.isEmpty && !isNoiseOrSilence(text) {
                    latestTranscript = text
                    fullTranscript += text + " "
                }
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
        Task {
            await bufferManager.clear()
        }
        latestTranscript = ""
        fullTranscript = ""
    }
}

// MARK: - Thread-safe Audio Buffer Manager

private actor AudioBufferManager {
    private var buffer: [Float] = []
    
    var count: Int {
        buffer.count
    }
    
    func append(_ pcmBuffer: AVAudioPCMBuffer) {
        guard let channelData = pcmBuffer.floatChannelData?[0] else { return }
        let frameCount = Int(pcmBuffer.frameLength)
        
        for i in 0..<frameCount {
            buffer.append(channelData[i])
        }
    }
    
    func getSamplesAndTrim(keepLast: Int) -> [Float] {
        let samples = Array(buffer)
        // Sliding window: garder keepLast samples d'overlap
        if buffer.count > keepLast {
            buffer = Array(buffer.suffix(keepLast))
        }
        return samples
    }
    
    func clear() {
        buffer.removeAll()
    }
}

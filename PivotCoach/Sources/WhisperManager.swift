import Foundation

/// Whisper Manager - Integrates with whisper.cpp for local speech-to-text
/// 
/// Setup:
/// 1. Clone whisper.cpp: git clone https://github.com/ggerganov/whisper.cpp
/// 2. Build: cd whisper.cpp && make -j
/// 3. Download model: ./models/download-ggml-model.sh base
/// 4. Set WHISPER_CPP_PATH environment variable or place in app bundle
@MainActor
class WhisperManager: ObservableObject {
    @Published var isReady = false
    @Published var isLoading = false
    @Published var statusMessage = "Non initialisé"
    @Published var currentTranscript = ""
    
    private var whisperProcess: Process?
    private var modelPath: String?
    private var whisperPath: String?
    
    // Callback for new transcriptions
    var onTranscription: ((String) -> Void)?
    
    init() {
        findWhisperInstallation()
    }
    
    private func findWhisperInstallation() {
        // Check common locations
        let possiblePaths = [
            "/usr/local/bin/whisper",
            "/opt/homebrew/bin/whisper",
            "\(NSHomeDirectory())/whisper.cpp/main",
            "\(NSHomeDirectory())/whisper.cpp/build/bin/main",
            Bundle.main.path(forResource: "whisper", ofType: nil)
        ].compactMap { $0 }
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                whisperPath = path
                statusMessage = "whisper.cpp trouvé"
                break
            }
        }
        
        // Check for model
        let modelPaths = [
            "\(NSHomeDirectory())/whisper.cpp/models/ggml-base.bin",
            "\(NSHomeDirectory())/whisper.cpp/models/ggml-small.bin",
            "/usr/local/share/whisper/ggml-base.bin",
            Bundle.main.path(forResource: "ggml-base", ofType: "bin")
        ].compactMap { $0 }
        
        for path in modelPaths {
            if FileManager.default.fileExists(atPath: path) {
                modelPath = path
                break
            }
        }
        
        if whisperPath == nil {
            statusMessage = "Installer whisper.cpp"
        } else if modelPath == nil {
            statusMessage = "Télécharger modèle"
        }
    }
    
    func loadModel() async {
        isLoading = true
        statusMessage = "Chargement..."
        
        // If whisper.cpp not found, provide instructions
        guard whisperPath != nil else {
            statusMessage = "Installer: brew install whisper-cpp"
            isLoading = false
            return
        }
        
        guard modelPath != nil else {
            statusMessage = "Modèle requis: ggml-base.bin"
            isLoading = false
            return
        }
        
        // Verify whisper works
        let testResult = await testWhisper()
        
        if testResult {
            isReady = true
            statusMessage = "Prêt"
        } else {
            statusMessage = "Erreur whisper.cpp"
        }
        
        isLoading = false
    }
    
    private func testWhisper() async -> Bool {
        guard let whisper = whisperPath, let model = modelPath else { return false }
        
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: whisper)
            process.arguments = ["--help"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                continuation.resume(returning: process.terminationStatus == 0)
            } catch {
                continuation.resume(returning: false)
            }
        }
    }
    
    /// Transcribe audio samples (16kHz mono Float)
    func transcribe(_ samples: [Float]) async -> String? {
        guard isReady, let whisper = whisperPath, let model = modelPath else { return nil }
        
        // Write samples to temporary WAV file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("whisper_input.wav")
        
        do {
            try writeWAV(samples: samples, to: tempURL)
        } catch {
            print("Failed to write WAV: \(error)")
            return nil
        }
        
        // Run whisper.cpp
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: whisper)
            process.arguments = [
                "-m", model,
                "-f", tempURL.path,
                "-l", "fr",  // French
                "-nt",       // No timestamps
                "--no-prints"
            ]
            
            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = FileHandle.nullDevice
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Clean up
                try? FileManager.default.removeItem(at: tempURL)
                
                continuation.resume(returning: output)
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// Write Float samples to WAV file (16-bit PCM, 16kHz mono)
    private func writeWAV(samples: [Float], to url: URL) throws {
        var data = Data()
        
        // WAV header
        let sampleRate: UInt32 = 16000
        let bitsPerSample: UInt16 = 16
        let channels: UInt16 = 1
        let byteRate = sampleRate * UInt32(channels) * UInt32(bitsPerSample) / 8
        let blockAlign = channels * bitsPerSample / 8
        let dataSize = UInt32(samples.count * 2)
        let fileSize = 36 + dataSize
        
        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        
        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // PCM
        data.append(contentsOf: withUnsafeBytes(of: channels.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })
        
        // data chunk
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })
        
        // Convert Float to Int16 and append
        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let int16 = Int16(clamped * 32767)
            data.append(contentsOf: withUnsafeBytes(of: int16.littleEndian) { Array($0) })
        }
        
        try data.write(to: url)
    }
}

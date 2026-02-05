import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioCapture: AudioCaptureManager
    @EnvironmentObject var whisperManager: WhisperManager
    @EnvironmentObject var ollamaClient: OllamaClient
    @EnvironmentObject var coachState: CoachState
    
    @State private var showSetup = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            TitleBar()
            
            // Status bar
            StatusBar()
            
            if showSetup {
                SetupView(showSetup: $showSetup)
            } else {
                CallView(showSetup: $showSetup)
            }
        }
        .frame(width: 400, height: 600)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Title Bar
struct TitleBar: View {
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text("🎯")
                Text("Pivot Coach")
                    .font(.system(size: 13, weight: .semibold))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 12, height: 12)
                    .onTapGesture {
                        NSApp.keyWindow?.miniaturize(nil)
                    }
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .onTapGesture {
                        NSApp.keyWindow?.close()
                    }
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(Color.black.opacity(0.2))
    }
}

// MARK: - Status Bar
struct StatusBar: View {
    @EnvironmentObject var audioCapture: AudioCaptureManager
    @EnvironmentObject var whisperManager: WhisperManager
    @EnvironmentObject var ollamaClient: OllamaClient
    @EnvironmentObject var coachState: CoachState
    
    var body: some View {
        HStack(spacing: 12) {
            StatusItem(label: "Micro", isActive: audioCapture.isMicActive)
            StatusItem(label: "Audio", isActive: audioCapture.isSystemAudioActive)
            StatusItem(label: "Whisper", isActive: whisperManager.isReady)
            StatusItem(label: "Ollama", isActive: ollamaClient.isConnected)
            StatusItem(label: "Appel", isActive: coachState.isCallActive)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .font(.system(size: 11))
        .foregroundColor(.white.opacity(0.7))
        .background(Color.black.opacity(0.1))
    }
}

struct StatusItem: View {
    let label: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.white.opacity(0.3))
                .frame(width: 6, height: 6)
                .shadow(color: isActive ? .green : .clear, radius: 3)
            
            Text(label)
        }
    }
}

// MARK: - Setup View
struct SetupView: View {
    @Binding var showSetup: Bool
    @EnvironmentObject var audioCapture: AudioCaptureManager
    @EnvironmentObject var whisperManager: WhisperManager
    @EnvironmentObject var ollamaClient: OllamaClient
    
    @State private var selectedSource: SCWindow?
    @State private var availableSources: [SCWindow] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Step 1: Microphone
                SetupStep(
                    number: audioCapture.isMicActive ? "✓" : "1",
                    title: "Microphone",
                    status: audioCapture.isMicActive ? "Activé" : "En attente...",
                    isDone: audioCapture.isMicActive
                ) {
                    Button("Activer") {
                        Task { await audioCapture.requestMicPermission() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(audioCapture.isMicActive)
                }
                
                // Step 2: Whisper
                SetupStep(
                    number: whisperManager.isReady ? "✓" : "2",
                    title: "Whisper (STT local)",
                    status: whisperManager.isReady ? "Prêt" : whisperManager.statusMessage,
                    isDone: whisperManager.isReady
                ) {
                    Button("Charger") {
                        Task { await whisperManager.loadModel() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(whisperManager.isReady || whisperManager.isLoading)
                }
                
                // Step 3: Ollama
                SetupStep(
                    number: ollamaClient.isConnected ? "✓" : "3",
                    title: "Ollama (LLM local)",
                    status: ollamaClient.isConnected ? "Connecté" : "Vérifier: ollama serve",
                    isDone: ollamaClient.isConnected
                ) {
                    Button("Vérifier") {
                        Task { await ollamaClient.checkConnection() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Step 4: Audio Source
                SetupStep(
                    number: audioCapture.isSystemAudioActive ? "✓" : "4",
                    title: "Source Audio Système",
                    status: selectedSource?.title ?? "Sélectionner une fenêtre",
                    isDone: audioCapture.isSystemAudioActive
                ) {
                    EmptyView()
                }
                
                // Source picker
                Picker("Source", selection: $selectedSource) {
                    Text("Choisir une fenêtre...").tag(nil as SCWindow?)
                    ForEach(availableSources, id: \.self) { source in
                        Text(source.title ?? "Sans titre").tag(source as SCWindow?)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedSource) { newValue in
                    if let source = newValue {
                        Task { await audioCapture.captureWindowAudio(source) }
                    }
                }
                
                Spacer()
                
                // Start button
                Button {
                    showSetup = false
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Démarrer l'appel")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(!isReady)
            }
            .padding()
        }
        .task {
            availableSources = await audioCapture.getAvailableWindows()
            await ollamaClient.checkConnection()
        }
    }
    
    var isReady: Bool {
        audioCapture.isMicActive && whisperManager.isReady && ollamaClient.isConnected
    }
}

struct SetupStep<Content: View>: View {
    let number: String
    let title: String
    let status: String
    let isDone: Bool
    @ViewBuilder let action: Content
    
    var body: some View {
        HStack {
            Text(number)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 24, height: 24)
                .background(isDone ? Color.green : Color.purple)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(status)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            action
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Call View
struct CallView: View {
    @Binding var showSetup: Bool
    @EnvironmentObject var coachState: CoachState
    @EnvironmentObject var whisperManager: WhisperManager
    @EnvironmentObject var ollamaClient: OllamaClient
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Transcription
                Card(icon: "📝", title: "TRANSCRIPTION") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(coachState.transcriptLines.suffix(5)) { line in
                            TranscriptLine(speaker: line.speaker, text: line.text)
                        }
                        
                        if coachState.transcriptLines.isEmpty {
                            Text("En attente de transcription...")
                                .foregroundColor(.white.opacity(0.4))
                                .font(.system(size: 13))
                        }
                    }
                }
                
                // Suggestion
                Card(icon: "💡", title: "SUGGESTION IA", isHighlighted: true) {
                    VStack(alignment: .leading, spacing: 10) {
                        if coachState.isGenerating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Analyse...")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        } else {
                            Text(coachState.currentSuggestion)
                                .font(.system(size: 14))
                                .lineSpacing(4)
                        }
                        
                        HStack(spacing: 8) {
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(coachState.currentSuggestion, forType: .string)
                            } label: {
                                Label("Copier", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                Task { await regenerateSuggestion() }
                            } label: {
                                Label("Reformuler", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // Analysis
                Card(icon: "📊", title: "ANALYSE") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        AnalysisItem(label: "Objection", value: coachState.analysis.objection ?? "—")
                        AnalysisItem(label: "Besoin", value: coachState.analysis.besoin ?? "—")
                        ProgressItem(label: "Intérêt", value: coachState.analysis.interet, max: 10)
                        ProgressItem(label: "Closing", value: coachState.analysis.closingProb, max: 100)
                    }
                }
                
                // Stop button
                Button {
                    coachState.stopCall()
                    showSetup = true
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Arrêter l'appel")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .onAppear {
            coachState.startCall()
        }
    }
    
    func regenerateSuggestion() async {
        let conversation = coachState.transcriptLines.map { "\($0.speaker): \($0.text)" }.joined(separator: "\n")
        await ollamaClient.generateSuggestion(conversation: conversation) { result in
            coachState.updateFromLLM(result)
        }
    }
}

struct TranscriptLine: View {
    let speaker: String
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(speaker.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(speaker == "Vous" ? .purple : .orange)
            Text(text)
                .font(.system(size: 13))
        }
    }
}

struct Card<Content: View>: View {
    let icon: String
    let title: String
    var isHighlighted: Bool = false
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(icon)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isHighlighted
                ? LinearGradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.purple.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct AnalysisItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 13, weight: .semibold))
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ProgressItem: View {
    let label: String
    let value: Int
    let max: Int
    
    var percentage: CGFloat {
        CGFloat(value) / CGFloat(max)
    }
    
    var color: Color {
        if percentage >= 0.6 { return .green }
        if percentage >= 0.3 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * percentage)
                }
            }
            .frame(height: 4)
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Visual Effect View
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

#Preview {
    ContentView()
        .environmentObject(AudioCaptureManager())
        .environmentObject(WhisperManager())
        .environmentObject(OllamaClient())
        .environmentObject(CoachState())
}

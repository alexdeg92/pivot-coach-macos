import SwiftUI
import Combine

@MainActor
class CoachViewModel: ObservableObject {
    static let shared = CoachViewModel()
    
    // MARK: - Published State
    @Published var isListening = false
    @Published var isReady = false
    @Published var transcript = ""
    @Published var clientSaid = ""
    @Published var suggestion = ""
    @Published var intent = ""
    @Published var emotion = "neutral"
    @Published var closingProbability = 50
    @Published var currentContact: Contact?
    @Published var stealthMode = false
    @Published var audioLevel: Float = 0
    @Published var ollamaAvailable = false
    @Published var hubspotConnected = false
    
    // Setup/Call mode
    @Published var showSetup = true
    @Published var selectedHubSpotContact: HubSpotContact?
    @Published var additionalContext = ""
    
    // MARK: - Services
    private let audioCapture = SystemAudioCapture()
    private let whisperService = WhisperService()
    private let ollamaService = OllamaService()
    private var vectorStore: VectorStore?
    
    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private var processingTask: Task<Void, Never>?
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Audio level
        audioCapture.$audioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.audioLevel = level
            }
            .store(in: &cancellables)
        
        // Transcription → Process
        whisperService.$latestTranscript
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                guard !text.isEmpty else { return }
                self?.clientSaid = text
                self?.transcript += text + " "
                self?.processTranscript(text)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        do {
            // Init Whisper
            try await whisperService.initialize()
            print("✅ WhisperKit initialisé")
            
            // Init Vector Store
            let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let appDir = supportDir.appendingPathComponent("PivotCoach", isDirectory: true)
            try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
            let dbPath = appDir.appendingPathComponent("vectors.db").path
            vectorStore = try VectorStore(dbPath: dbPath)
            print("✅ Vector Store initialisé")
            
            // Check Ollama
            ollamaAvailable = await ollamaService.isAvailable()
            if ollamaAvailable {
                print("✅ Ollama disponible")
            } else {
                print("⚠️ Ollama non disponible - lance 'ollama serve'")
            }
            
            isReady = true
        } catch {
            print("❌ Erreur init: \(error)")
        }
    }
    
    // MARK: - Audio Control
    
    func startListening() async {
        guard isReady else {
            print("⚠️ Pas prêt - appelle initialize() d'abord")
            return
        }
        
        do {
            try await audioCapture.startCapture()
            isListening = true
            
            // Pipe audio vers Whisper
            processingTask = Task {
                await whisperService.processAudioStream(audioCapture.audioStream)
            }
            
            print("🎙️ Écoute démarrée")
        } catch {
            print("❌ Erreur capture: \(error)")
        }
    }
    
    func stopListening() async {
        processingTask?.cancel()
        await audioCapture.stopCapture()
        isListening = false
        print("⏹️ Écoute arrêtée")
    }
    
    // MARK: - Transcript Processing
    
    private func processTranscript(_ text: String) {
        guard ollamaAvailable else {
            suggestion = "⚠️ Ollama non disponible. Lance 'ollama serve' dans le terminal."
            return
        }
        
        Task {
            // 1. RAG lookup
            let ragContext = vectorStore?.search(query: text, contactId: currentContact?.id, limit: 3)
                .map { $0.content }
                .joined(separator: "\n") ?? ""
            
            // 2. Build prompt
            let systemPrompt = buildSystemPrompt(ragContext: ragContext)
            let userPrompt = "Le client dit: \"\(text)\""
            
            // 3. Stream response
            suggestion = ""
            do {
                for try await token in ollamaService.generateStream(prompt: userPrompt, system: systemPrompt) {
                    suggestion += token
                }
            } catch {
                print("❌ Ollama error: \(error)")
            }
            
            // 4. Analyze intent
            analyzeIntent(text)
        }
    }
    
    private func buildSystemPrompt(ragContext: String) -> String {
        var prompt = """
        Tu es un coach commercial expert pour Pivot, un logiciel de gestion pour restaurants.
        
        RÈGLES STRICTES:
        - Réponses COURTES: 2-3 phrases maximum
        - Focus sur la VALEUR pour le client
        - Si objection → reformuler en opportunité
        - Terminer par une question ouverte OU un call-to-action clair
        - Ton professionnel mais chaleureux
        - Ne jamais mentir ou exagérer
        """
        
        // HubSpot contact info
        if let contact = selectedHubSpotContact {
            prompt += """
            
            
            CLIENT ACTUEL (HubSpot):
            - Nom: \(contact.fullName)
            - Entreprise: \(contact.company)
            - Email: \(contact.email)
            - Statut: \(contact.leadStatus ?? "Non défini")
            """
        } else if let contact = currentContact {
            prompt += """
            
            
            CLIENT ACTUEL:
            - Nom: \(contact.firstName) \(contact.lastName)
            - Entreprise: \(contact.company)
            - Stade: \(contact.dealStage ?? "Inconnu")
            """
        }
        
        // Additional context from user
        if !additionalContext.isEmpty {
            prompt += """
            
            
            CONTEXTE ADDITIONNEL:
            \(additionalContext)
            """
        }
        
        if !ragContext.isEmpty {
            prompt += """
            
            
            HISTORIQUE (notes précédentes):
            \(ragContext)
            """
        }
        
        return prompt
    }
    
    private func analyzeIntent(_ text: String) {
        let lower = text.lowercased()
        
        // Détection d'intent basée sur des règles
        if lower.contains("prix") || lower.contains("combien") || lower.contains("coût") || lower.contains("tarif") {
            intent = "Question prix"
            emotion = "neutral"
            closingProbability = 40
        } else if lower.contains("intéress") || lower.contains("parfait") || lower.contains("super") || lower.contains("génial") {
            intent = "Signal d'intérêt"
            emotion = "positive"
            closingProbability = 70
        } else if lower.contains("mais") || lower.contains("cependant") || lower.contains("problème") || lower.contains("difficile") {
            intent = "Objection"
            emotion = "sceptique"
            closingProbability = 30
        } else if lower.contains("quand") || lower.contains("comment") || lower.contains("déploie") || lower.contains("implément") {
            intent = "Question technique"
            emotion = "neutral"
            closingProbability = 55
        } else if lower.contains("concurrent") || lower.contains("autre solution") || lower.contains("déjà") {
            intent = "Comparaison concurrence"
            emotion = "sceptique"
            closingProbability = 35
        } else if lower.contains("essai") || lower.contains("tester") || lower.contains("démo") {
            intent = "Demande démo"
            emotion = "positive"
            closingProbability = 65
        } else if lower.contains("ok") || lower.contains("d'accord") || lower.contains("allons-y") || lower.contains("on signe") {
            intent = "Signal de closing"
            emotion = "positive"
            closingProbability = 85
        } else {
            intent = "Neutre"
            emotion = "neutral"
            closingProbability = 50
        }
    }
    
    // MARK: - Actions
    
    func copySuggestion() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(suggestion, forType: .string)
    }
    
    func regenerateSuggestion() {
        guard !clientSaid.isEmpty else { return }
        processTranscript(clientSaid)
    }
    
    func shortenSuggestion() {
        guard !suggestion.isEmpty else { return }
        Task {
            let shortened = try? await ollamaService.generate(
                prompt: "Raccourcis cette réponse en 1 phrase max, garde l'essentiel:\n\(suggestion)",
                system: "Tu raccourcis des textes. Réponse directe sans introduction."
            )
            if let shortened = shortened {
                suggestion = shortened
            }
        }
    }
    
    func toggleOverlay() {
        print("🔄 toggleOverlay appelé")
        if let appDelegate = NSApp.delegate as? AppDelegate {
            print("✅ AppDelegate trouvé")
            if let controller = appDelegate.overlayController {
                print("✅ OverlayController trouvé, toggle...")
                controller.toggle()
            } else {
                print("❌ overlayController est nil!")
            }
        } else {
            print("❌ AppDelegate non trouvé")
        }
    }
    
    func showSummary() {
        // TODO: Afficher un résumé de la conversation
        print("📄 Résumé de la conversation...")
    }
    
    func showSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    // MARK: - HubSpot
    
    func syncHubSpotContacts() async {
        // TODO: Implémenter la sync HubSpot
    }
    
    func selectContact(_ contact: Contact) {
        currentContact = contact
    }
    
    // MARK: - Reset
    
    func resetConversation() {
        transcript = ""
        clientSaid = ""
        suggestion = ""
        intent = ""
        emotion = "neutral"
        closingProbability = 50
        whisperService.reset()
    }
}

import Foundation

@MainActor
class CoachState: ObservableObject {
    @Published var isCallActive = false
    @Published var transcriptLines: [TranscriptLine] = []
    @Published var currentSuggestion = "Commencez à parler pour recevoir des suggestions..."
    @Published var isGenerating = false
    @Published var analysis = AnalysisState()
    
    private var conversationBuffer: [String] = []
    
    struct TranscriptLine: Identifiable {
        let id = UUID()
        let speaker: String
        let text: String
        let timestamp: Date
    }
    
    struct AnalysisState {
        var objection: String?
        var besoin: String?
        var interet: Int = 0
        var closingProb: Int = 0
    }
    
    func startCall() {
        isCallActive = true
        transcriptLines = []
        currentSuggestion = "En attente de transcription..."
        analysis = AnalysisState()
    }
    
    func stopCall() {
        isCallActive = false
    }
    
    func addTranscript(speaker: String, text: String) {
        let line = TranscriptLine(speaker: speaker, text: text, timestamp: Date())
        transcriptLines.append(line)
        
        // Keep last 20 lines
        if transcriptLines.count > 20 {
            transcriptLines.removeFirst(transcriptLines.count - 20)
        }
        
        // Add to conversation buffer for LLM context
        conversationBuffer.append("\(speaker): \(text)")
        if conversationBuffer.count > 30 {
            conversationBuffer.removeFirst()
        }
    }
    
    func getConversationContext() -> String {
        return conversationBuffer.joined(separator: "\n")
    }
    
    func updateFromLLM(_ response: LLMResponse) {
        if let error = response.error {
            currentSuggestion = "Erreur: \(error)"
            return
        }
        
        currentSuggestion = response.suggestion
        
        analysis.objection = response.objection
        analysis.besoin = response.besoin
        analysis.interet = response.interet
        analysis.closingProb = response.closingProb
    }
    
    func setSuggestion(_ text: String) {
        currentSuggestion = text
    }
    
    func setGenerating(_ value: Bool) {
        isGenerating = value
    }
}

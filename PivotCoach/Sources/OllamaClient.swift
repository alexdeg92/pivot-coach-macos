import Foundation

/// Ollama Client for local LLM inference
/// 
/// Setup:
/// 1. Install: brew install ollama
/// 2. Start server: ollama serve
/// 3. Pull model: ollama pull mistral:7b-instruct-q4_K_M
@MainActor
class OllamaClient: ObservableObject {
    @Published var isConnected = false
    @Published var availableModels: [String] = []
    @Published var currentModel = "mistral:7b-instruct-q4_K_M"
    @Published var isGenerating = false
    
    private let baseURL = "http://localhost:11434"
    
    // System prompt for sales coaching
    let systemPrompt = """
    Tu es un coach commercial expert en vente B2B SaaS pour restaurants.
    
    CONTEXTE PRODUIT - PIVOT:
    - Logiciel de gestion RH pour restaurants (horaires, paie, intégrations POS)
    - Prix: 200-500$/mois selon taille du restaurant
    - Concurrents: 7shifts, HotSchedules, When I Work
    - Avantages clés: 
      • Intégrations POS natives (Clover, Lightspeed, Maitre'D)
      • Support local Québec
      • Interface en français
      • Calcul automatique des tips et tip-out
    
    OBJECTIFS:
    1. Analyser chaque échange de la conversation
    2. Détecter les objections, besoins et signaux d'achat
    3. Suggérer la meilleure réponse commerciale
    
    FORMAT DE RÉPONSE (JSON strict):
    {
      "objection": "type d'objection ou null",
      "besoin": "besoin principal détecté",
      "interet": 7,
      "closing_prob": 60,
      "suggestion": "Votre suggestion de réponse commerciale (2-3 phrases max)"
    }
    
    TYPES D'OBJECTIONS COURANTS:
    - Prix trop élevé
    - Déjà un système en place
    - Pas le temps de changer
    - Besoin de consulter l'équipe
    - Fonctionnalité manquante
    
    Réponds UNIQUEMENT avec le JSON, sans texte additionnel.
    """
    
    // MARK: - Connection
    
    func checkConnection() async {
        do {
            let url = URL(string: "\(baseURL)/api/tags")!
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                isConnected = false
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                availableModels = models.compactMap { $0["name"] as? String }
                
                // Check if we have a usable model
                let hasUsableModel = availableModels.contains { 
                    $0.contains("mistral") || $0.contains("llama") || $0.contains("qwen")
                }
                
                if hasUsableModel {
                    isConnected = true
                    // Use the best available model
                    if let model = availableModels.first(where: { $0.contains("mistral") }) {
                        currentModel = model
                    }
                }
            }
        } catch {
            print("Ollama connection error: \(error)")
            isConnected = false
        }
    }
    
    // MARK: - Generation
    
    func generateSuggestion(conversation: String, completion: @escaping (LLMResponse) -> Void) async {
        guard isConnected else {
            completion(LLMResponse(error: "Ollama non connecté"))
            return
        }
        
        isGenerating = true
        
        let prompt = """
        \(systemPrompt)
        
        CONVERSATION EN COURS:
        \(conversation)
        
        Analyse et suggère:
        """
        
        do {
            let url = URL(string: "\(baseURL)/api/generate")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "model": currentModel,
                "prompt": prompt,
                "stream": false,
                "options": [
                    "temperature": 0.7,
                    "top_p": 0.9,
                    "num_predict": 300
                ]
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseText = json["response"] as? String {
                
                // Parse the JSON response from LLM
                let response = parseLLMResponse(responseText)
                
                await MainActor.run {
                    isGenerating = false
                    completion(response)
                }
            } else {
                await MainActor.run {
                    isGenerating = false
                    completion(LLMResponse(error: "Réponse invalide"))
                }
            }
        } catch {
            await MainActor.run {
                isGenerating = false
                completion(LLMResponse(error: error.localizedDescription))
            }
        }
    }
    
    private func parseLLMResponse(_ text: String) -> LLMResponse {
        // Try to extract JSON from response
        guard let jsonStart = text.firstIndex(of: "{"),
              let jsonEnd = text.lastIndex(of: "}") else {
            return LLMResponse(suggestion: text)
        }
        
        let jsonString = String(text[jsonStart...jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return LLMResponse(suggestion: text)
        }
        
        return LLMResponse(
            objection: json["objection"] as? String,
            besoin: json["besoin"] as? String,
            interet: json["interet"] as? Int ?? 5,
            closingProb: json["closing_prob"] as? Int ?? 30,
            suggestion: json["suggestion"] as? String ?? text
        )
    }
    
    // MARK: - Streaming (optional, for real-time display)
    
    func streamGeneration(prompt: String, onToken: @escaping (String) -> Void) async {
        guard isConnected else { return }
        
        let url = URL(string: "\(baseURL)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": currentModel,
            "prompt": prompt,
            "stream": true
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return }
        request.httpBody = bodyData
        
        do {
            let (bytes, _) = try await URLSession.shared.bytes(for: request)
            
            for try await line in bytes.lines {
                if let data = line.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["response"] as? String {
                    await MainActor.run {
                        onToken(token)
                    }
                }
            }
        } catch {
            print("Streaming error: \(error)")
        }
    }
}

// MARK: - Response Model

struct LLMResponse {
    var objection: String?
    var besoin: String?
    var interet: Int = 5
    var closingProb: Int = 30
    var suggestion: String = ""
    var error: String?
    
    init(objection: String? = nil, besoin: String? = nil, interet: Int = 5, closingProb: Int = 30, suggestion: String = "") {
        self.objection = objection
        self.besoin = besoin
        self.interet = interet
        self.closingProb = closingProb
        self.suggestion = suggestion
    }
    
    init(error: String) {
        self.error = error
    }
    
    init(suggestion: String) {
        self.suggestion = suggestion
    }
}

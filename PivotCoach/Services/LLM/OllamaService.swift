import Foundation

actor OllamaService {
    private let baseURL = URL(string: "http://127.0.0.1:11434")!
    private var model = "qwen2.5:7b-instruct-q4_K_M"
    
    // MARK: - Request/Response Types
    
    struct GenerateRequest: Codable {
        let model: String
        let prompt: String
        let system: String?
        let stream: Bool
        let options: Options?
        
        struct Options: Codable {
            let temperature: Double?
            let num_predict: Int?
            let top_p: Double?
            let repeat_penalty: Double?
        }
    }
    
    struct GenerateResponse: Codable {
        let response: String
        let done: Bool
    }
    
    struct TagsResponse: Codable {
        let models: [Model]
        
        struct Model: Codable {
            let name: String
        }
    }
    
    // MARK: - Configuration
    
    func setModel(_ modelName: String) {
        self.model = modelName
    }
    
    // MARK: - Health Check
    
    func isAvailable() async -> Bool {
        let url = baseURL.appendingPathComponent("api/tags")
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    func listModels() async -> [String] {
        let url = baseURL.appendingPathComponent("api/tags")
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(TagsResponse.self, from: data)
            return response.models.map { $0.name }
        } catch {
            return []
        }
    }
    
    // MARK: - Streaming Generation
    
    nonisolated func generateStream(prompt: String, system: String) -> AsyncThrowingStream<String, Error> {
        let model = "qwen2.5:7b-instruct-q4_K_M"
        let baseURL = URL(string: "http://127.0.0.1:11434")!
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = baseURL.appendingPathComponent("api/generate")
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = 60
                    
                    let body = GenerateRequest(
                        model: model,
                        prompt: prompt,
                        system: system,
                        stream: true,
                        options: .init(
                            temperature: 0.7,
                            num_predict: 256,
                            top_p: 0.9,
                            repeat_penalty: 1.1
                        )
                    )
                    request.httpBody = try JSONEncoder().encode(body)
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                        throw OllamaError.requestFailed
                    }
                    
                    for try await line in bytes.lines {
                        if let data = line.data(using: .utf8),
                           let response = try? JSONDecoder().decode(GenerateResponse.self, from: data) {
                            if !response.response.isEmpty {
                                continuation.yield(response.response)
                            }
                            if response.done {
                                break
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Simple Generation (non-streaming)
    
    func generate(prompt: String, system: String) async throws -> String {
        let url = baseURL.appendingPathComponent("api/generate")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        let body = GenerateRequest(
            model: model,
            prompt: prompt,
            system: system,
            stream: false,
            options: .init(
                temperature: 0.7,
                num_predict: 256,
                top_p: 0.9,
                repeat_penalty: 1.1
            )
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw OllamaError.requestFailed
        }
        
        let result = try JSONDecoder().decode(GenerateResponse.self, from: data)
        return result.response
    }
}

// MARK: - Errors

enum OllamaError: Error, LocalizedError {
    case notAvailable
    case requestFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notAvailable: return "Ollama n'est pas disponible. Lance 'ollama serve' dans le terminal."
        case .requestFailed: return "La requête à Ollama a échoué"
        case .invalidResponse: return "Réponse invalide d'Ollama"
        }
    }
}

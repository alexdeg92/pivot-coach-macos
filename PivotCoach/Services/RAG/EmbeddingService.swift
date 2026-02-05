import NaturalLanguage

final class EmbeddingService: @unchecked Sendable {
    private let embedding: NLEmbedding?
    
    init() {
        // Utiliser l'embedding français si disponible, sinon anglais
        embedding = NLEmbedding.wordEmbedding(for: .french) ?? NLEmbedding.wordEmbedding(for: .english)
        
        if embedding != nil {
            print("✅ NLEmbedding initialisé")
        } else {
            print("⚠️ NLEmbedding non disponible")
        }
    }
    
    /// Crée un embedding pour un texte (moyenne des embeddings de mots)
    func embed(text: String) -> [Double]? {
        guard let embedding = embedding else { return nil }
        
        // Tokeniser et nettoyer
        let words = text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count > 2 }
        
        guard !words.isEmpty else { return nil }
        
        var sumVector: [Double]?
        var count = 0
        
        for word in words {
            if let vector = embedding.vector(for: word) {
                if sumVector == nil {
                    sumVector = vector
                } else {
                    for i in 0..<vector.count {
                        sumVector![i] += vector[i]
                    }
                }
                count += 1
            }
        }
        
        guard let sum = sumVector, count > 0 else { return nil }
        
        // Moyenne
        return sum.map { $0 / Double(count) }
    }
    
    /// Calcule la similarité cosinus entre deux vecteurs
    func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        
        var dotProduct: Double = 0
        var normA: Double = 0
        var normB: Double = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        let denominator = sqrt(normA) * sqrt(normB)
        return denominator > 0 ? dotProduct / denominator : 0
    }
}

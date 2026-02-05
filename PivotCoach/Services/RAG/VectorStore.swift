import Foundation
import SQLite3
import NaturalLanguage

final class VectorStore: @unchecked Sendable {
    private var db: OpaquePointer?
    private let embeddingService = EmbeddingService()
    private let queue = DispatchQueue(label: "com.pivotcoach.vectorstore", qos: .userInitiated)
    
    init(dbPath: String) throws {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            throw VectorStoreError.openFailed
        }
        try createTables()
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    // MARK: - Setup
    
    private func createTables() throws {
        let sql = """
            CREATE TABLE IF NOT EXISTS documents (
                id TEXT PRIMARY KEY,
                contact_id TEXT,
                type TEXT,
                content TEXT,
                embedding BLOB,
                created_at INTEGER
            );
            CREATE INDEX IF NOT EXISTS idx_contact ON documents(contact_id);
            
            CREATE TABLE IF NOT EXISTS contacts (
                id TEXT PRIMARY KEY,
                first_name TEXT,
                last_name TEXT,
                email TEXT,
                company TEXT,
                phone TEXT,
                deal_stage TEXT,
                synced_at INTEGER
            );
        """
        
        var errMsg: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            let message = errMsg != nil ? String(cString: errMsg!) : "Unknown error"
            sqlite3_free(errMsg)
            throw VectorStoreError.queryFailed(message)
        }
    }
    
    // MARK: - Document Operations
    
    func upsertDocument(id: String, contactId: String, type: String, content: String) throws {
        guard let embedding = embeddingService.embed(text: content) else {
            print("⚠️ Could not create embedding for: \(content.prefix(50))...")
            return
        }
        
        let embeddingData = embedding.withUnsafeBufferPointer { Data(buffer: $0) }
        
        let sql = """
            INSERT OR REPLACE INTO documents (id, contact_id, type, content, embedding, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw VectorStoreError.queryFailed("Prepare failed")
        }
        defer { sqlite3_finalize(stmt) }
        
        sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (contactId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (type as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, (content as NSString).utf8String, -1, nil)
        embeddingData.withUnsafeBytes { ptr in
            sqlite3_bind_blob(stmt, 5, ptr.baseAddress, Int32(embeddingData.count), nil)
        }
        sqlite3_bind_int64(stmt, 6, Int64(Date().timeIntervalSince1970))
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw VectorStoreError.queryFailed("Insert failed")
        }
    }
    
    func search(query: String, contactId: String? = nil, limit: Int = 5) -> [(content: String, score: Double)] {
        guard let queryEmbedding = embeddingService.embed(text: query) else { return [] }
        
        var sql = "SELECT content, embedding FROM documents"
        if let contactId = contactId {
            sql += " WHERE contact_id = ?"
        }
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        
        if let contactId = contactId {
            sqlite3_bind_text(stmt, 1, (contactId as NSString).utf8String, -1, nil)
        }
        
        var results: [(content: String, score: Double)] = []
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let contentPtr = sqlite3_column_text(stmt, 0) else { continue }
            let content = String(cString: contentPtr)
            
            if let blobPointer = sqlite3_column_blob(stmt, 1) {
                let blobSize = Int(sqlite3_column_bytes(stmt, 1))
                let data = Data(bytes: blobPointer, count: blobSize)
                
                let embedding: [Double] = data.withUnsafeBytes { buffer in
                    Array(buffer.bindMemory(to: Double.self))
                }
                
                let score = embeddingService.cosineSimilarity(queryEmbedding, embedding)
                results.append((content, score))
            }
        }
        
        return results
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }
    
    func deleteDocuments(forContactId contactId: String) throws {
        let sql = "DELETE FROM documents WHERE contact_id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw VectorStoreError.queryFailed("Prepare failed")
        }
        defer { sqlite3_finalize(stmt) }
        
        sqlite3_bind_text(stmt, 1, (contactId as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
    }
    
    // MARK: - Contact Operations
    
    func upsertContact(_ contact: Contact) throws {
        let sql = """
            INSERT OR REPLACE INTO contacts (id, first_name, last_name, email, company, phone, deal_stage, synced_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw VectorStoreError.queryFailed("Prepare failed")
        }
        defer { sqlite3_finalize(stmt) }
        
        sqlite3_bind_text(stmt, 1, (contact.id as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (contact.firstName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (contact.lastName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, (contact.email as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 5, (contact.company as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 6, (contact.phone as NSString).utf8String, -1, nil)
        if let stage = contact.dealStage {
            sqlite3_bind_text(stmt, 7, (stage as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(stmt, 7)
        }
        sqlite3_bind_int64(stmt, 8, Int64(Date().timeIntervalSince1970))
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw VectorStoreError.queryFailed("Insert contact failed")
        }
    }
    
    func getAllContacts() -> [Contact] {
        let sql = "SELECT id, first_name, last_name, email, company, phone, deal_stage FROM contacts ORDER BY last_name"
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        
        var contacts: [Contact] = []
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let idPtr = sqlite3_column_text(stmt, 0),
                  let firstNamePtr = sqlite3_column_text(stmt, 1),
                  let lastNamePtr = sqlite3_column_text(stmt, 2),
                  let emailPtr = sqlite3_column_text(stmt, 3),
                  let companyPtr = sqlite3_column_text(stmt, 4),
                  let phonePtr = sqlite3_column_text(stmt, 5) else {
                continue
            }
            
            let id = String(cString: idPtr)
            let firstName = String(cString: firstNamePtr)
            let lastName = String(cString: lastNamePtr)
            let email = String(cString: emailPtr)
            let company = String(cString: companyPtr)
            let phone = String(cString: phonePtr)
            let dealStage = sqlite3_column_text(stmt, 6).map { String(cString: $0) }
            
            contacts.append(Contact(
                id: id,
                firstName: firstName,
                lastName: lastName,
                email: email,
                company: company,
                phone: phone,
                dealStage: dealStage
            ))
        }
        
        return contacts
    }
}

// MARK: - Errors

enum VectorStoreError: Error, LocalizedError, Sendable {
    case openFailed
    case queryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .openFailed: return "Impossible d'ouvrir la base de données"
        case .queryFailed(let msg): return "Erreur SQL: \(msg)"
        }
    }
}

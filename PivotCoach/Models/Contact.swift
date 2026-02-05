import Foundation

struct Contact: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var company: String
    var phone: String
    var dealStage: String?
    var notes: [String] = []
    var lastActivity: Date?
    
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var displayName: String {
        if !fullName.isEmpty {
            return fullName
        }
        if !company.isEmpty {
            return company
        }
        return email
    }
}

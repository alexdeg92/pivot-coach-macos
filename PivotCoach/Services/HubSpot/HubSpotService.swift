import Foundation
import AuthenticationServices

@MainActor
class HubSpotService: NSObject, ObservableObject {
    static let shared = HubSpotService()
    
    @Published var isConnected = false
    @Published var contacts: [HubSpotContact] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var accessToken: String? {
        didSet {
            isConnected = accessToken != nil
            if let token = accessToken {
                UserDefaults.standard.set(token, forKey: "hubspot_access_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "hubspot_access_token")
            }
        }
    }
    
    private var refreshToken: String? {
        didSet {
            if let token = refreshToken {
                UserDefaults.standard.set(token, forKey: "hubspot_refresh_token")
            }
        }
    }
    
    // HubSpot OAuth credentials - à configurer
    private let clientId = "YOUR_HUBSPOT_CLIENT_ID"  // TODO: Remplacer
    private let clientSecret = "YOUR_HUBSPOT_CLIENT_SECRET"  // TODO: Remplacer
    private let redirectUri = "pivotcoach://oauth/callback"
    private let scopes = ["crm.objects.contacts.read", "crm.objects.deals.read", "crm.objects.companies.read"]
    
    override init() {
        super.init()
        // Charger le token sauvegardé
        accessToken = UserDefaults.standard.string(forKey: "hubspot_access_token")
        refreshToken = UserDefaults.standard.string(forKey: "hubspot_refresh_token")
    }
    
    // MARK: - OAuth Flow
    
    var authURL: URL {
        var components = URLComponents(string: "https://app.hubspot.com/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " "))
        ]
        return components.url!
    }
    
    func startOAuth(from window: NSWindow?) {
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "pivotcoach"
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    self.error = "OAuth error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let callbackURL = callbackURL,
                  let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value else {
                Task { @MainActor in
                    self.error = "No authorization code received"
                }
                return
            }
            
            Task {
                await self.exchangeCodeForToken(code)
            }
        }
        
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
    
    private func exchangeCodeForToken(_ code: String) async {
        let url = URL(string: "https://api.hubapi.com/oauth/v1/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectUri,
            "code": code
        ]
        
        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(TokenResponse.self, from: data)
            
            accessToken = response.accessToken
            refreshToken = response.refreshToken
            
            // Charger les contacts après connexion
            await fetchContacts()
        } catch {
            self.error = "Token exchange failed: \(error.localizedDescription)"
        }
    }
    
    func disconnect() {
        accessToken = nil
        refreshToken = nil
        contacts = []
        isConnected = false
    }
    
    // MARK: - API Calls
    
    func fetchContacts() async {
        guard let token = accessToken else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        var allContacts: [HubSpotContact] = []
        var after: String? = nil
        
        repeat {
            var urlComponents = URLComponents(string: "https://api.hubapi.com/crm/v3/objects/contacts")!
            var queryItems = [
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "properties", value: "firstname,lastname,email,phone,company,hs_lead_status,notes_last_updated")
            ]
            if let after = after {
                queryItems.append(URLQueryItem(name: "after", value: after))
            }
            urlComponents.queryItems = queryItems
            
            var request = URLRequest(url: urlComponents.url!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    // Token expired, try refresh
                    await refreshAccessToken()
                    return await fetchContacts()
                }
                
                let result = try JSONDecoder().decode(ContactsResponse.self, from: data)
                
                for contact in result.results {
                    allContacts.append(HubSpotContact(
                        id: contact.id,
                        firstName: contact.properties["firstname"] ?? "",
                        lastName: contact.properties["lastname"] ?? "",
                        email: contact.properties["email"] ?? "",
                        phone: contact.properties["phone"] ?? "",
                        company: contact.properties["company"] ?? "",
                        leadStatus: contact.properties["hs_lead_status"]
                    ))
                }
                
                after = result.paging?.next?.after
            } catch {
                self.error = "Failed to fetch contacts: \(error.localizedDescription)"
                break
            }
        } while after != nil
        
        contacts = allContacts.sorted { ($0.lastName + $0.firstName) < ($1.lastName + $1.firstName) }
    }
    
    private func refreshAccessToken() async {
        guard let refresh = refreshToken else { return }
        
        let url = URL(string: "https://api.hubapi.com/oauth/v1/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "grant_type": "refresh_token",
            "client_id": clientId,
            "client_secret": clientSecret,
            "refresh_token": refresh
        ]
        
        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(TokenResponse.self, from: data)
            accessToken = response.accessToken
            if let newRefresh = response.refreshToken {
                refreshToken = newRefresh
            }
        } catch {
            // Refresh failed, need to re-auth
            disconnect()
        }
    }
    
    func searchContacts(query: String) -> [HubSpotContact] {
        guard !query.isEmpty else { return contacts }
        let lowercased = query.lowercased()
        return contacts.filter {
            $0.firstName.lowercased().contains(lowercased) ||
            $0.lastName.lowercased().contains(lowercased) ||
            $0.company.lowercased().contains(lowercased) ||
            $0.email.lowercased().contains(lowercased)
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension HubSpotService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.keyWindow ?? NSWindow()
    }
}

// MARK: - Models

struct HubSpotContact: Identifiable, Codable, Hashable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var company: String
    var leadStatus: String?
    
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var displayName: String {
        if !fullName.isEmpty { return fullName }
        if !company.isEmpty { return company }
        return email
    }
}

private struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

private struct ContactsResponse: Codable {
    let results: [ContactResult]
    let paging: Paging?
    
    struct ContactResult: Codable {
        let id: String
        let properties: [String: String]
    }
    
    struct Paging: Codable {
        let next: NextPage?
        
        struct NextPage: Codable {
            let after: String
        }
    }
}

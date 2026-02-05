import SwiftUI

struct SetupOverlayView: View {
    @ObservedObject var viewModel: CoachViewModel
    @ObservedObject var hubspot = HubSpotService.shared
    @State private var searchText = ""
    @State private var additionalContext = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("🎯 Nouveau Call")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.3))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // HubSpot Connection
                    HubSpotConnectionCard(hubspot: hubspot)
                    
                    // Contact Selection
                    if hubspot.isConnected {
                        ContactPickerCard(
                            hubspot: hubspot,
                            searchText: $searchText,
                            selectedContact: $viewModel.selectedHubSpotContact
                        )
                    }
                    
                    // Additional Context
                    AdditionalContextCard(context: $additionalContext)
                    
                    // Start Button
                    Button(action: {
                        viewModel.additionalContext = additionalContext
                        viewModel.showSetup = false
                        Task {
                            await viewModel.startListening()
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Démarrer l'appel")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isReady ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.isReady)
                }
                .padding()
            }
        }
        .background(Color(white: 0.1))
    }
}

// MARK: - HubSpot Connection Card

struct HubSpotConnectionCard: View {
    @ObservedObject var hubspot: HubSpotService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundColor(.orange)
                Text("HubSpot")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                
                if hubspot.isConnected {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Connecté")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            if hubspot.isConnected {
                HStack {
                    Text("\(hubspot.contacts.count) contacts")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Button("Déconnecter") {
                        hubspot.disconnect()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .buttonStyle(.plain)
                }
            } else {
                Button(action: {
                    hubspot.startOAuth(from: NSApp.keyWindow)
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle")
                        Text("Connecter HubSpot")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            if let error = hubspot.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Contact Picker Card

struct ContactPickerCard: View {
    @ObservedObject var hubspot: HubSpotService
    @Binding var searchText: String
    @Binding var selectedContact: HubSpotContact?
    
    var filteredContacts: [HubSpotContact] {
        hubspot.searchContacts(query: searchText)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                Text("Client")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if selectedContact != nil {
                    Spacer()
                    Button(action: { selectedContact = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if let contact = selectedContact {
                // Selected contact display
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        if !contact.company.isEmpty {
                            Text(contact.company)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding(10)
                .background(Color.green.opacity(0.2))
                .cornerRadius(8)
            } else {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Rechercher un contact...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding(10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                
                // Contact list
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredContacts.prefix(10)) { contact in
                            ContactRow(contact: contact) {
                                selectedContact = contact
                                searchText = ""
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ContactRow: View {
    let contact: HubSpotContact
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    if !contact.company.isEmpty {
                        Text(contact.company)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Additional Context Card

struct AdditionalContextCard: View {
    @Binding var context: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.purple)
                Text("Contexte (optionnel)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            TextEditor(text: $context)
                .font(.subheadline)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(height: 80)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            Text("Ex: \"Suivi démo de la semaine dernière\", \"Intéressé par le module planning\"")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

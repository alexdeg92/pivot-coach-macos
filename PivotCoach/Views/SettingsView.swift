import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: CoachViewModel
    @State private var selectedModel = "qwen2.5:7b-instruct-q4_K_M"
    @State private var availableModels: [String] = []
    @State private var hubspotClientId = ""
    @State private var isLoadingModels = false
    
    var body: some View {
        TabView {
            // Général
            GeneralSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Général", systemImage: "gearshape")
                }
            
            // Modèle LLM
            LLMSettingsView(
                selectedModel: $selectedModel,
                availableModels: $availableModels,
                isLoading: $isLoadingModels,
                ollamaAvailable: viewModel.ollamaAvailable
            )
            .tabItem {
                Label("Modèle IA", systemImage: "brain")
            }
            
            // HubSpot
            HubSpotSettingsView(
                clientId: $hubspotClientId,
                isConnected: viewModel.hubspotConnected
            )
            .tabItem {
                Label("HubSpot", systemImage: "link")
            }
            
            // Raccourcis
            ShortcutsSettingsView()
                .tabItem {
                    Label("Raccourcis", systemImage: "keyboard")
                }
        }
        .frame(width: 500, height: 400)
        .task {
            await loadModels()
        }
    }
    
    private func loadModels() async {
        isLoadingModels = true
        let service = OllamaService()
        let models = await service.listModels()
        await MainActor.run {
            availableModels = models.isEmpty ? ["qwen2.5:7b-instruct-q4_K_M"] : models
            isLoadingModels = false
        }
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: CoachViewModel
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInDock") private var showInDock = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Lancer au démarrage", isOn: $launchAtLogin)
                Toggle("Afficher dans le Dock", isOn: $showInDock)
            }
            
            Section("Status") {
                HStack {
                    Text("Ollama")
                    Spacer()
                    if viewModel.ollamaAvailable {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Connecté")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Non disponible")
                            .foregroundColor(.red)
                    }
                }
                
                HStack {
                    Text("HubSpot")
                    Spacer()
                    if viewModel.hubspotConnected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Connecté")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.gray)
                        Text("Non connecté")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            if !viewModel.ollamaAvailable {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚠️ Ollama n'est pas disponible")
                            .font(.headline)
                        Text("Lance ces commandes dans le Terminal:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("brew install ollama")
                                .font(.system(.body, design: .monospaced))
                            Text("ollama serve")
                                .font(.system(.body, design: .monospaced))
                            Text("ollama pull qwen2.5:7b-instruct-q4_K_M")
                                .font(.system(.body, design: .monospaced))
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - LLM Settings

struct LLMSettingsView: View {
    @Binding var selectedModel: String
    @Binding var availableModels: [String]
    @Binding var isLoading: Bool
    let ollamaAvailable: Bool
    
    var body: some View {
        Form {
            Section("Modèle") {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Chargement des modèles...")
                    }
                } else {
                    Picker("Modèle actif", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                }
            }
            
            Section("Modèles recommandés") {
                VStack(alignment: .leading, spacing: 8) {
                    ModelRecommendation(
                        name: "qwen2.5:7b",
                        description: "Rapide, bon français",
                        vram: "5GB"
                    )
                    ModelRecommendation(
                        name: "mistral:7b",
                        description: "Équilibré",
                        vram: "5GB"
                    )
                    ModelRecommendation(
                        name: "llama3.1:8b",
                        description: "Très capable",
                        vram: "6GB"
                    )
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ModelRecommendation: View {
    let name: String
    let description: String
    let vram: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.system(.body, design: .monospaced))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(vram)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

// MARK: - HubSpot Settings

struct HubSpotSettingsView: View {
    @Binding var clientId: String
    let isConnected: Bool
    
    var body: some View {
        Form {
            Section("Connexion") {
                if isConnected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Connecté à HubSpot")
                        Spacer()
                        Button("Déconnecter") {
                            // TODO: Disconnect
                        }
                        .foregroundColor(.red)
                    }
                } else {
                    TextField("Client ID HubSpot", text: $clientId)
                    Button("Connecter HubSpot") {
                        // TODO: Start OAuth flow
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Section {
                Text("Pour obtenir un Client ID:")
                    .font(.headline)
                Link("1. Créer une app sur HubSpot Developer",
                     destination: URL(string: "https://developers.hubspot.com/")!)
                Text("2. Copier le Client ID dans le champ ci-dessus")
                Text("3. Cliquer sur Connecter")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Shortcuts Settings

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("Raccourcis clavier") {
                ShortcutRow(
                    action: "Démarrer/Arrêter l'écoute",
                    shortcut: "⌘⇧L"
                )
                ShortcutRow(
                    action: "Afficher/Masquer l'overlay",
                    shortcut: "⌘⇧O"
                )
                ShortcutRow(
                    action: "Copier la suggestion",
                    shortcut: "⌘⇧C"
                )
                ShortcutRow(
                    action: "Mode discret",
                    shortcut: "⌘⇧S"
                )
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ShortcutRow: View {
    let action: String
    let shortcut: String
    
    var body: some View {
        HStack {
            Text(action)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
        }
    }
}

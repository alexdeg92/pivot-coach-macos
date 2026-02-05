import SwiftUI

struct SetupOverlayView: View {
    @ObservedObject var viewModel: CoachViewModel
    @State private var notes = ""
    @State private var prospectName = ""
    @State private var prospectType = "Restaurant"
    
    let prospectTypes = ["Restaurant", "Bar", "Café", "Traiteur", "Autre"]
    
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
                    // Prospect Info Card
                    ProspectInfoCard(
                        prospectName: $prospectName,
                        prospectType: $prospectType,
                        prospectTypes: prospectTypes
                    )
                    
                    // Notes avant l'appel
                    NotesCard(notes: $notes)
                    
                    // Start Button
                    Button(action: {
                        viewModel.prospectName = prospectName
                        viewModel.prospectType = prospectType
                        viewModel.additionalContext = notes
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

// MARK: - Prospect Info Card

struct ProspectInfoCard: View {
    @Binding var prospectName: String
    @Binding var prospectType: String
    let prospectTypes: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                Text("Prospect")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Nom du prospect
            VStack(alignment: .leading, spacing: 4) {
                Text("Nom du prospect (optionnel)")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("Ex: Jean Dupont", text: $prospectName)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Type de prospect
            VStack(alignment: .leading, spacing: 4) {
                Text("Type de prospect")
                    .font(.caption)
                    .foregroundColor(.gray)
                Picker("Type", selection: $prospectType) {
                    ForEach(prospectTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Notes Card

struct NotesCard: View {
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.purple)
                Text("Notes avant l'appel")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            TextEditor(text: $notes)
                .font(.subheadline)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(height: 80)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            Text("Ex: \"Premier contact via salon pro\", \"Utilise actuellement Zelty\"")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

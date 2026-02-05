import SwiftUI

struct OverlayView: View {
    @ObservedObject var viewModel: CoachViewModel
    
    var body: some View {
        if viewModel.showSetup {
            SetupOverlayView(viewModel: viewModel)
        } else if viewModel.stealthMode {
            StealthView(viewModel: viewModel)
        } else {
            FullOverlayView(viewModel: viewModel)
        }
    }
}

struct FullOverlayView: View {
    @ObservedObject var viewModel: CoachViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(viewModel: viewModel)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Transcription
                    SectionCard(title: "📝 TRANSCRIPTION") {
                        Text(viewModel.clientSaid.isEmpty ? "En attente..." : viewModel.clientSaid)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Suggestion
                    SectionCard(title: "💡 SUGGESTION") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(viewModel.suggestion.isEmpty ? "En attente du client..." : viewModel.suggestion)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.5))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 8) {
                                ActionButton(label: "📋 Copier") {
                                    viewModel.copySuggestion()
                                }
                                ActionButton(label: "🔄 Autre") {
                                    viewModel.regenerateSuggestion()
                                }
                                ActionButton(label: "📝 Court") {
                                    viewModel.shortenSuggestion()
                                }
                            }
                        }
                    }
                    
                    // Analyse
                    SectionCard(title: "📊 ANALYSE") {
                        VStack(alignment: .leading, spacing: 8) {
                            AnalysisRow(label: "Intent", value: viewModel.intent.isEmpty ? "-" : viewModel.intent)
                            
                            HStack {
                                Text("Émotion:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                Text(emotionEmoji(viewModel.emotion))
                                Text(viewModel.emotion.capitalized)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("Closing:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .frame(width: 60, alignment: .leading)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.1))
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(closingColor(viewModel.closingProbability))
                                            .frame(width: geometry.size.width * CGFloat(viewModel.closingProbability) / 100)
                                    }
                                }
                                .frame(height: 8)
                                
                                Text("\(viewModel.closingProbability)%")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 40)
                            }
                        }
                    }
                    
                    // Contact actuel
                    if let contact = viewModel.currentContact {
                        SectionCard(title: "👤 CLIENT") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(contact.firstName) \(contact.lastName)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Text(contact.company)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                if let stage = contact.dealStage {
                                    Text("Stage: \(stage)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            
            // Footer
            FooterView(viewModel: viewModel)
        }
        .background(Color(white: 0.1))
    }
    
    func emotionEmoji(_ emotion: String) -> String {
        switch emotion.lowercased() {
        case "positive", "positif": return "😊"
        case "sceptical", "sceptique": return "🤨"
        case "frustrated", "frustré": return "😤"
        case "enthusiastic", "enthousiaste": return "🤩"
        default: return "😐"
        }
    }
    
    func closingColor(_ probability: Int) -> Color {
        if probability >= 70 {
            return Color.green
        } else if probability >= 40 {
            return Color.yellow
        } else {
            return Color.red
        }
    }
}

// MARK: - Header

struct HeaderView: View {
    @ObservedObject var viewModel: CoachViewModel
    
    var body: some View {
        HStack {
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isListening ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                    .shadow(color: viewModel.isListening ? Color.green.opacity(0.6) : .clear, radius: 4)
                
                Text(viewModel.isListening ? "En écoute..." : "En pause")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Audio level
            if viewModel.isListening {
                AudioLevelView(level: viewModel.audioLevel)
            }
            
            // Stealth mode button
            Button(action: { viewModel.stealthMode = true }) {
                Image(systemName: "eye.slash")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("Mode discret")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Footer

struct FooterView: View {
    @ObservedObject var viewModel: CoachViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                Task {
                    if viewModel.isListening {
                        await viewModel.stopListening()
                    } else {
                        await viewModel.startListening()
                    }
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isListening ? "pause.fill" : "play.fill")
                    Text(viewModel.isListening ? "Pause" : "Start")
                }
                .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.stopListening()
                    viewModel.resetConversation()
                    viewModel.showSetup = true
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "phone.badge.plus")
                    Text("Nouveau")
                }
                .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)
            
            Button(action: { viewModel.showSettings() }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Stealth View

struct StealthView: View {
    @ObservedObject var viewModel: CoachViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(closingColor(viewModel.closingProbability))
                .frame(width: 8, height: 8)
            
            Text(viewModel.suggestion.isEmpty ? "En attente..." : viewModel.suggestion)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: { viewModel.stealthMode = false }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.black.opacity(0.85))
        .cornerRadius(8)
    }
    
    func closingColor(_ probability: Int) -> Color {
        if probability >= 70 { return .green }
        else if probability >= 40 { return .yellow }
        else { return .red }
    }
}

// MARK: - Components

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray)
                .tracking(1)
            
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct ActionButton: View {
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .foregroundColor(.white)
    }
}

struct AnalysisRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.white)
        }
    }
}

struct AudioLevelView: View {
    let level: Float
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor(for: i))
                    .frame(width: 3, height: CGFloat(4 + i * 2))
            }
        }
    }
    
    func barColor(for index: Int) -> Color {
        let threshold = Float(index) * 0.15
        return level > threshold ? .green : Color.gray.opacity(0.3)
    }
}

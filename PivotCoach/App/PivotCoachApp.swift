import SwiftUI

@main
struct PivotCoachApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var coachVM = CoachViewModel()
    
    var body: some Scene {
        // Menu bar icon
        MenuBarExtra("Pivot Coach", systemImage: "waveform.circle.fill") {
            MenuBarView(viewModel: coachVM)
        }
        .menuBarExtraStyle(.window)
        
        // Settings window
        Settings {
            SettingsView(viewModel: coachVM)
        }
    }
}

struct MenuBarView: View {
    @ObservedObject var viewModel: CoachViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(viewModel.isListening ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(viewModel.isListening ? "En écoute" : "Arrêté")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            Button(action: {
                Task {
                    if viewModel.isListening {
                        await viewModel.stopListening()
                    } else {
                        await viewModel.startListening()
                    }
                }
            }) {
                Label(viewModel.isListening ? "Arrêter" : "Démarrer", 
                      systemImage: viewModel.isListening ? "stop.fill" : "play.fill")
            }
            
            Button(action: { viewModel.toggleOverlay() }) {
                Label("Afficher/Masquer Overlay", systemImage: "rectangle.on.rectangle")
            }
            
            Divider()
            
            Button(action: { NSApp.terminate(nil) }) {
                Label("Quitter", systemImage: "xmark.circle")
            }
        }
        .padding()
        .frame(width: 250)
    }
}

import AppKit
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayController: OverlayWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Créer l'overlay
        overlayController = OverlayWindowController()
        
        // Enregistrer les raccourcis globaux
        KeyboardShortcuts.shared.register()
        
        // Demander les permissions
        Task {
            await requestPermissions()
        }
        
        // Initialiser le ViewModel global
        Task {
            await CoachViewModel.shared.initialize()
        }
    }
    
    private func requestPermissions() async {
        // Microphone
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .notDetermined {
            await AVCaptureDevice.requestAccess(for: .audio)
        }
        
        // ScreenCaptureKit permission sera demandée automatiquement
        // lors de la première capture
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Rester en menu bar
    }
}

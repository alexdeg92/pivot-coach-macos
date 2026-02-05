import SwiftUI

@main
struct PivotCoachApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var audioCapture = AudioCaptureManager()
    @StateObject private var whisperManager = WhisperManager()
    @StateObject private var ollamaClient = OllamaClient()
    @StateObject private var coachState = CoachState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioCapture)
                .environmentObject(whisperManager)
                .environmentObject(ollamaClient)
                .environmentObject(coachState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: NSPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure as accessory app (no dock icon)
        // NSApp.setActivationPolicy(.accessory)
        
        // Create floating overlay window
        setupOverlayWindow()
    }
    
    func setupOverlayWindow() {
        guard let screen = NSScreen.main else { return }
        
        let windowRect = NSRect(
            x: screen.frame.maxX - 420,
            y: screen.frame.maxY - 650,
            width: 400,
            height: 600
        )
        
        overlayWindow = NSPanel(
            contentRect: windowRect,
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        overlayWindow?.level = .floating
        overlayWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlayWindow?.isOpaque = false
        overlayWindow?.backgroundColor = .clear
        overlayWindow?.hasShadow = true
        overlayWindow?.hidesOnDeactivate = false
        
        // Set SwiftUI content
        let contentView = NSHostingView(rootView: ContentView()
            .environmentObject(AudioCaptureManager())
            .environmentObject(WhisperManager())
            .environmentObject(OllamaClient())
            .environmentObject(CoachState())
        )
        
        overlayWindow?.contentView = contentView
        overlayWindow?.makeKeyAndOrderFront(nil)
    }
}

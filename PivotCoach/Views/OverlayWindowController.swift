import AppKit
import SwiftUI

@MainActor
class OverlayWindowController {
    private var panel: NSPanel!
    private var hostingView: NSHostingView<OverlayView>!
    
    init() {
        setupPanel()
    }
    
    private func setupPanel() {
        // Créer le panel flottant
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 520),
            styleMask: [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Configuration always-on-top
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        
        // Style visuel
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = NSColor(white: 0.1, alpha: 0.95)
        panel.hasShadow = true
        panel.isOpaque = false
        
        // SwiftUI content
        hostingView = NSHostingView(rootView: OverlayView(viewModel: CoachViewModel.shared))
        panel.contentView = hostingView
        
        // Position initiale (coin droit)
        positionWindow()
    }
    
    private func positionWindow() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - panel.frame.width - 20
        let y = screenFrame.maxY - panel.frame.height - 20
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func show() {
        panel.orderFrontRegardless()
    }
    
    func hide() {
        panel.orderOut(nil)
    }
    
    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func setOpacity(_ opacity: CGFloat) {
        panel.alphaValue = opacity
    }
    
    func setStealth(_ enabled: Bool) {
        if enabled {
            panel.setContentSize(NSSize(width: 320, height: 70))
            panel.alphaValue = 0.8
        } else {
            panel.setContentSize(NSSize(width: 380, height: 520))
            panel.alphaValue = 0.95
        }
    }
}

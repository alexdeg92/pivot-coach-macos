import AppKit
import Carbon

class KeyboardShortcuts {
    static let shared = KeyboardShortcuts()
    
    private var eventHandler: EventHandlerRef?
    
    func register() {
        // Enregistrer les hotkeys globaux
        // Cmd+Shift+L: Toggle écoute
        // Cmd+Shift+O: Toggle overlay
        // Cmd+Shift+C: Copier suggestion
        
        var hotKeyRef: EventHotKeyRef?
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.signature = OSType(0x50564348) // "PVCH"
        gMyHotKeyID.id = 1
        
        // Cmd+Shift+L (keycode 37 = L)
        var status = RegisterEventHotKey(
            UInt32(kVK_ANSI_L),
            UInt32(cmdKey | shiftKey),
            gMyHotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            print("✅ Hotkey Cmd+Shift+L enregistré")
        }
        
        // Setup event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handler: EventHandlerUPP = { (_, event, _) -> OSStatus in
            var hkCom = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hkCom
            )
            
            Task { @MainActor in
                switch hkCom.id {
                case 1: // Toggle listen
                    let vm = CoachViewModel.shared
                    if vm.isListening {
                        await vm.stopListening()
                    } else {
                        await vm.startListening()
                    }
                case 2: // Toggle overlay
                    CoachViewModel.shared.toggleOverlay()
                case 3: // Copy suggestion
                    CoachViewModel.shared.copySuggestion()
                default:
                    break
                }
            }
            
            return noErr
        }
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }
    
    func unregister() {
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }
}

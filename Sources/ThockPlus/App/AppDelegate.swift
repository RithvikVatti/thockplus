import AppKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run purely as a menu bar accessory (no dock icon clutter)
        NSApp.setActivationPolicy(.accessory)
        
        // Setup menu bar status item
        StatusItemController.shared.setup()
        
        // Pre-warm sound engines
        SoundEngine.shared.preloadAllSounds()
        KeyboardMouseEngine.shared.preloadAudio()
        _ = HardwareHapticEngine.shared
        
        // Start input monitor (scroll, keyboard, mouse)
        InputMonitor.shared.start()
        
        // Check accessibility
        if !AppSettings.shared.isAccessibilityGranted {
            AppSettings.shared.requestAccessibility()
        }
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        InputMonitor.shared.stop()
    }
}

import AppKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run purely as a menu bar accessory (no dock icon clutter)
        NSApp.setActivationPolicy(.accessory)
        
        // Setup menu bar status item
        StatusItemController.shared.setup()
        
        // Pre-warm sound engine
        SoundEngine.shared.preloadAllSounds()
        
        // Start scroll monitor
        ScrollMonitor.shared.start()
        
        // Check accessibility
        if !AppSettings.shared.isAccessibilityGranted {
            AppSettings.shared.requestAccessibility()
        }
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        ScrollMonitor.shared.stop()
    }
}

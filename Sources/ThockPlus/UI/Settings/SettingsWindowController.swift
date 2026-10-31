import AppKit
import SwiftUI

@MainActor
public final class SettingsWindowController: NSObject {
    public static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    
    private override init() {
        super.init()
    }
    
    public func show(tab: SettingsTab = .soundpacks) {
        if let win = window {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView(initialTab: tab)
        let hostingController = NSHostingController(rootView: settingsView)
        
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.center()
        win.title = "Thock+ Settings"
        win.contentViewController = hostingController
        win.minSize = NSSize(width: 720, height: 480)
        win.isReleasedWhenClosed = false
        
        self.window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

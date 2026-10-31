import AppKit
import SwiftUI

@MainActor
public final class StatusItemController: NSObject {
    public static let shared = StatusItemController()
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    private override init() {
        super.init()
    }
    
    public func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = item
        
        if let button = item.button {
            button.image = makeMenuBarIcon()
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Setup Popover
        let pop = NSPopover()
        pop.behavior = .transient
        pop.contentSize = NSSize(width: 340, height: 620)
        pop.contentViewController = NSHostingController(rootView: MenuBarView())
        self.popover = pop
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        
        // Option + Click toggles enabled directly
        if event?.modifierFlags.contains(.option) == true {
            let s = AppSettings.shared
            s.isEnabled.toggle()
            SoundEngine.shared.play(voiceId: s.selectedVoiceId, gain: Float(s.scrollVolume))
            HardwareHapticEngine.shared.pulse(feel: .crisp)
            return
        }
        
        togglePopover(sender)
    }
    
    public func togglePopover(_ sender: AnyObject?) {
        guard let popover = popover, let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            AppSettings.shared.refreshAccessibility()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    private func makeMenuBarIcon() -> NSImage {
        if let img = NSImage(named: "MenuBarIcon") {
            img.isTemplate = true
            return img
        }
        
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: "MenuBarIcon", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            img.isTemplate = true
            return img
        }
        #endif
        
        let paths = [
            "Resources/MenuBarIcon.png",
            "Sources/ThockPlus/Resources/MenuBarIcon.png"
        ]
        for p in paths {
            let u = URL(fileURLWithPath: p)
            if let img = NSImage(contentsOf: u) {
                img.isTemplate = true
                return img
            }
        }
        
        // T+ Vector fallback
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let fontT = NSFont.systemFont(ofSize: 13, weight: .heavy)
            let fontPlus = NSFont.systemFont(ofSize: 10, weight: .black)
            ("T" as NSString).draw(at: CGPoint(x: 1, y: 1.5), withAttributes: [.font: fontT, .foregroundColor: NSColor.black])
            ("+" as NSString).draw(at: CGPoint(x: 10, y: 4.5), withAttributes: [.font: fontPlus, .foregroundColor: NSColor.black])
            return true
        }
        image.isTemplate = true
        return image
    }
}

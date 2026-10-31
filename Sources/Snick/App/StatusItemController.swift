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
        pop.contentSize = NSSize(width: 330, height: 560)
        pop.contentViewController = NSHostingController(rootView: MenuBarView())
        self.popover = pop
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        
        // Option + Click toggles enabled directly
        if event?.modifierFlags.contains(.option) == true {
            let s = AppSettings.shared
            s.isEnabled.toggle()
            SoundEngine.shared.play(voiceId: s.selectedVoiceId, gain: Float(s.volume))
            return
        }
        
        togglePopover(sender)
    }
    
    public func togglePopover(_ sender: AnyObject?) {
        guard let popover = popover, let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            // Refresh accessibility status right when user opens popover
            AppSettings.shared.refreshAccessibility()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    private func makeMenuBarIcon() -> NSImage {
        // Try loading from bundle first
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
        
        // Vector fallback drawing (5 waveform pill bars)
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            
            let scale = rect.width / 1024.0
            ctx.scaleBy(x: scale, y: scale)
            
            let bars: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (280, 296, 64, 432),
                (400, 384, 64, 256),
                (480, 456, 64, 112),
                (560, 384, 64, 256),
                (680, 296, 64, 432)
            ]
            
            ctx.setFillColor(CGColor(gray: 0.0, alpha: 1.0))
            for bar in bars {
                let p = CGPath(
                    roundedRect: CGRect(x: bar.0, y: bar.1, width: bar.2, height: bar.3),
                    cornerWidth: 32,
                    cornerHeight: 32,
                    transform: nil
                )
                ctx.addPath(p)
                ctx.fillPath()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}

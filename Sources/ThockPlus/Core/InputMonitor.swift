import AppKit
import ApplicationServices

public final class InputMonitor: @unchecked Sendable {
    public static let shared = InputMonitor()
    
    private let scrollProcessor = ScrollProcessor()
    private let kmEngine = KeyboardMouseEngine.shared
    
    private var globalScrollMonitor: Any?
    private var localScrollMonitor: Any?
    
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    
    private var isRunning: Bool = false
    
    private init() {}
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        setupScrollMonitors()
        setupKeyboardMonitors()
        setupMouseMonitors()
    }
    
    public func stop() {
        guard isRunning else { return }
        isRunning = false
        
        removeMonitors()
    }
    
    public func restart() {
        stop()
        start()
    }
    
    private func removeMonitors() {
        if let m = globalScrollMonitor { NSEvent.removeMonitor(m); globalScrollMonitor = nil }
        if let m = localScrollMonitor { NSEvent.removeMonitor(m); localScrollMonitor = nil }
        if let m = globalKeyMonitor { NSEvent.removeMonitor(m); globalKeyMonitor = nil }
        if let m = localKeyMonitor { NSEvent.removeMonitor(m); localKeyMonitor = nil }
        if let m = globalMouseMonitor { NSEvent.removeMonitor(m); globalMouseMonitor = nil }
        if let m = localMouseMonitor { NSEvent.removeMonitor(m); localMouseMonitor = nil }
    }
    
    // MARK: - Scroll
    private func setupScrollMonitors() {
        globalScrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event)
        }
        localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event)
            return event
        }
    }
    
    private func handleScrollEvent(_ event: NSEvent) {
        let isContinuous = event.hasPreciseScrollingDeltas
        let isMomentum = event.momentumPhase.contains(.began) || event.momentumPhase.contains(.changed)
        let deltaY = Double(event.scrollingDeltaY)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let s = AppSettings.shared
            guard s.isEnabled && s.enableScrollSounds else { return }
            
            let config = ScrollConfig(
                isEnabled: s.isEnabled,
                voiceId: s.selectedVoiceId,
                volume: s.scrollVolume,
                notchSpacing: s.notchSpacing,
                enableHaptics: s.enableHaptics,
                hapticFeel: s.hapticFeel,
                enableMomentum: s.enableMomentum,
                isMouseWheelInstant: s.isMouseWheelInstant
            )
            
            self.scrollProcessor.processScroll(
                deltaY: deltaY,
                isContinuous: isContinuous,
                isMomentum: isMomentum,
                settings: config
            )
        }
    }
    
    // MARK: - Keyboard
    private func setupKeyboardMonitors() {
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let s = AppSettings.shared
            guard s.isEnabled && s.enableKeyboardSounds else { return }
            
            if event.type == .keyDown {
                self.kmEngine.playKeyDown(keyCode: event.keyCode, volume: s.keyboardVolume)
            } else if event.type == .keyUp && s.enableKeyUpSounds {
                self.kmEngine.playKeyUp(keyCode: event.keyCode, volume: s.keyboardVolume)
            }
        }
    }
    
    // MARK: - Mouse
    private func setupMouseMonitors() {
        let mask: NSEvent.EventTypeMask = [
            .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .otherMouseDown, .otherMouseUp
        ]
        
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handleMouseEvent(event)
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handleMouseEvent(event)
            return event
        }
    }
    
    private func handleMouseEvent(_ event: NSEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let s = AppSettings.shared
            guard s.isEnabled && s.enableMouseSounds else { return }
            
            let btn = (event.type == .rightMouseDown || event.type == .rightMouseUp) ? 1 : 0
            if event.type == .leftMouseDown || event.type == .rightMouseDown || event.type == .otherMouseDown {
                self.kmEngine.playMouseDown(button: btn, volume: s.mouseVolume)
            } else {
                self.kmEngine.playMouseUp(button: btn, volume: s.mouseVolume)
            }
        }
    }
}

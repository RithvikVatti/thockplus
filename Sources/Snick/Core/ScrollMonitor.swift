import AppKit
import ApplicationServices

public final class ScrollMonitor: @unchecked Sendable {
    public static let shared = ScrollMonitor()
    
    private let processor = ScrollProcessor()
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private var isRunning: Bool = false
    
    private init() {}
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        setupNSEventMonitors()
        setupEventTapIfPossible()
    }
    
    public func stop() {
        guard isRunning else { return }
        isRunning = false
        
        if let gm = globalMonitor {
            NSEvent.removeMonitor(gm)
            globalMonitor = nil
        }
        if let lm = localMonitor {
            NSEvent.removeMonitor(lm)
            localMonitor = nil
        }
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let src = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
                runLoopSource = nil
            }
            eventTap = nil
        }
    }
    
    public func restart() {
        stop()
        start()
    }
    
    private func setupNSEventMonitors() {
        // Global monitor catches scrolls in all other apps
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleNSEvent(event)
        }
        
        // Local monitor catches scrolls within Snick's own popover / test area
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleNSEvent(event)
            return event
        }
    }
    
    private func handleNSEvent(_ event: NSEvent) {
        let isContinuous = event.hasPreciseScrollingDeltas
        let isMomentum = event.momentumPhase.contains(.began) ||
                         event.momentumPhase.contains(.changed)
        
        let deltaY = Double(event.scrollingDeltaY)
        
        // Read current settings on main actor safely
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let s = AppSettings.shared
            let config = ScrollConfig(
                isEnabled: s.isEnabled,
                voiceId: s.selectedVoiceId,
                volume: s.volume,
                notchSpacing: s.notchSpacing,
                rateLimitMs: s.rateLimitMs,
                enableHaptics: s.enableHaptics,
                hapticPattern: s.hapticPattern,
                enableMomentum: s.enableMomentum,
                isMouseWheelInstant: s.isMouseWheelInstant
            )
            
            self.processor.processScroll(
                deltaY: deltaY,
                isContinuous: isContinuous,
                isMomentum: isMomentum,
                settings: config
            )
        }
    }
    
    private func setupEventTapIfPossible() {
        guard AXIsProcessTrusted() else { return }
        
        // Event tap provides direct kernel/WindowServer level capture
        let eventMask = (1 << CGEventType.scrollWheel.rawValue)
        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Handled via NSEvent monitor to avoid duplicate triggers
                return Unmanaged.passUnretained(event)
            },
            userInfo: observer
        )
        
        if let tap = tap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            self.eventTap = tap
            self.runLoopSource = runLoopSource
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
}

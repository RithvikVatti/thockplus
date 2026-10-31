import Foundation
import AppKit
import IOKit

public final class HardwareHapticEngine: @unchecked Sendable {
    public static let shared = HardwareHapticEngine()
    
    public enum HapticFeel: String, CaseIterable, Identifiable, Sendable {
        case ratchet = "ratchet"
        case crisp = "crisp"
        case light = "light"
        case medium = "medium"
        case thock = "thock"
        
        public var id: String { rawValue }
        
        public var displayName: String {
            switch self {
            case .ratchet: return "Wheel Ratchet (Oscillating)"
            case .crisp: return "Crisp Detent (Mechanical)"
            case .light: return "Light Tick (Subtle)"
            case .medium: return "Medium Click (Standard)"
            case .thock: return "Firm Thock (Heavy)"
            }
        }
        
        public var primaryActuationID: Int32 {
            switch self {
            case .ratchet: return 1
            case .crisp: return 1
            case .light: return 3
            case .medium: return 4
            case .thock: return 6
            }
        }
    }
    
    typealias MTActuatorCreateFromDeviceIDFunc = @convention(c) (UInt64) -> Unmanaged<CFTypeRef>?
    typealias MTActuatorOpenFunc = @convention(c) (CFTypeRef) -> Int32
    typealias MTActuatorCloseFunc = @convention(c) (CFTypeRef) -> Int32
    typealias MTActuatorActuateFunc = @convention(c) (CFTypeRef, Int32, UInt32, Float32, Float32) -> Int32
    
    private var actuatorRef: CFTypeRef?
    private var createActuator: MTActuatorCreateFromDeviceIDFunc?
    private var openActuator: MTActuatorOpenFunc?
    private var closeActuator: MTActuatorCloseFunc?
    private var actuateFunc: MTActuatorActuateFunc?
    
    private let queue = DispatchQueue(label: "com.thockplus.hardwarehaptics", qos: .userInteractive)
    private var lastActuationUptime: TimeInterval = 0
    private var isActuatorAvailable: Bool = false
    
    private init() {
        bindFunctions()
        openActuatorDevice()
    }
    
    private func bindFunctions() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_NOW) else {
            return
        }
        if let ptr = dlsym(handle, "MTActuatorCreateFromDeviceID") {
            createActuator = unsafeBitCast(ptr, to: MTActuatorCreateFromDeviceIDFunc.self)
        }
        if let ptr = dlsym(handle, "MTActuatorOpen") {
            openActuator = unsafeBitCast(ptr, to: MTActuatorOpenFunc.self)
        }
        if let ptr = dlsym(handle, "MTActuatorClose") {
            closeActuator = unsafeBitCast(ptr, to: MTActuatorCloseFunc.self)
        }
        if let ptr = dlsym(handle, "MTActuatorActuate") {
            actuateFunc = unsafeBitCast(ptr, to: MTActuatorActuateFunc.self)
        }
    }
    
    private func openActuatorDevice() {
        guard let createActuator = createActuator, let openActuator = openActuator else { return }
        
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("AppleMultitouchDevice")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return }
        
        var service = IOIteratorNext(iterator)
        while service != 0 {
            var props: Unmanaged<CFMutableDictionary>? = nil
            if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any],
               let actSupported = dict["ActuationSupported"] as? Bool, actSupported,
               let mtID = dict["Multitouch ID"] as? UInt64 ?? (dict["Multitouch ID"] as? NSNumber)?.uint64Value {
                if let ref = createActuator(mtID)?.takeRetainedValue() {
                    if openActuator(ref) == 0 {
                        self.actuatorRef = ref
                        self.isActuatorAvailable = true
                        IOObjectRelease(service)
                        break
                    }
                }
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        IOObjectRelease(iterator)
    }
    
    public func pulse(feel: HapticFeel = .ratchet) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let now = ProcessInfo.processInfo.systemUptime
            
            // Minimal 6ms debounce to ensure every distinct notch clicks without jamming solenoid
            if now - self.lastActuationUptime < 0.006 {
                return
            }
            self.lastActuationUptime = now
            
            if self.isActuatorAvailable, let act = self.actuatorRef, let actuate = self.actuateFunc {
                if feel == .ratchet {
                    // Oscillating wheel ratchet: sharp primary notch + trailing micro-oscillation
                    _ = actuate(act, 1, 0, 0.0, 2.0)
                    self.queue.asyncAfter(deadline: .now() + 0.012) { [weak self] in
                        guard let self = self, let reAct = self.actuatorRef, let reActuate = self.actuateFunc else { return }
                        _ = reActuate(reAct, 3, 0, 0.0, 1.0)
                    }
                } else {
                    let res = actuate(act, feel.primaryActuationID, 0, 0.0, 2.0)
                    if res != 0 {
                        self.openActuatorDevice()
                        if let reAct = self.actuatorRef {
                            _ = actuate(reAct, feel.primaryActuationID, 0, 0.0, 2.0)
                        }
                    }
                }
            } else {
                // Fallback for non-Apple trackpads
                DispatchQueue.main.async {
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                }
            }
        }
    }
    
    deinit {
        if let act = actuatorRef, let close = closeActuator {
            _ = close(act)
        }
    }
}

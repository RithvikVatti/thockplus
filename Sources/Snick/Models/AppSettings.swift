import Foundation
import SwiftUI
import ServiceManagement
import ApplicationServices

@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    @Published public var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: "isEnabled") }
    }
    
    @Published public var selectedVoiceId: String {
        didSet { defaults.set(selectedVoiceId, forKey: "selectedVoiceId") }
    }
    
    @Published public var volume: Double {
        didSet { defaults.set(volume, forKey: "volume") }
    }
    
    @Published public var notchSpacing: Double {
        didSet { defaults.set(notchSpacing, forKey: "notchSpacing") }
    }
    
    @Published public var rateLimitMs: Double {
        didSet { defaults.set(rateLimitMs, forKey: "rateLimitMs") }
    }
    
    @Published public var enableHaptics: Bool {
        didSet { defaults.set(enableHaptics, forKey: "enableHaptics") }
    }
    
    @Published public var hapticPattern: String {
        didSet { defaults.set(hapticPattern, forKey: "hapticPattern") }
    }
    
    @Published public var enableMomentum: Bool {
        didSet { defaults.set(enableMomentum, forKey: "enableMomentum") }
    }
    
    @Published public var isMouseWheelInstant: Bool {
        didSet { defaults.set(isMouseWheelInstant, forKey: "isMouseWheelInstant") }
    }
    
    @Published public var isAccessibilityGranted: Bool = false
    
    @Published public var launchAtLogin: Bool = false {
        didSet {
            updateLaunchAtLogin(launchAtLogin)
        }
    }
    
    private var permissionTimer: Timer?
    
    private init() {
        // Register default values
        defaults.register(defaults: [
            "isEnabled": true,
            "selectedVoiceId": "nok",
            "volume": 0.72,
            "notchSpacing": 30.0,
            "rateLimitMs": 18.0,
            "enableHaptics": true,
            "hapticPattern": "generic",
            "enableMomentum": true,
            "isMouseWheelInstant": true
        ])
        
        self.isEnabled = defaults.bool(forKey: "isEnabled")
        self.selectedVoiceId = defaults.string(forKey: "selectedVoiceId") ?? "nok"
        self.volume = defaults.double(forKey: "volume")
        self.notchSpacing = defaults.double(forKey: "notchSpacing")
        self.rateLimitMs = defaults.double(forKey: "rateLimitMs")
        self.enableHaptics = defaults.bool(forKey: "enableHaptics")
        self.hapticPattern = defaults.string(forKey: "hapticPattern") ?? "generic"
        self.enableMomentum = defaults.bool(forKey: "enableMomentum")
        self.isMouseWheelInstant = defaults.bool(forKey: "isMouseWheelInstant")
        
        self.isAccessibilityGranted = AXIsProcessTrusted()
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        
        startMonitoringAccessibility()
    }
    
    public func refreshAccessibility() {
        self.isAccessibilityGranted = AXIsProcessTrusted()
    }
    
    public func requestAccessibility() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
        refreshAccessibility()
    }
    
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func startMonitoringAccessibility() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let trusted = AXIsProcessTrusted()
                if self.isAccessibilityGranted != trusted {
                    self.isAccessibilityGranted = trusted
                }
            }
        }
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("[Snick] Error updating launch at login: \(error.localizedDescription)")
        }
    }
    
    deinit {
        permissionTimer?.invalidate()
    }
}

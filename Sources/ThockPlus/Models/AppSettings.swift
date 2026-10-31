import Foundation
import SwiftUI
import ServiceManagement
import ApplicationServices

@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    // Master switch
    @Published public var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: "isEnabled") }
    }
    
    // Scroll Detents
    @Published public var enableScrollSounds: Bool {
        didSet { defaults.set(enableScrollSounds, forKey: "enableScrollSounds") }
    }
    
    @Published public var selectedVoiceId: String {
        didSet { defaults.set(selectedVoiceId, forKey: "selectedVoiceId") }
    }
    
    @Published public var scrollVolume: Double {
        didSet { defaults.set(scrollVolume, forKey: "scrollVolume") }
    }
    
    @Published public var notchSpacing: Double {
        didSet { defaults.set(notchSpacing, forKey: "notchSpacing") }
    }
    
    @Published public var enableHaptics: Bool {
        didSet { defaults.set(enableHaptics, forKey: "enableHaptics") }
    }
    
    @Published public var hapticFeel: String {
        didSet { defaults.set(hapticFeel, forKey: "hapticFeel") }
    }
    
    @Published public var enableMomentum: Bool {
        didSet { defaults.set(enableMomentum, forKey: "enableMomentum") }
    }
    
    @Published public var isMouseWheelInstant: Bool {
        didSet { defaults.set(isMouseWheelInstant, forKey: "isMouseWheelInstant") }
    }
    
    // Keyboard Switches
    @Published public var enableKeyboardSounds: Bool {
        didSet { defaults.set(enableKeyboardSounds, forKey: "enableKeyboardSounds") }
    }
    
    @Published public var keyboardVolume: Double {
        didSet { defaults.set(keyboardVolume, forKey: "keyboardVolume") }
    }
    
    @Published public var enableKeyUpSounds: Bool {
        didSet { defaults.set(enableKeyUpSounds, forKey: "enableKeyUpSounds") }
    }
    
    // Mouse Clicks
    @Published public var enableMouseSounds: Bool {
        didSet { defaults.set(enableMouseSounds, forKey: "enableMouseSounds") }
    }
    
    @Published public var mouseVolume: Double {
        didSet { defaults.set(mouseVolume, forKey: "mouseVolume") }
    }
    
    // System status
    @Published public var isAccessibilityGranted: Bool = false
    @Published public var launchAtLogin: Bool = false {
        didSet { updateLaunchAtLogin(launchAtLogin) }
    }
    
    private var permissionTimer: Timer?
    
    private init() {
        defaults.register(defaults: [
            "isEnabled": true,
            "enableScrollSounds": true,
            "selectedVoiceId": "nok",
            "scrollVolume": 0.75,
            "notchSpacing": 16.0,
            "enableHaptics": true,
            "hapticFeel": "ratchet",
            "enableMomentum": true,
            "isMouseWheelInstant": true,
            "enableKeyboardSounds": true,
            "keyboardVolume": 0.70,
            "enableKeyUpSounds": true,
            "enableMouseSounds": true,
            "mouseVolume": 0.70
        ])
        
        self.isEnabled = defaults.bool(forKey: "isEnabled")
        self.enableScrollSounds = defaults.bool(forKey: "enableScrollSounds")
        self.selectedVoiceId = defaults.string(forKey: "selectedVoiceId") ?? "nok"
        self.scrollVolume = defaults.double(forKey: "scrollVolume")
        self.notchSpacing = defaults.double(forKey: "notchSpacing")
        self.enableHaptics = defaults.bool(forKey: "enableHaptics")
        self.hapticFeel = defaults.string(forKey: "hapticFeel") ?? "ratchet"
        self.enableMomentum = defaults.bool(forKey: "enableMomentum")
        self.isMouseWheelInstant = defaults.bool(forKey: "isMouseWheelInstant")
        
        self.enableKeyboardSounds = defaults.bool(forKey: "enableKeyboardSounds")
        self.keyboardVolume = defaults.double(forKey: "keyboardVolume")
        self.enableKeyUpSounds = defaults.bool(forKey: "enableKeyUpSounds")
        
        self.enableMouseSounds = defaults.bool(forKey: "enableMouseSounds")
        self.mouseVolume = defaults.double(forKey: "mouseVolume")
        
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
            print("[Thock+] Error updating launch at login: \(error.localizedDescription)")
        }
    }
    
    deinit {
        permissionTimer?.invalidate()
    }
}

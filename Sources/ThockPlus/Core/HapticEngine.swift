import Foundation
import AppKit

public final class HapticEngine: @unchecked Sendable {
    public static let shared = HapticEngine()
    
    public func trigger(feelName: String = "ratchet") {
        let feel = HardwareHapticEngine.HapticFeel(rawValue: feelName) ?? .ratchet
        HardwareHapticEngine.shared.pulse(feel: feel)
    }
}

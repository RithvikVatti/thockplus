import AppKit

public final class HapticEngine: @unchecked Sendable {
    public static let shared = HapticEngine()
    
    private let queue = DispatchQueue(label: "xyz.trysnick.hapticengine", qos: .userInteractive)
    private var lastHapticTime: TimeInterval = 0.0
    private let minIntervalSeconds: TimeInterval = 0.015 // 15ms debounce
    
    public enum Pattern: String, CaseIterable, Identifiable {
        case generic = "generic"
        case alignment = "alignment"
        case levelChange = "levelChange"
        
        public var id: String { rawValue }
        
        public var displayName: String {
            switch self {
            case .generic: return "Generic (Detent)"
            case .alignment: return "Alignment (Sharp)"
            case .levelChange: return "Level Change (Firm)"
            }
        }
        
        public var feedbackPattern: NSHapticFeedbackManager.FeedbackPattern {
            switch self {
            case .generic: return .generic
            case .alignment: return .alignment
            case .levelChange: return .levelChange
            }
        }
    }
    
    public func trigger(patternName: String = "generic") {
        let pattern = Pattern(rawValue: patternName) ?? .generic
        
        let now = ProcessInfo.processInfo.systemUptime
        if now - lastHapticTime < minIntervalSeconds {
            return
        }
        lastHapticTime = now
        
        DispatchQueue.main.async {
            NSHapticFeedbackManager.defaultPerformer.perform(
                pattern.feedbackPattern,
                performanceTime: .now
            )
        }
    }
}

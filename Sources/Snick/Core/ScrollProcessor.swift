import Foundation

public final class ScrollProcessor: @unchecked Sendable {
    private let soundEngine: SoundEngine
    private let hapticEngine: HapticEngine
    
    private let queue = DispatchQueue(label: "xyz.trysnick.scrollprocessor", qos: .userInteractive)
    
    private var accumulatedDelta: Double = 0.0
    private var lastEventUptimeMs: Double = 0.0
    private var lastClickUptimeMs: Double = 0.0
    
    // Stats for UI
    public private(set) var clickCount: UInt64 = 0
    
    public init(soundEngine: SoundEngine = .shared, hapticEngine: HapticEngine = .shared) {
        self.soundEngine = soundEngine
        self.hapticEngine = hapticEngine
    }
    
    public func processScroll(
        deltaY: Double,
        isContinuous: Bool,
        isMomentum: Bool,
        settings: ScrollConfig
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard settings.isEnabled else { return }
            
            // If it is momentum coasting and momentum is disabled, do nothing
            if isMomentum && !settings.enableMomentum {
                return
            }
            
            let nowMs = ProcessInfo.processInfo.systemUptime * 1000.0
            let absDelta = abs(deltaY)
            guard absDelta > 0.0001 else { return }
            
            // Traditional notched mouse wheel (discrete steps)
            if !isContinuous && settings.isMouseWheelInstant {
                self.accumulatedDelta = 0
                self.lastClickUptimeMs = nowMs
                self.clickCount &+= 1
                
                let gain = Float(settings.volume)
                self.soundEngine.play(voiceId: settings.voiceId, gain: gain)
                if settings.enableHaptics {
                    self.hapticEngine.trigger(patternName: settings.hapticPattern)
                }
                return
            }
            
            // Trackpad smooth continuous scroll
            let dt = max(1.0, nowMs - self.lastEventUptimeMs)
            self.lastEventUptimeMs = nowMs
            let velocity = absDelta / dt
            
            self.accumulatedDelta += absDelta
            let timeSinceLastClick = nowMs - self.lastClickUptimeMs
            
            let spacing = max(5.0, settings.notchSpacing)
            let rateLimit = max(5.0, settings.rateLimitMs)
            
            if self.accumulatedDelta >= spacing && timeSinceLastClick >= rateLimit {
                self.accumulatedDelta = self.accumulatedDelta.truncatingRemainder(dividingBy: spacing)
                self.lastClickUptimeMs = nowMs
                self.clickCount &+= 1
                
                // Velocity-aware gain calculation matching trysnick.xyz
                // minGain = 0.25, maxGain = 1.0, velocityScale = 0.18
                let rawGain = min(1.0, 0.25 + velocity * 0.18)
                let finalGain = Float(rawGain * settings.volume)
                
                self.soundEngine.play(voiceId: settings.voiceId, gain: finalGain)
                if settings.enableHaptics {
                    self.hapticEngine.trigger(patternName: settings.hapticPattern)
                }
            } else if self.accumulatedDelta > 6.0 * spacing {
                self.accumulatedDelta = 6.0 * spacing
            }
        }
    }
}

public struct ScrollConfig: Sendable {
    public let isEnabled: Bool
    public let voiceId: String
    public let volume: Double
    public let notchSpacing: Double
    public let rateLimitMs: Double
    public let enableHaptics: Bool
    public let hapticPattern: String
    public let enableMomentum: Bool
    public let isMouseWheelInstant: Bool
    
    public init(
        isEnabled: Bool,
        voiceId: String,
        volume: Double,
        notchSpacing: Double,
        rateLimitMs: Double,
        enableHaptics: Bool,
        hapticPattern: String,
        enableMomentum: Bool,
        isMouseWheelInstant: Bool
    ) {
        self.isEnabled = isEnabled
        self.voiceId = voiceId
        self.volume = volume
        self.notchSpacing = notchSpacing
        self.rateLimitMs = rateLimitMs
        self.enableHaptics = enableHaptics
        self.hapticPattern = hapticPattern
        self.enableMomentum = enableMomentum
        self.isMouseWheelInstant = isMouseWheelInstant
    }
}

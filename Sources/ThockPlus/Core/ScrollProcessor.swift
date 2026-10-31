import Foundation

public final class ScrollProcessor: @unchecked Sendable {
    private let soundEngine: SoundEngine
    private let hapticEngine: HapticEngine
    
    private let queue = DispatchQueue(label: "com.thockplus.scrollprocessor", qos: .userInteractive)
    
    private var accumulatedDelta: Double = 0.0
    private var lastEventUptimeMs: Double = 0.0
    private var lastClickUptimeMs: Double = -1000.0
    
    public private(set) var clickCount: UInt64 = 0
    
    public init(soundEngine: SoundEngine = .shared, hapticEngine: HapticEngine = .shared) {
        self.soundEngine = soundEngine
        self.hapticEngine = hapticEngine
    }
    
    public func reset() {
        queue.async { [weak self] in
            self?.accumulatedDelta = 0.0
        }
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
            
            // If momentum is disabled and user lifted fingers, discard immediately
            if isMomentum && !settings.enableMomentum {
                self.accumulatedDelta = 0
                return
            }
            
            let nowMs = ProcessInfo.processInfo.systemUptime * 1000.0
            let absDelta = abs(deltaY)
            guard absDelta > 0.0001 else { return }
            
            // If user paused scrolling for more than 75ms, reset backlog so nothing carries over
            if (nowMs - self.lastEventUptimeMs) > 75.0 {
                self.accumulatedDelta = 0.0
            }
            
            let dt = max(1.0, nowMs - self.lastEventUptimeMs)
            self.lastEventUptimeMs = nowMs
            let velocity = absDelta / dt
            
            let rateLimit = max(16.0, settings.rateLimitMs)
            let timeSinceLastClick = nowMs - self.lastClickUptimeMs
            
            // Stepped Mouse Wheel Mode (discrete notches)
            if !isContinuous && settings.isMouseWheelInstant {
                if timeSinceLastClick >= rateLimit {
                    self.accumulatedDelta = 0
                    self.lastClickUptimeMs = nowMs
                    self.clickCount &+= 1
                    
                    let gain = Float(settings.volume)
                    self.soundEngine.play(voiceId: settings.voiceId, gain: gain)
                    if settings.enableHaptics {
                        self.hapticEngine.trigger(feelName: settings.hapticFeel)
                    }
                }
                return
            }
            
            // Trackpad Continuous Scroll
            self.accumulatedDelta += absDelta
            let spacing = max(8.0, settings.notchSpacing)
            
            // Only fire if accumulated distance reached spacing AND rate limit interval has elapsed
            if self.accumulatedDelta >= spacing && timeSinceLastClick >= rateLimit {
                self.accumulatedDelta = 0.0 // Clean reset: never queue future backlog
                self.lastClickUptimeMs = nowMs
                self.clickCount &+= 1
                
                // Velocity-aware gain calculation (capped cleanly between 0.35 and 1.0)
                let rawGain = min(1.0, 0.35 + velocity * 0.12)
                let finalGain = Float(rawGain * settings.volume)
                
                // Fire exactly one synchronized detent sound and hardware haptic
                self.soundEngine.play(voiceId: settings.voiceId, gain: finalGain)
                if settings.enableHaptics {
                    self.hapticEngine.trigger(feelName: settings.hapticFeel)
                }
            } else if self.accumulatedDelta > spacing {
                // Hard clamp to prevent runaway accumulation during violent flings
                self.accumulatedDelta = spacing
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
    public let hapticFeel: String
    public let enableMomentum: Bool
    public let isMouseWheelInstant: Bool
    
    public init(
        isEnabled: Bool,
        voiceId: String,
        volume: Double,
        notchSpacing: Double,
        rateLimitMs: Double = 22.0,
        enableHaptics: Bool,
        hapticFeel: String,
        enableMomentum: Bool,
        isMouseWheelInstant: Bool
    ) {
        self.isEnabled = isEnabled
        self.voiceId = voiceId
        self.volume = volume
        self.notchSpacing = notchSpacing
        self.rateLimitMs = rateLimitMs
        self.enableHaptics = enableHaptics
        self.hapticFeel = hapticFeel
        self.enableMomentum = enableMomentum
        self.isMouseWheelInstant = isMouseWheelInstant
    }
}

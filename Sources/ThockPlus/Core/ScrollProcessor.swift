import Foundation

public final class ScrollProcessor: @unchecked Sendable {
    private let soundEngine: SoundEngine
    private let hapticEngine: HapticEngine
    
    private let queue = DispatchQueue(label: "com.thockplus.scrollprocessor", qos: .userInteractive)
    
    private var accumulatedDelta: Double = 0.0
    private var lastEventUptimeMs: Double = 0.0
    private var lastClickUptimeMs: Double = 0.0
    
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
            
            if isMomentum && !settings.enableMomentum {
                return
            }
            
            let nowMs = ProcessInfo.processInfo.systemUptime * 1000.0
            let absDelta = abs(deltaY)
            guard absDelta > 0.0001 else { return }
            
            // Stepped Mouse Wheel Mode (discrete notch ticks)
            if !isContinuous && settings.isMouseWheelInstant {
                self.accumulatedDelta = 0
                self.lastClickUptimeMs = nowMs
                self.clickCount &+= 1
                
                let gain = Float(settings.volume)
                self.soundEngine.play(voiceId: settings.voiceId, gain: gain)
                if settings.enableHaptics {
                    self.hapticEngine.trigger(feelName: settings.hapticFeel)
                }
                return
            }
            
            // Trackpad Continuous Scroll
            let dt = max(1.0, nowMs - self.lastEventUptimeMs)
            self.lastEventUptimeMs = nowMs
            let velocity = absDelta / dt
            
            self.accumulatedDelta += absDelta
            let spacing = max(6.0, settings.notchSpacing)
            
            if self.accumulatedDelta >= spacing {
                let notches = min(4, Int(self.accumulatedDelta / spacing))
                self.accumulatedDelta = self.accumulatedDelta.truncatingRemainder(dividingBy: spacing)
                self.lastClickUptimeMs = nowMs
                
                // Velocity-aware gain calculation
                let rawGain = min(1.0, 0.28 + velocity * 0.16)
                let finalGain = Float(rawGain * settings.volume)
                
                for i in 0..<notches {
                    if i == 0 {
                        self.clickCount &+= 1
                        self.soundEngine.play(voiceId: settings.voiceId, gain: finalGain)
                        if settings.enableHaptics {
                            self.hapticEngine.trigger(feelName: settings.hapticFeel)
                        }
                    } else {
                        // Spread subsequent rapid notches smoothly
                        let delay = Double(i) * 0.010
                        self.queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                            guard let self = self else { return }
                            self.clickCount &+= 1
                            self.soundEngine.play(voiceId: settings.voiceId, gain: finalGain * 0.9)
                            if settings.enableHaptics {
                                self.hapticEngine.trigger(feelName: settings.hapticFeel)
                            }
                        }
                    }
                }
            } else if self.accumulatedDelta > 4.0 * spacing {
                self.accumulatedDelta = 4.0 * spacing
            }
        }
    }
}

public struct ScrollConfig: Sendable {
    public let isEnabled: Bool
    public let voiceId: String
    public let volume: Double
    public let notchSpacing: Double
    public let enableHaptics: Bool
    public let hapticFeel: String
    public let enableMomentum: Bool
    public let isMouseWheelInstant: Bool
    
    public init(
        isEnabled: Bool,
        voiceId: String,
        volume: Double,
        notchSpacing: Double,
        enableHaptics: Bool,
        hapticFeel: String,
        enableMomentum: Bool,
        isMouseWheelInstant: Bool
    ) {
        self.isEnabled = isEnabled
        self.voiceId = voiceId
        self.volume = volume
        self.notchSpacing = notchSpacing
        self.enableHaptics = enableHaptics
        self.hapticFeel = hapticFeel
        self.enableMomentum = enableMomentum
        self.isMouseWheelInstant = isMouseWheelInstant
    }
}

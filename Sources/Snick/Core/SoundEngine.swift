import Foundation
import AVFoundation

public final class SoundEngine: @unchecked Sendable {
    public static let shared = SoundEngine()
    
    private let queue = DispatchQueue(label: "xyz.trysnick.soundengine", qos: .userInteractive)
    private var pools: [String: [AVAudioPlayer]] = [:]
    private var poolIndices: [String: Int] = [:]
    private let poolSize = 6
    
    public init() {
        preloadAllSounds()
    }
    
    public func preloadAllSounds() {
        queue.async { [weak self] in
            guard let self = self else { return }
            for voice in SoundCatalog.allVoices {
                self.preloadVoice(voice.id)
            }
        }
    }
    
    private func preloadVoice(_ voiceId: String) {
        guard let url = locateSoundURL(name: voiceId) else {
            print("[Snick] Could not locate sound file for: \(voiceId)")
            return
        }
        
        var list: [AVAudioPlayer] = []
        for _ in 0..<poolSize {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                list.append(player)
            } catch {
                print("[Snick] Failed to load audio player for \(voiceId): \(error)")
            }
        }
        
        if !list.isEmpty {
            pools[voiceId] = list
            poolIndices[voiceId] = 0
        }
    }
    
    public func play(voiceId: String, gain: Float) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // If pool doesn't exist yet, try to load it on demand
            if self.pools[voiceId] == nil {
                self.preloadVoice(voiceId)
            }
            
            guard let pool = self.pools[voiceId], !pool.isEmpty else { return }
            let idx = self.poolIndices[voiceId] ?? 0
            self.poolIndices[voiceId] = (idx + 1) % pool.count
            
            let player = pool[idx]
            player.volume = max(0.0, min(1.0, gain))
            player.currentTime = 0
            player.play()
        }
    }
    
    private func locateSoundURL(name: String) -> URL? {
        // 1. Bundle.main
        if let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds") {
            return url
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
            return url
        }
        
        // 2. Bundle.module (SPM)
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: name, withExtension: "wav", subdirectory: "Sounds") {
            return url
        }
        if let url = Bundle.module.url(forResource: name, withExtension: "wav") {
            return url
        }
        #endif
        
        // 3. App bundle Resources directory
        let bundleResources = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Sounds/\(name).wav")
        if FileManager.default.fileExists(atPath: bundleResources.path) {
            return bundleResources
        }
        
        // 4. Relative paths during development or standalone runs
        let relativePaths = [
            "Resources/Sounds/\(name).wav",
            "Sources/Snick/Resources/Sounds/\(name).wav",
            "Sounds/\(name).wav",
            "../Resources/Sounds/\(name).wav"
        ]
        for path in relativePaths {
            let u = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: u.path) {
                return u
            }
        }
        
        return nil
    }
}

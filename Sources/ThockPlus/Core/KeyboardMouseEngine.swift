import Foundation
import AVFoundation
import AppKit

public final class KeyboardMouseEngine: @unchecked Sendable {
    public static let shared = KeyboardMouseEngine()
    
    private let queue = DispatchQueue(label: "com.thockplus.keyboardmouse", qos: .userInteractive)
    private var players: [String: [AVAudioPlayer]] = [:]
    private var indices: [String: Int] = [:]
    
    private init() {
        preloadAudio()
    }
    
    public func preloadAudio() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Keyboard sounds
            let kbSounds = ["1", "2", "3", "4", "5", "101", "102", "201", "251", "301", "351", "401", "451"]
            for s in kbSounds {
                self.preload(category: "Keyboard", name: s, poolSize: 4)
            }
            
            // Mouse sounds
            let mouseSounds = ["1", "2", "3", "4"]
            for s in mouseSounds {
                self.preload(category: "Mouse", name: s, poolSize: 4)
            }
        }
    }
    
    private func preload(category: String, name: String, poolSize: Int) {
        guard let url = locateSoundURL(category: category, name: name) else { return }
        let key = "\(category)/\(name)"
        var pool: [AVAudioPlayer] = []
        for _ in 0..<poolSize {
            if let p = try? AVAudioPlayer(contentsOf: url) {
                p.prepareToPlay()
                pool.append(p)
            }
        }
        if !pool.isEmpty {
            players[key] = pool
            indices[key] = 0
        }
    }
    
    public func playKeyDown(keyCode: UInt16, volume: Double) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let name: String
            switch keyCode {
            case 49: // Space
                name = "201"
            case 36, 76: // Enter / Return
                name = "301"
            case 51: // Backspace / Delete
                name = "401"
            default:
                let rnd = Int.random(in: 1...5)
                name = "\(rnd)"
            }
            self.playPooled(category: "Keyboard", name: name, volume: Float(volume))
        }
    }
    
    public func playKeyUp(keyCode: UInt16, volume: Double) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let name: String
            switch keyCode {
            case 49: // Space
                name = "251"
            case 36, 76: // Enter
                name = "351"
            case 51: // Backspace
                name = "451"
            default:
                name = Bool.random() ? "101" : "102"
            }
            self.playPooled(category: "Keyboard", name: name, volume: Float(volume * 0.75))
        }
    }
    
    public func playMouseDown(button: Int, volume: Double) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let name = (button == 1) ? "3" : "1" // 1 = right, 0 = left
            self.playPooled(category: "Mouse", name: name, volume: Float(volume))
        }
    }
    
    public func playMouseUp(button: Int, volume: Double) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let name = (button == 1) ? "4" : "2"
            self.playPooled(category: "Mouse", name: name, volume: Float(volume * 0.8))
        }
    }
    
    private func playPooled(category: String, name: String, volume: Float) {
        let key = "\(category)/\(name)"
        guard let pool = players[key], !pool.isEmpty else { return }
        let idx = indices[key] ?? 0
        indices[key] = (idx + 1) % pool.count
        
        let p = pool[idx]
        p.volume = max(0.0, min(1.0, volume))
        p.currentTime = 0
        p.play()
    }
    
    private func locateSoundURL(category: String, name: String) -> URL? {
        let sub = "Sounds/\(category)"
        if let u = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: sub) {
            return u
        }
        #if SWIFT_PACKAGE
        if let u = Bundle.module.url(forResource: name, withExtension: "wav", subdirectory: sub) {
            return u
        }
        #endif
        
        let paths = [
            "Resources/Sounds/\(category)/\(name).wav",
            "Sources/ThockPlus/Resources/Sounds/\(category)/\(name).wav",
            "../Resources/Sounds/\(category)/\(name).wav"
        ]
        for p in paths {
            let u = URL(fileURLWithPath: p)
            if FileManager.default.fileExists(atPath: u.path) {
                return u
            }
        }
        return nil
    }
}

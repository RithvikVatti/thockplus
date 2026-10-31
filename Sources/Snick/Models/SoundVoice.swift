import Foundation
import SwiftUI

public struct SoundVoice: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let hexColor: String
    public let desc: String
    public let freq: Double
    public let decay: Double
    public let waveType: String
    
    public init(id: String, name: String, hexColor: String, desc: String, freq: Double, decay: Double, waveType: String) {
        self.id = id
        self.name = name
        self.hexColor = hexColor
        self.desc = desc
        self.freq = freq
        self.decay = decay
        self.waveType = waveType
    }
    
    public var color: Color {
        Color(hex: hexColor)
    }
}

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}

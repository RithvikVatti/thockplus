import Foundation

public enum SoundCatalog {
    public static let allVoices: [SoundVoice] = [
        SoundVoice(
            id: "nok",
            name: "Nok",
            hexColor: "#6366f1",
            desc: "Crisp detent",
            freq: 184,
            decay: 0.09,
            waveType: "sine"
        ),
        SoundVoice(
            id: "vyl",
            name: "Vyl",
            hexColor: "#a855f7",
            desc: "Vinyl tick",
            freq: 320,
            decay: 0.07,
            waveType: "triangle"
        ),
        SoundVoice(
            id: "glu",
            name: "Glu",
            hexColor: "#14b8a6",
            desc: "Gluey pop",
            freq: 140,
            decay: 0.16,
            waveType: "sine"
        ),
        SoundVoice(
            id: "dib",
            name: "Dib",
            hexColor: "#f97316",
            desc: "Tight blip",
            freq: 440,
            decay: 0.05,
            waveType: "square"
        ),
        SoundVoice(
            id: "plo",
            name: "Plo",
            hexColor: "#3b82f6",
            desc: "Low plop",
            freq: 96,
            decay: 0.18,
            waveType: "sine"
        ),
        SoundVoice(
            id: "tok",
            name: "Tok",
            hexColor: "#2dd4bf",
            desc: "Wooden tok",
            freq: 600,
            decay: 0.06,
            waveType: "square"
        ),
        SoundVoice(
            id: "rub",
            name: "Rub",
            hexColor: "#ef4444",
            desc: "Rubber snap",
            freq: 220,
            decay: 0.11,
            waveType: "sawtooth"
        )
    ]
    
    public static let defaultVoice = allVoices[0] // Nok
    
    public static func voice(for id: String) -> SoundVoice {
        allVoices.first { $0.id == id } ?? defaultVoice
    }
}

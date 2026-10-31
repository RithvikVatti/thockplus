import SwiftUI

struct SoundVoiceRow: View {
    let voice: SoundVoice
    let isSelected: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Color indicator dot
                Circle()
                    .fill(voice.color)
                    .frame(width: 9, height: 9)
                    .shadow(color: voice.color.opacity(0.6), radius: 3, x: 0, y: 0)
                
                // Name & description
                VStack(alignment: .leading, spacing: 1) {
                    Text(voice.name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(voice.desc)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                // Preview button
                Button(action: onPreview) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(5)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .help("Preview \(voice.name) sound")
                
                // Selection checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(voice.color.opacity(0.85))
                            : AnyShapeStyle(isHovered ? Color.primary.opacity(0.05) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

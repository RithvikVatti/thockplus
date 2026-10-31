import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var showingAdvanced: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)
            
            Divider()
                .opacity(0.4)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    // Accessibility Warning if not granted
                    if !settings.isAccessibilityGranted {
                        accessibilityBanner
                    }
                    
                    // Sound Voices Section
                    soundSection
                    
                    Divider()
                        .opacity(0.4)
                    
                    // Controls & Settings
                    SettingsSection(settings: settings)
                    
                    Divider()
                        .opacity(0.4)
                    
                    // Interactive Test Area
                    TestScrollArea()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            
            Divider()
                .opacity(0.4)
            
            // Footer
            footerView
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .frame(width: 330)
        .frame(maxHeight: 640)
        .background(
            Color(nsColor: .windowBackgroundColor)
                .opacity(0.96)
        )
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 10) {
            // Custom Waveform Pill Logo
            HStack(spacing: 2.5) {
                RoundedRectangle(cornerRadius: 1.5)
                    .frame(width: 3, height: 16)
                RoundedRectangle(cornerRadius: 1.5)
                    .frame(width: 3, height: 10)
                RoundedRectangle(cornerRadius: 1.5)
                    .frame(width: 3, height: 4)
                RoundedRectangle(cornerRadius: 1.5)
                    .frame(width: 3, height: 10)
                RoundedRectangle(cornerRadius: 1.5)
                    .frame(width: 3, height: 16)
            }
            .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("Snick")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    
                    // Status Pill
                    HStack(spacing: 4) {
                        Circle()
                            .fill(settings.isEnabled && settings.isAccessibilityGranted ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                        
                        Text(settings.isEnabled ? (settings.isAccessibilityGranted ? "Active" : "Needs AX") : "Off")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(settings.isEnabled && settings.isAccessibilityGranted ? .green : .secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill((settings.isEnabled && settings.isAccessibilityGranted ? Color.green : Color.orange).opacity(0.12))
                    )
                }
                
                Text("Satisfying scroll detents & haptics")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Master Switch
            Toggle("", isOn: $settings.isEnabled)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        }
    }
    
    // MARK: - Accessibility Banner
    private var accessibilityBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 13))
                
                Text("Accessibility Access Needed")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text("macOS requires accessibility permission to detect global scroll events across apps.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Button(action: {
                    settings.requestAccessibility()
                }) {
                    Text("Grant Permission")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button(action: {
                    settings.openAccessibilitySettings()
                }) {
                    Text("Open Settings")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Sound Section
    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SOUND VOICE")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)
                .padding(.horizontal, 2)
            
            VStack(spacing: 4) {
                ForEach(SoundCatalog.allVoices) { voice in
                    SoundVoiceRow(
                        voice: voice,
                        isSelected: settings.selectedVoiceId == voice.id,
                        onSelect: {
                            settings.selectedVoiceId = voice.id
                            // Preview the sound immediately
                            SoundEngine.shared.play(voiceId: voice.id, gain: Float(settings.volume))
                            if settings.enableHaptics {
                                HapticEngine.shared.trigger(patternName: settings.hapticPattern)
                            }
                        },
                        onPreview: {
                            SoundEngine.shared.play(voiceId: voice.id, gain: Float(settings.volume))
                            if settings.enableHaptics {
                                HapticEngine.shared.trigger(patternName: settings.hapticPattern)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack {
            Text("OpenSnick · v1.0.0")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 11))
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .onHover { isHovered in
                if isHovered {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }
}

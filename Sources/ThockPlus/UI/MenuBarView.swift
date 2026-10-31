import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)
            
            Divider().opacity(0.4)
            
            // Tab Picker
            Picker("", selection: $selectedTab) {
                Text("Scroll Detents").tag(0)
                Text("Controls & Haptics").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider().opacity(0.4)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    // Accessibility Warning if needed
                    if !settings.isAccessibilityGranted {
                        accessibilityBanner
                    }
                    
                    if selectedTab == 0 {
                        // Sound Voices Section
                        soundSection
                    } else {
                        // Settings & Controls
                        SettingsSection(settings: settings)
                    }
                    
                    Divider().opacity(0.4)
                    
                    // Live interactive test area
                    TestScrollArea()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            Divider().opacity(0.4)
            
            // Footer
            footerView
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .frame(width: 340)
        .frame(maxHeight: 640)
        .background(
            Color(nsColor: .windowBackgroundColor)
                .opacity(0.96)
        )
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 10) {
            // T+ Emblem
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#6366f1"), Color(hex: "#a855f7")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 26, height: 26)
                
                HStack(spacing: 1) {
                    Text("T")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("+")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .offset(y: -1)
                }
            }
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("Thock+")
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
                
                Text("Tactile mechanical audio & hardware haptics")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Gear icon to open full Settings Window
            Button(action: {
                SettingsWindowController.shared.show(tab: .soundpacks)
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(5)
                    .background(Circle().fill(Color.primary.opacity(0.06)))
            }
            .buttonStyle(.plain)
            .help("Open Thock+ Settings & Soundpacks (⌘,)")
            
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
            }
            
            Text("macOS requires Accessibility permission to detect keyboard, mouse, and scroll events system-wide.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Button("Grant Permission") {
                    settings.requestAccessibility()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Open Settings") {
                    settings.openAccessibilitySettings()
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
            Text("SCROLL DETENT VOICES")
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
                            SoundEngine.shared.play(voiceId: voice.id, gain: Float(settings.scrollVolume))
                            if settings.enableHaptics {
                                HapticEngine.shared.trigger(feelName: settings.hapticFeel)
                            }
                        },
                        onPreview: {
                            SoundEngine.shared.play(voiceId: voice.id, gain: Float(settings.scrollVolume))
                            if settings.enableHaptics {
                                HapticEngine.shared.trigger(feelName: settings.hapticFeel)
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
            Button(action: {
                SettingsWindowController.shared.show(tab: .soundpacks)
            }) {
                Label("Settings & Soundpacks...", systemImage: "music.note.list")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
            
            Spacer()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 11))
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
    }
}

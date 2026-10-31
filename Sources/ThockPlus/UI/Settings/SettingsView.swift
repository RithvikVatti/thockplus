import SwiftUI

public enum SettingsTab: String, CaseIterable, Identifiable {
    case soundpacks = "soundpacks"
    case scroll = "scroll"
    case sound = "sound"
    case general = "general"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .soundpacks: return "Soundpacks"
        case .scroll: return "Scroll & Haptics"
        case .sound: return "Audio & Volumes"
        case .general: return "General"
        }
    }
    
    public var icon: String {
        switch self {
        case .soundpacks: return "music.note.list"
        case .scroll: return "arrow.up.and.down.circle.fill"
        case .sound: return "speaker.wave.2.fill"
        case .general: return "gearshape.fill"
        }
    }
}

public struct SettingsView: View {
    @State private var selectedTab: SettingsTab
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var soundpackManager = SoundpackManager.shared
    
    public init(initialTab: SettingsTab = .soundpacks) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    public var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.title, systemImage: tab.icon)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.vertical, 4)
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch selectedTab {
                case .soundpacks:
                    SoundpacksSettingsPane(manager: soundpackManager)
                case .scroll:
                    ScrollHapticsSettingsPane(settings: settings)
                case .sound:
                    AudioVolumeSettingsPane(settings: settings)
                case .general:
                    GeneralSettingsPane(settings: settings, manager: soundpackManager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 740, minHeight: 520)
    }
}

// MARK: - 1. Soundpacks Settings Pane
struct SoundpacksSettingsPane: View {
    @ObservedObject var manager: SoundpackManager
    @State private var packCategoryTab: Int = 0 // 0: Keyboard, 1: Mouse
    @State private var searchText: String = ""
    
    var filteredKeyboardRegistry: [SoundpackRegistryEntry] {
        if searchText.isEmpty { return manager.keyboardRegistry }
        return manager.keyboardRegistry.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.brand.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredMouseRegistry: [SoundpackRegistryEntry] {
        if searchText.isEmpty { return manager.mouseRegistry }
        return manager.mouseRegistry.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.brand.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            HStack {
                Picker("", selection: $packCategoryTab) {
                    Text("Keyboard Packs (\(manager.keyboardRegistry.count))").tag(0)
                    Text("Mouse Packs (\(manager.mouseRegistry.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                
                Spacer()
                
                // Open Folder Button
                Button(action: {
                    manager.openSoundpacksFolder()
                }) {
                    Label("Open Directory", systemImage: "folder")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                // Refresh Manifest
                Button(action: {
                    Task { await manager.fetchManifest() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Refresh Registry")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            
            Divider().opacity(0.4)
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                TextField("Search switch profiles, brands (Alps, Cherry MX, Gateron, Razer...)", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.04))
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            
            // Soundpack Grid / List
            ScrollView {
                LazyVStack(spacing: 10) {
                    if packCategoryTab == 0 {
                        ForEach(filteredKeyboardRegistry) { entry in
                            SoundpackCardRow(
                                entry: entry,
                                isSelected: manager.selectedKeyboardPackID == entry.id,
                                onSelect: {
                                    manager.selectedKeyboardPackID = entry.id
                                },
                                onDownload: {
                                    Task { await manager.downloadAndInstall(entry: entry) }
                                }
                            )
                        }
                    } else {
                        ForEach(filteredMouseRegistry) { entry in
                            SoundpackCardRow(
                                entry: entry,
                                isSelected: manager.selectedMousePackID == entry.id,
                                onSelect: {
                                    manager.selectedMousePackID = entry.id
                                },
                                onDownload: {
                                    Task { await manager.downloadAndInstall(entry: entry) }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
    }
}

// Single Soundpack Row
struct SoundpackCardRow: View {
    let entry: SoundpackRegistryEntry
    let isSelected: Bool
    let onSelect: () -> Void
    let onDownload: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.06))
                    .frame(width: 38, height: 38)
                
                Image(systemName: entry.category == "keyboard" ? "keyboard" : "computermouse")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.name)
                        .font(.system(size: 13, weight: .bold))
                    
                    Text(entry.brand)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                    
                    if isSelected {
                        Text("Active")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green))
                    }
                }
                
                Text("by \(entry.author) · \(entry.size / 1024) KB")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if entry.isDownloading {
                ProgressView()
                    .controlSize(.small)
                    .padding(.trailing, 8)
            } else if entry.isInstalled {
                if isSelected {
                    Label("Selected", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                } else {
                    Button("Use Pack") {
                        onSelect()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            } else {
                Button(action: onDownload) {
                    Label("Install", systemImage: "arrow.down.circle")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - 2. Scroll & Haptics Settings Pane
struct ScrollHapticsSettingsPane: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scroll Detents & Hardware Solenoid Haptics")
                        .font(.system(size: 18, weight: .bold))
                    Text("Model mechanical scroll wheel detents on your Force Touch trackpad with direct IOKit MTActuator control.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Voice Picker Grid
                VStack(alignment: .leading, spacing: 8) {
                    Text("SELECT DETENT VOICE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                        ForEach(SoundCatalog.allVoices) { voice in
                            Button(action: {
                                settings.selectedVoiceId = voice.id
                                SoundEngine.shared.play(voiceId: voice.id, gain: Float(settings.scrollVolume))
                                HardwareHapticEngine.shared.pulse(feel: HardwareHapticEngine.HapticFeel(rawValue: settings.hapticFeel) ?? .ratchet)
                            }) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(voice.color)
                                        .frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(voice.name)
                                            .font(.system(size: 12, weight: .bold))
                                        Text(voice.desc)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if settings.selectedVoiceId == voice.id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(settings.selectedVoiceId == voice.id ? voice.color.opacity(0.12) : Color.primary.opacity(0.03))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(settings.selectedVoiceId == voice.id ? voice.color : Color.clear, lineWidth: 1.5)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
                // Hardware Haptics
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $settings.enableHaptics) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Force Touch Hardware Haptics (MTActuator)")
                                .font(.system(size: 13, weight: .bold))
                            Text("Direct hardware Taptic Engine solenoid vibration with zero WindowServer drop.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    
                    if settings.enableHaptics {
                        HStack {
                            Text("Haptic Sensation Feel:")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Picker("", selection: $settings.hapticFeel) {
                                ForEach(HardwareHapticEngine.HapticFeel.allCases) { feel in
                                    Text(feel.displayName).tag(feel.rawValue)
                                }
                            }
                            .frame(width: 260)
                            .onChange(of: settings.hapticFeel) { _, newFeel in
                                HardwareHapticEngine.shared.pulse(feel: HardwareHapticEngine.HapticFeel(rawValue: newFeel) ?? .ratchet)
                            }
                        }
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
                
                // Detent Spacing
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Detent Spacing (Notch Density):")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(Int(settings.notchSpacing)) px / notch")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    Slider(value: $settings.notchSpacing, in: 8.0...40.0, step: 2.0)
                    HStack {
                        Text("Dense (8px) · Mechanical ratchet")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Broad (40px) · Heavy dials")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
                
                // Max Speed / Cadence Limiter
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Max Detent Speed Limit (Rate Limiter):")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(Int(1000.0 / settings.rateLimitMs)) clicks/sec (\(Int(settings.rateLimitMs))ms)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    Slider(value: $settings.rateLimitMs, in: 16.0...45.0, step: 2.0)
                    HStack {
                        Text("Fast (16ms) · Smooth high speed")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Default (22ms)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Calm (45ms) · Heavy resistance")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
            }
            .padding(24)
        }
    }
}

// MARK: - 3. Audio & Volume Settings Pane
struct AudioVolumeSettingsPane: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audio & Volume Levels")
                        .font(.system(size: 18, weight: .bold))
                    Text("Fine-tune volume balance between typing, mouse clicks, and scrolling.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Keyboard Volume
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Keyboard Typing Audio", systemImage: "keyboard")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text("\(Int(settings.keyboardVolume * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    Slider(value: $settings.keyboardVolume, in: 0...1)
                    
                    Toggle("Play key-up (switch release) sounds", isOn: $settings.enableKeyUpSounds)
                        .font(.system(size: 11))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
                
                // Mouse Volume
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Mouse Click Audio", systemImage: "computermouse")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text("\(Int(settings.mouseVolume * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    Slider(value: $settings.mouseVolume, in: 0...1)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
                
                // Scroll Volume
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Scroll Detent Audio", systemImage: "arrow.up.and.down")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text("\(Int(settings.scrollVolume * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    Slider(value: $settings.scrollVolume, in: 0...1)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
            }
            .padding(24)
        }
    }
}

// MARK: - 4. General Settings Pane
struct GeneralSettingsPane: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var manager: SoundpackManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with AppIcon
                VStack(spacing: 8) {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(18)
                        .shadow(radius: 8)
                    
                    Text("Thock+")
                        .font(.system(size: 22, weight: .bold))
                    
                    Text("Version 1.0.0 · The All-in-One Mechanical Sound & Haptic Companion")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                Divider()
                
                // Options
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                        .font(.system(size: 13, weight: .medium))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accessibility Permission")
                                .font(.system(size: 13, weight: .medium))
                            Text(settings.isAccessibilityGranted ? "Granted · System-wide event capture active" : "Required for keyboard, mouse, and scroll events")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if settings.isAccessibilityGranted {
                            Label("Active", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12, weight: .bold))
                        } else {
                            Button("Grant Permission") {
                                settings.requestAccessibility()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    
                    Divider().opacity(0.4)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Soundpacks Directory")
                                .font(.system(size: 13, weight: .medium))
                            Text("Drop custom soundpack folders directly into Application Support")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Open in Finder") {
                            manager.openSoundpacksFolder()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
                .padding(.horizontal, 24)
            }
        }
    }
}

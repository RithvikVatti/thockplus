import SwiftUI

struct SettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Scroll Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Scroll Detents", systemImage: "arrow.up.and.down")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Toggle("", isOn: $settings.enableScrollSounds)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                
                if settings.enableScrollSounds {
                    // Scroll Volume
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Volume")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(settings.scrollVolume * 100))%")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.scrollVolume, in: 0.0...1.0)
                            .tint(.accentColor)
                    }
                    
                    // Detent Spacing
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Detent Spacing")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(settings.notchSpacing))px")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.notchSpacing, in: 8.0...40.0, step: 2.0)
                            .tint(.accentColor)
                        HStack {
                            Text("Dense (8px)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Default (16px)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Broad (40px)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Hardware Haptics
                    Toggle(isOn: $settings.enableHaptics) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Trackpad Hardware Haptics")
                                .font(.system(size: 12, weight: .medium))
                            Text("Real solenoid vibration with every notch")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    
                    if settings.enableHaptics {
                        // Haptic Feel Picker
                        HStack {
                            Text("Haptic Sensation")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $settings.hapticFeel) {
                                ForEach(HardwareHapticEngine.HapticFeel.allCases) { feel in
                                    Text(feel.displayName).tag(feel.rawValue)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .controlSize(.small)
                            .onChange(of: settings.hapticFeel) { _, newFeel in
                                HardwareHapticEngine.shared.pulse(feel: HardwareHapticEngine.HapticFeel(rawValue: newFeel) ?? .ratchet)
                            }
                        }
                    }
                    
                    Toggle(isOn: $settings.enableMomentum) {
                        Text("Momentum Fling Clicks")
                            .font(.system(size: 11))
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    
                    Toggle(isOn: $settings.isMouseWheelInstant) {
                        Text("Instant Stepped Mouse Wheel Detents")
                            .font(.system(size: 11))
                    }
                    .toggleStyle(CheckboxToggleStyle())
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            )
            
            // MARK: - Keyboard Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Mechanical Keyboard", systemImage: "keyboard")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Toggle("", isOn: $settings.enableKeyboardSounds)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                
                if settings.enableKeyboardSounds {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Typing Volume")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(settings.keyboardVolume * 100))%")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.keyboardVolume, in: 0.0...1.0)
                            .tint(.accentColor)
                    }
                    
                    Toggle(isOn: $settings.enableKeyUpSounds) {
                        Text("Switch Release (Key-Up) Sounds")
                            .font(.system(size: 11))
                    }
                    .toggleStyle(CheckboxToggleStyle())
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            )
            
            // MARK: - Mouse Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Mouse Click Sounds", systemImage: "computermouse")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Toggle("", isOn: $settings.enableMouseSounds)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                
                if settings.enableMouseSounds {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Click Volume")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(settings.mouseVolume * 100))%")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.mouseVolume, in: 0.0...1.0)
                            .tint(.accentColor)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            )
            
            // MARK: - System Options
            Toggle(isOn: $settings.launchAtLogin) {
                Label("Launch at Login", systemImage: "power")
                    .font(.system(size: 12, weight: .medium))
            }
            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        }
    }
}

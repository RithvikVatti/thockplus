import SwiftUI

struct SettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(spacing: 12) {
            // Volume Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("Volume", systemImage: "speaker.wave.2")
                        .font(.system(size: 12, weight: .medium))
                    
                    Spacer()
                    
                    Text("\(Int(settings.volume * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.primary.opacity(0.06))
                        )
                }
                
                Slider(value: $settings.volume, in: 0.0...1.0)
                    .tint(.accentColor)
            }
            
            // Detent Spacing / Feel Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("Detent Spacing", systemImage: "slider.horizontal.below.rectangle")
                        .font(.system(size: 12, weight: .medium))
                    
                    Spacer()
                    
                    Text(spacingDescription(settings.notchSpacing))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.primary.opacity(0.06))
                        )
                }
                
                Slider(value: $settings.notchSpacing, in: 12.0...60.0, step: 2.0)
                    .tint(.accentColor)
                
                HStack {
                    Text("Fine (12px)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Default (30px)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Broad (60px)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .opacity(0.4)
            
            // Toggles
            VStack(spacing: 8) {
                Toggle(isOn: $settings.enableHaptics) {
                    Label {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Trackpad Haptics")
                                .font(.system(size: 12, weight: .medium))
                            Text("Force Touch detent feedback")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "hand.tap")
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                
                Toggle(isOn: $settings.enableMomentum) {
                    Label {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Momentum Clicks")
                                .font(.system(size: 12, weight: .medium))
                            Text("Click during inertia fling")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "wind")
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                
                Toggle(isOn: $settings.isMouseWheelInstant) {
                    Label {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Stepped Mouse Wheel")
                                .font(.system(size: 12, weight: .medium))
                            Text("Click on every notched mouse tick")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "computermouse")
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                
                Toggle(isOn: $settings.launchAtLogin) {
                    Label {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Launch at Login")
                                .font(.system(size: 12, weight: .medium))
                            Text("Start automatically on boot")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "power")
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            }
        }
    }
    
    private func spacingDescription(_ val: Double) -> String {
        if val <= 18 {
            return "Fine (\(Int(val))px)"
        } else if val <= 38 {
            return "Medium (\(Int(val))px)"
        } else {
            return "Broad (\(Int(val))px)"
        }
    }
}

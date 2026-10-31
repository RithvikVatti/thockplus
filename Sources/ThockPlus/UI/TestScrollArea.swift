import SwiftUI

struct TestScrollArea: View {
    @State private var items = Array(1...40)
    @State private var testText: String = ""
    @State private var clickTestCount: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LIVE INTERACTIVE TEST PAD")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)
            
            // Keyboard test field
            TextField("Type here to test mechanical switches...", text: $testText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11))
            
            // Mouse click test button
            Button(action: {
                clickTestCount += 1
            }) {
                HStack {
                    Image(systemName: "cursorarrow.click.2")
                    Text("Click button to test mouse switch (clicks: \(clickTestCount))")
                        .font(.system(size: 11, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            // Scroll Wheel test list
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 4) {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Image(systemName: "arrow.up.and.down")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Text("Scroll Detent Notch #\(item)")
                                .font(.system(size: 10, design: .monospaced))
                            Spacer()
                            Text("feel the haptic")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.primary.opacity(0.04))
                        )
                    }
                }
                .padding(4)
            }
            .frame(height: 75)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}

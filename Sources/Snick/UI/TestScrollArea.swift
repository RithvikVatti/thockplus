import SwiftUI

struct TestScrollArea: View {
    @State private var items = Array(1...50)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("TEST SCROLL")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                
                Spacer()
                
                Text("Scroll here to feel")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 2)
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Image(systemName: "hand.point.up.left.and.text")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            
                            Text("Detent notch row #\(item)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("↓ scroll")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.04))
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}
